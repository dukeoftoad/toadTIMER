import 'package:flutter_test/flutter_test.dart';

import 'package:toadtimer/update/update_checker.dart';
import 'package:toadtimer/update/version_compare.dart';

/// The self-update flow's pure logic: tag comparison and release parsing,
/// both exercised without any network (mirrors the family's toadFILES,
/// toadPLAYER and toadHEALTH suites, where the flow was proven).
void main() {
  group('VersionCompare.isNewer', () {
    test('a newer patch is newer', () {
      expect(VersionCompare.isNewer('1.2.1', 'v1.2.2'), isTrue);
    });

    test('the same version is not newer, with or without the v', () {
      expect(VersionCompare.isNewer('1.2.1', 'v1.2.1'), isFalse);
      expect(VersionCompare.isNewer('v1.2.1', '1.2.1'), isFalse);
    });

    test('an older release is not newer', () {
      expect(VersionCompare.isNewer('1.2.1', '1.2.0'), isFalse);
    });

    test('components compare numerically, not lexicographically', () {
      expect(VersionCompare.isNewer('1.9.0', '1.10.0'), isTrue);
      expect(VersionCompare.isNewer('1.10.0', '1.9.0'), isFalse);
    });

    test('short tags are padded ("1.2" == "1.2.0")', () {
      expect(VersionCompare.isNewer('1.2', '1.2.0'), isFalse);
      expect(VersionCompare.isNewer('1.2', '1.2.1'), isTrue);
    });

    test('a pre-release is older than its stable release', () {
      expect(VersionCompare.isNewer('1.2.1', '1.2.1-beta'), isFalse);
      expect(VersionCompare.isNewer('1.2.1-beta', '1.2.1'), isTrue);
    });

    test('a malformed tag never pushes an update', () {
      expect(VersionCompare.isNewer('1.2.1', ''), isFalse);
      expect(VersionCompare.isNewer('1.2.1', 'v'), isFalse);
      expect(VersionCompare.isNewer('1.2.1', 'blob'), isFalse);
    });
  });

  group('GithubReleaseChecker.parseRelease', () {
    test('reads a real-shaped release payload', () {
      const body = '''
{
  "tag_name": "v1.3.0",
  "html_url": "https://github.com/dukeoftoad/toadTIMER/releases/tag/v1.3.0",
  "body": "The update release.\\r\\n- In-app updates\\r\\n- Pond polish",
  "assets": [
    {
      "name": "toadtimer-v1.3.0.apk",
      "browser_download_url": "https://github.com/dukeoftoad/toadTIMER/releases/download/v1.3.0/toadtimer-v1.3.0.apk",
      "size": 9876543
    },
    {
      "name": "toadtimer-v1.3.0.aab",
      "browser_download_url": "https://github.com/dukeoftoad/toadTIMER/releases/download/v1.3.0/toadtimer-v1.3.0.aab",
      "size": 1234567
    }
  ]
}
''';
      final release = GithubReleaseChecker.parseRelease(body);
      expect(release.tagName, 'v1.3.0');
      // CR-LF normalized to plain newlines.
      expect(release.notes, contains('release.\n- In-app updates'));
      // The phone app is offered the APK; the .aab bundle is skipped.
      expect(release.apkName, 'toadtimer-v1.3.0.apk');
      expect(release.apkUrl, isNotNull);
      expect(release.apkUrl, isNot(contains('.aab')));
      expect(release.apkSizeBytes, 9876543);
    });

    test('a release with only the .aab keeps a null url', () {
      const body = '''
{
  "tag_name": "v1.3.0",
  "assets": [
    {"name": "toadtimer-v1.3.0.aab", "browser_download_url": "https://x/app.aab", "size": 10}
  ]
}
''';
      final release = GithubReleaseChecker.parseRelease(body);
      expect(release.tagName, 'v1.3.0');
      expect(release.apkUrl, isNull);
    });

    test('a payload without a tag fails with a friendly message', () {
      expect(
        () => GithubReleaseChecker.parseRelease('{"assets": []}'),
        throwsA(isA<UpdateCheckException>()),
      );
    });

    test('garbage fails with a friendly message, not a FormatException', () {
      expect(
        () => GithubReleaseChecker.parseRelease('{not json'),
        throwsA(isA<UpdateCheckException>()),
      );
    });
  });

  group('GithubReleaseChecker.exceptionFor', () {
    test('403 maps to the rate limit', () {
      expect(
        GithubReleaseChecker.exceptionFor(403),
        isA<UpdateCheckRateLimitException>(),
      );
    });

    test('5xx maps to the retryable shape', () {
      expect(
        GithubReleaseChecker.exceptionFor(502),
        isA<UpdateCheckRetryableException>(),
      );
    });

    test('other 4xx maps to the plain friendly error', () {
      expect(
        GithubReleaseChecker.exceptionFor(404),
        isA<UpdateCheckException>(),
      );
      expect(
        GithubReleaseChecker.exceptionFor(404),
        isNot(isA<UpdateCheckRateLimitException>()),
      );
    });
  });
}
