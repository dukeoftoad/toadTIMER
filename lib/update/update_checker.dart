import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The slice of a GitHub release toadTIMER needs for the self-update flow.
class GitHubRelease {
  const GitHubRelease({
    required this.tagName,
    required this.htmlUrl,
    this.notes,
    this.apkName,
    this.apkUrl,
    this.apkSizeBytes = 0,
  });

  final String tagName;
  final String htmlUrl;

  /// Release notes body as plain text (markdown kept raw, CR-LF normalized).
  final String? notes;

  /// Null when the release ships no APK.
  final String? apkName;
  final String? apkUrl;
  final int apkSizeBytes;
}

/// An update-check failure with a ready-to-show, human-readable message.
/// [message] is already phrased for the user — no raw stack or HTTP text.
class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// GitHub's unauthenticated API rate limit (HTTP 403) was hit. Not retried.
class UpdateCheckRateLimitException extends UpdateCheckException {
  UpdateCheckRateLimitException()
      : super(
          "GitHub's rate limit was hit — wait a few minutes and try again, "
          'or open the release page on github.com.',
        );
}

/// GitHub-side 5xx: transient, so it IS retried, but keeps a ready message.
class UpdateCheckRetryableException extends UpdateCheckException {
  UpdateCheckRetryableException(int code)
      : super('GitHub is having trouble (HTTP $code) — try again in a moment.');
}

/// Fetches toadTIMER's newest GitHub release.
///
/// PRIVACY STANCE: this is the app's ONLY network path — until now the pond
/// was fully offline — and it exists solely for the update flow the user
/// asked for. It talks to exactly one endpoint (the repo's
/// releases/latest), sends nothing but a plain GET with the headers GitHub
/// requires, and keeps no cache beyond the in-memory UI state. It runs on
/// the user's "Check for updates" tap and once silently on app open —
/// never periodically. Nothing about the device, the session log or the
/// focus history is sent, stored or logged. Implemented on dart:io's
/// HttpClient so the feature adds zero packages.
abstract class UpdateChecker {
  /// Fetch and parse the latest release. Throws [UpdateCheckException]
  /// shapes on network/HTTP/parse trouble, with user-ready messages.
  Future<GitHubRelease> fetchLatestRelease();
}

class GithubReleaseChecker implements UpdateChecker {
  GithubReleaseChecker({
    HttpClient? client,
    Uri? apiUrl,
    int maxAttempts = defaultAttempts,
  }) : _client = client ?? HttpClient(),
       _apiUrl = apiUrl ??
           Uri.parse(
             'https://api.github.com/repos/dukeoftoad/toadTIMER/releases/latest',
           ),
       _maxAttempts = maxAttempts;

  final HttpClient _client;
  final Uri _apiUrl;
  final int _maxAttempts;

  @override
  Future<GitHubRelease> fetchLatestRelease() async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        return await _fetchOnce();
      } on UpdateCheckRateLimitException {
        rethrow; // GitHub's rate limit: never retried
      } on UpdateCheckRetryableException {
        // GitHub-side 5xx: retried once, then surfaces its ready message.
        if (attempt >= _maxAttempts) rethrow;
      } on UpdateCheckException {
        rethrow; // 4xx and parse failures are permanent
      } catch (_) {
        // Plain network trouble (connect/reset/timeout): retry once.
        if (attempt >= _maxAttempts) rethrow;
      }
    }
  }

  Future<GitHubRelease> _fetchOnce() async {
    final HttpClientRequest request;
    try {
      request = await _client
          .getUrl(_apiUrl)
          .timeout(timeout);
    } on TimeoutException {
      throw const UpdateCheckException(
        'GitHub did not answer in time — check the connection and try again.',
      );
    }
    request.headers.set('User-Agent', userAgent);
    request.headers.set('Accept', 'application/vnd.github+json');
    request.headers.set('X-GitHub-Api-Version', apiVersion);
    final HttpClientResponse response;
    try {
      response = await request.close().timeout(timeout);
    } on TimeoutException {
      throw const UpdateCheckException(
        'GitHub did not answer in time — check the connection and try again.',
      );
    }
    final code = response.statusCode;
    if (code < 200 || code >= 300) throw exceptionFor(code);
    // Bound the body so a hostile endpoint cannot stream forever.
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(timeout);
    return parseRelease(body);
  }

  /// Parses a GitHub release payload. The release workflow attaches a
  /// single phone APK (`toadtimer-v<tag>.apk`) plus an .aab bundle, so the
  /// first .apk asset wins and the .aab is skipped by the extension
  /// filter — no edition logic needed. Kept a static function so unit
  /// tests exercise real payloads without any network.
  static GitHubRelease parseRelease(String body) {
    final dynamic root;
    try {
      root = jsonDecode(body);
    } on FormatException {
      throw const UpdateCheckException(
        'GitHub sent a release the app could not read — try again later.',
      );
    }
    if (root is! Map<String, dynamic>) {
      throw const UpdateCheckException(
        'GitHub sent a release the app could not read — try again later.',
      );
    }
    final tag = root['tag_name'];
    if (tag is! String || tag.trim().isEmpty) {
      throw const UpdateCheckException(
        'GitHub sent a release without a version tag — try again later.',
      );
    }
    String? apkName;
    String? apkUrl;
    var apkSize = 0;
    final assets = root['assets'];
    if (assets is List<dynamic>) {
      for (final asset in assets) {
        if (asset is! Map<String, dynamic>) continue;
        final name = asset['name'];
        // Only the APK installs on the phone; the .aab bundle is skipped.
        if (name is! String || !name.toLowerCase().endsWith('.apk')) continue;
        final url = asset['browser_download_url'];
        final size = asset['size'];
        apkName ??= name;
        apkUrl ??= url is String && url.isNotEmpty ? url : null;
        if (apkSize == 0 && size is int) apkSize = size;
      }
    }
    final htmlUrl = root['html_url'];
    final notes = root['body'];
    return GitHubRelease(
      tagName: tag.trim(),
      htmlUrl: htmlUrl is String && htmlUrl.isNotEmpty
          ? htmlUrl
          : 'https://github.com/dukeoftoad/toadTIMER/releases',
      notes: notes is String && notes.isNotEmpty
          ? notes.replaceAll('\r\n', '\n')
          : null,
      apkName: apkName,
      apkUrl: apkUrl,
      apkSizeBytes: apkSize,
    );
  }

  /// Maps a non-2xx status to the exception that classifies the failure:
  /// 403 → rate limit, never retried; 5xx → retryable; other 4xx → permanent.
  static UpdateCheckException exceptionFor(int code) {
    if (code == 403) return UpdateCheckRateLimitException();
    if (code >= 500 && code < 600) return UpdateCheckRetryableException(code);
    return UpdateCheckException(
      'GitHub Releases answered HTTP $code — try again later.',
    );
  }

  static const userAgent = 'toadTIMER-update-check';
  static const apiVersion = '2022-11-28';
  static const timeout = Duration(seconds: 10);
  static const defaultAttempts = 2;
}
