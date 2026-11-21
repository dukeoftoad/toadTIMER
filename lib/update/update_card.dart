import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/theme.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/toad.dart';
import '../widgets/toad_icon.dart';
import 'update_checker.dart';
import 'update_controller.dart';

/// The self-update panel in the settings sheet: check the latest GitHub
/// release, download the APK through the system download manager, and hand
/// it to the package installer. Drawn in the toadmark ink-and-frog design;
/// ported from the family's toadFILES/toadHEALTH flow.
class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, this.controller});

  final UpdateController? controller;

  @override
  Widget build(BuildContext context) {
    final update = controller ?? UpdateController.instance;
    return ListenableBuilder(
      listenable: update,
      builder: (context, _) => _UpdateCardView(update: update),
    );
  }
}

class _UpdateCardView extends StatelessWidget {
  const _UpdateCardView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final state = update.state;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.frog.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.frog.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.frog.withOpacity(0.25),
                  ),
                ),
                child: const ToadIcon(
                  'update.svg',
                  size: 17,
                  color: AppColors.frog400,
                ),
              ),
              const SizedBox(width: 10),
              Text('App updates', style: AppText.sora(size: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'toadTIMER v$kAppVersion · GitHub is asked only when you tap, or '
            'once quietly on open.',
            style: AppText.inter(
              size: 11.5,
              color: AppColors.textFaint,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          switch (state.status) {
            UpdateStatus.idle || UpdateStatus.upToDate => _IdleView(
              update: update,
            ),
            UpdateStatus.checking => const _CheckingView(),
            UpdateStatus.available => _AvailableView(update: update),
            UpdateStatus.downloading => _DownloadingView(update: update),
            UpdateStatus.installing => const Text(
              'The installer has the update — confirm it there.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
            UpdateStatus.needsPermission => _NeedsPermissionView(
              update: update,
            ),
            UpdateStatus.error => _ErrorView(update: update),
          },
        ],
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final upToDate = update.state.status == UpdateStatus.upToDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (upToDate)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ToadIcon(
                  'check.svg',
                  size: 15,
                  color: Color(0xFF34D399),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You're on the latest release",
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _PillButton(
          label: 'Check for updates',
          onTap: update.checkForUpdates,
        ),
      ],
    );
  }
}

class _CheckingView extends StatelessWidget {
  const _CheckingView();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox.square(
        dimension: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          'Checking for updates…',
          style: AppText.inter(
            size: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    ],
  );
}

class _AvailableView extends StatelessWidget {
  const _AvailableView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final state = update.state;
    final release = state.release;
    if (release == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'toadTIMER ${release.tagName} is available',
          style: AppText.sora(size: 13.5, weight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        const Text(
          'Downloaded only if you ask.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textFaint),
        ),
        if (state.message != null) ...[
          const SizedBox(height: 6),
          Text(
            state.message!,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (release.apkSizeBytes > 0) ...[
          const SizedBox(height: 6),
          Text(
            '${(release.apkSizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textFaint,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _PillButton(
              label: 'Download & install',
              onTap: release.apkUrl == null ? null : update.downloadAndInstall,
            ),
            _PillButton(
              label: 'View on GitHub',
              secondary: true,
              onTap: update.openReleasePage,
            ),
          ],
        ),
      ],
    );
  }
}

class _DownloadingView extends StatelessWidget {
  const _DownloadingView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final progress = update.state.progress;
    final total = progress?.totalBytes ?? -1;
    final bytes = progress?.bytesSoFar ?? 0;
    final fraction = total > 0 ? (bytes / total).clamp(0.0, 1.0) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox.square(
              dimension: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                total > 0
                    ? '${(bytes / 1024 / 1024).toStringAsFixed(1)} / '
                          '${(total / 1024 / 1024).toStringAsFixed(1)} MB'
                    : '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB',
                style: AppText.inter(
                  size: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.frog400),
          ),
        ),
      ],
    );
  }
}

class _NeedsPermissionView extends StatelessWidget {
  const _NeedsPermissionView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final state = update.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Allow installs from this app in Android Settings, then tap Install '
          'again.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        if (state.message != null) ...[
          const SizedBox(height: 6),
          Text(
            state.message!,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: AppColors.textFaint,
            ),
          ),
        ],
        const SizedBox(height: 12),
        _PillButton(label: 'Install now', onTap: update.retryInstall),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.update});

  final UpdateController update;

  @override
  Widget build(BuildContext context) {
    final state = update.state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.message ?? 'The update check failed — try again.',
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        _PillButton(label: 'Check for updates', onTap: update.checkForUpdates),
      ],
    );
  }
}

/// A pill button in the app's own language: the primary shape carries the
/// signature frog gradient (like the timer's Start control), the secondary
/// is the quiet outlined pill used across the settings sheet.
class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    this.onTap,
    this.secondary = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// When true, draw the quiet outlined shape instead of the frog gradient.
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    if (secondary) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.14)),
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      );
    }
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: IgnorePointer(
        ignoring: onTap == null,
        child: PressableScale(
          pressedScale: 0.93,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppGradients.frog,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: AppColors.frog.withOpacity(0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onGradient,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The quiet, dismissible "update available" strip the silent startup check
/// can raise at the top of the home screen. Nothing downloads until the
/// user acts; the toad delivers the news himself, mid-leap.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({super.key, this.controller});

  final UpdateController? controller;

  @override
  Widget build(BuildContext context) {
    final update = controller ?? UpdateController.instance;
    return ListenableBuilder(
      listenable: update,
      builder: (context, _) {
        final GitHubRelease? release = update.bannerRelease;
        if (release == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: AppColors.frog.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.frog.withOpacity(0.30)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.frog.withOpacity(0.12),
                  blurRadius: 20,
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 62,
                  height: 46,
                  child: ToadMascot(mood: ToadMood.celebrate, size: 46),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'toadTIMER ${release.tagName} available',
                        style: AppText.sora(size: 13, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Downloaded only if you ask.',
                        style: AppText.inter(
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PillButton(
                  label: 'Later',
                  secondary: true,
                  onTap: update.dismissBanner,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
