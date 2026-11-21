import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/constants.dart';
import 'update_checker.dart';
import 'version_compare.dart';

/// The self-update flow's state, one shape for every screen that watches it
/// (the settings-sheet update panel and the home banner).
enum UpdateStatus {
  /// Nothing has happened yet.
  idle,

  /// A check is in flight (manual or the silent startup probe).
  checking,

  /// The newest GitHub release is not newer than the installed version.
  upToDate,

  /// A newer release with an APK is available.
  available,

  /// The APK is downloading; [UpdateState.progress] tracks the bytes.
  downloading,

  /// The APK finished downloading and the installer was handed the file.
  installing,

  /// The "Install unknown apps" toggle is off; the user was taken to the
  /// setting. The APK is kept — the same button finishes the job after the
  /// round-trip.
  needsPermission,

  /// The check or the download failed; [UpdateState.message] says why in
  /// words the user can act on.
  error,
}

class UpdateState {
  const UpdateState({
    this.status = UpdateStatus.idle,
    this.release,
    this.progress,
    this.message,
    this.downloadId,
  });

  final UpdateStatus status;
  final GitHubRelease? release;

  /// Download byte counters; a non-positive total means indeterminate.
  final ({int bytesSoFar, int totalBytes})? progress;
  final String? message;
  final int? downloadId;

  UpdateState copyWith({
    UpdateStatus? status,
    GitHubRelease? release,
    ({int bytesSoFar, int totalBytes})? progress,
    String? message,
    int? downloadId,
  }) => UpdateState(
    status: status ?? this.status,
    release: release ?? this.release,
    progress: progress ?? this.progress,
    message: message,
    downloadId: downloadId ?? this.downloadId,
  );
}

/// Drives the self-update flow: the manual settings-sheet check and
/// download, and the silent once-per-process startup probe that seeds the
/// home banner.
///
/// The network check is Dart ([GithubReleaseChecker], the update flow's
/// only network path); the download and the installer handoff are the
/// native DownloadManager steps behind the `dev.toad.toadtimer/update`
/// channel (UpdatePlugin.kt) — the same naming the tile channel uses. The
/// controller is a process-wide singleton so the startup probe's finding
/// is still there when the user opens settings — no second request.
class UpdateController extends ChangeNotifier {
  UpdateController({UpdateChecker? checker})
      : _checker = checker ?? GithubReleaseChecker();

  final UpdateChecker _checker;
  static const _channel = MethodChannel('dev.toad.toadtimer/update');
  static const _pollInterval = Duration(milliseconds: 500);
  static const _downloadTimeout = Duration(minutes: 10);

  UpdateState _state = const UpdateState();
  UpdateState get state => _state;

  /// Whether the user dismissed the banner for this process. The release
  /// itself stays in [state] so the update panel still seeds from the probe.
  bool _bannerDismissed = false;
  bool get bannerDismissed => _bannerDismissed;

  /// True once the silent probe ran in this process (it never repeats).
  bool _started = false;

  bool _disposed = false;

  void _emit(UpdateState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  /// The silent once-per-process probe on app open. Failures are swallowed
  /// by design — airplane mode, no network, GitHub being down stay quiet;
  /// only the manual check shows errors. Never downloads anything.
  void checkSilentlyOnce() {
    if (_started) return;
    _started = true;
    Future<void>(() async {
      final release = await _fetch();
      if (release == null) return;
      if (release.apkUrl != null &&
          VersionCompare.isNewer(kAppVersion, release.tagName)) {
        // Never disturb an in-flight download the user started.
        if (_state.status == UpdateStatus.downloading ||
            _state.status == UpdateStatus.installing) {
          return;
        }
        _emit(_state.copyWith(status: UpdateStatus.available, release: release));
      }
    });
  }

  /// The manual check from the settings sheet. Surfaces every failure as a
  /// ready-to-show message.
  Future<void> checkForUpdates() async {
    _emit(_state.copyWith(status: UpdateStatus.checking, message: null));
    try {
      final release = await _checker.fetchLatestRelease();
      if (release.apkUrl != null &&
          VersionCompare.isNewer(kAppVersion, release.tagName)) {
        _emit(
          _state.copyWith(
            status: UpdateStatus.available,
            release: release,
            message: null,
          ),
        );
      } else {
        _emit(
          _state.copyWith(
            status: UpdateStatus.upToDate,
            release: release,
            message: null,
          ),
        );
      }
    } on UpdateCheckException catch (error) {
      _emit(
        _state.copyWith(status: UpdateStatus.error, message: error.message),
      );
    } catch (_) {
      _emit(
        _state.copyWith(
          status: UpdateStatus.error,
          message: 'The update check failed — check the connection and try '
              'again.',
        ),
      );
    }
  }

  /// "Download & install": enqueues the system download, watches it to
  /// completion (the notification shade mirrors the same job), then hands
  /// the APK to the installer — or reports the "Install unknown apps"
  /// round-trip when the toggle is off.
  Future<void> downloadAndInstall() async {
    final release = _state.release;
    final url = release?.apkUrl;
    if (release == null || url == null) return;
    try {
      final id = await _channel.invokeMethod<int>('download', {
        'url': url,
        'fileName': release.apkName ?? 'toadtimer-update.apk',
        'title': 'toadTIMER ${release.tagName}',
        'description': 'Downloading the new release',
      });
      if (id == null) return;
      _emit(
        _state.copyWith(
          status: UpdateStatus.downloading,
          downloadId: id,
          progress: (bytesSoFar: 0, totalBytes: release.apkSizeBytes),
        ),
      );
      final done = await _watchDownload(id);
      if (!done) {
        _emit(
          _state.copyWith(
            status: UpdateStatus.available,
            message: 'The download did not finish — its notification keeps '
                'any progress; try again when convenient.',
          ),
        );
        return;
      }
      await _install(id);
    } on PlatformException catch (error) {
      _emit(
        _state.copyWith(
          status: UpdateStatus.available,
          message: error.message ?? 'The download could not be started.',
        ),
      );
    }
  }

  /// Retries the installer handoff after the user flipped the "Install
  /// unknown apps" toggle. The APK is still on disk from the same job.
  Future<void> retryInstall() async {
    final id = _state.downloadId;
    if (id == null) return;
    await _install(id);
  }

  Future<GitHubRelease?> _fetch() async {
    try {
      return await _checker.fetchLatestRelease();
    } catch (_) {
      return null; // silent probe: any failure is invisible
    }
  }

  /// Polls the system job until it completes or the timeout passes. The
  /// DownloadManager keeps downloading regardless of the watch loop.
  Future<bool> _watchDownload(int id) async {
    final deadline = DateTime.now().add(_downloadTimeout);
    while (DateTime.now().isBefore(deadline)) {
      final snapshot = await _channel
          .invokeMapMethod<String, dynamic>('progress', {'id': id});
      if (snapshot == null) return false;
      final status = snapshot['status'] as String? ?? 'running';
      final bytes = (snapshot['bytesSoFar'] as num?)?.toInt() ?? 0;
      final total = (snapshot['totalBytes'] as num?)?.toInt() ?? -1;
      if (status == 'successful') return true;
      if (status == 'failed' || status == 'vanished') return false;
      if (_state.downloadId == id) {
        _emit(
          _state.copyWith(
            status: UpdateStatus.downloading,
            progress: (bytesSoFar: bytes, totalBytes: total),
          ),
        );
      }
      await Future<void>.delayed(_pollInterval);
    }
    return false;
  }

  Future<void> _install(int id) async {
    final outcome = await _channel.invokeMethod<String>('install', {'id': id});
    switch (outcome) {
      case 'started':
        _emit(_state.copyWith(status: UpdateStatus.installing));
      case 'needsPermission':
        _emit(_state.copyWith(status: UpdateStatus.needsPermission));
      case 'settingsFailed':
        _emit(
          _state.copyWith(
            status: UpdateStatus.needsPermission,
            message: 'Could not open the install-permission setting — allow '
                'installs from this app in Android Settings, then tap again.',
          ),
        );
      default:
        _emit(
          _state.copyWith(
            status: UpdateStatus.available,
            message: 'The installer could not be opened — the APK is '
                'downloaded; try again.',
          ),
        );
    }
  }

  /// Opens the release page in the browser ("View on GitHub") through the
  /// native side — an https-only ACTION_VIEW, no browser package needed.
  Future<void> openReleasePage() async {
    final url = _state.release?.htmlUrl;
    if (url == null) return;
    try {
      await _channel.invokeMethod<bool>('openUrl', {'url': url});
    } catch (_) {
      // The browser launch is best-effort; the release page is reachable
      // from any browser manually too.
    }
  }

  /// Hides the banner for the rest of the process; the update panel keeps
  /// the release.
  void dismissBanner() {
    _bannerDismissed = true;
    notifyListeners();
  }

  /// The release the startup probe found, for the home banner; null when
  /// there is nothing to advertise or the user dismissed it.
  GitHubRelease? get bannerRelease {
    if (_bannerDismissed) return null;
    if (_state.status != UpdateStatus.available) return null;
    final release = _state.release;
    if (release == null) return null;
    if (!VersionCompare.isNewer(kAppVersion, release.tagName)) return null;
    return release;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Process-wide instance the app shell wires up; tests build their own.
  static final UpdateController instance = UpdateController();
}
