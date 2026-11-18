import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/constants.dart';
import '../models/timer_mode.dart';
import '../services/notification_service.dart';
import '../state/providers.dart';
import '../widgets/history_card.dart';
import '../widgets/mode_tabs.dart';
import '../widgets/quick_tiles_grid.dart';
import '../widgets/session_dots.dart';
import '../widgets/settings_sheet.dart';
import '../widgets/stats_grid.dart';
import '../widgets/tips_card.dart';
import '../widgets/timer_controls.dart';
import '../widgets/timer_ring.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recalculate from wall clock and consume any Quick Tile action.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(timerProvider.notifier).resync();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final mode = ref.watch(timerProvider.select((s) => s.mode));

    // Completion side effects surface as snackbars.
    ref.listen<UiMessage?>(uiMessengerProvider, (previous, next) {
      if (next == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next.text)));
      ref.read(uiMessengerProvider.notifier).clear();
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // base vertical wash
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0B1210),
                  AppColors.background,
                  AppColors.background,
                ],
                stops: [0, 0.35, 1],
              ),
            ),
          ),

          // ambient mode-tinted glow orbs
          _AmbientOrb(top: -90, left: -70, size: 260, color: mode.from),
          _AmbientOrb(bottom: -110, right: -60, size: 300, color: mode.to),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(notifyOn: settings.notifyOn),
                  const SizedBox(height: 20),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: mode.accent.withOpacity(0.14),
                      ),
                    ),
                    child: Column(
                      children: [
                        const ModeTabs(),
                        const SizedBox(height: 24),
                        const TimerRing(),
                        const SizedBox(height: 24),
                        const SessionDots(),
                        const SizedBox(height: 26),
                        const TimerControls(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  const _SectionHeader(
                    title: 'Quick Tiles',
                    subtitle: 'One-tap launch presets. Pin the system tile from '
                        'quick settings for the real deal.',
                  ),
                  const SizedBox(height: 12),
                  const QuickTilesGrid(),
                  const SizedBox(height: 26),
                  const _SectionHeader(
                    title: 'Today at the pond',
                    subtitle: 'Sessions, focus minutes and your streak.',
                  ),
                  const SizedBox(height: 12),
                  const StatsGrid(),
                  const SizedBox(height: 26),
                  const HistoryCard(),
                  const SizedBox(height: 16),
                  const TipsCard(),
                  const SizedBox(height: 28),
                  Column(
                    children: [
                      Text(
                        'toadTIMER v$kAppVersion — pomodoro flow, quick tiles '
                        'and gentle ribbits.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Riverpod state machine · flutter_local_notifications · '
                        'Android Quick Tile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A soft radial glow that fades to transparent — tinted by the active mode
/// and cross-fading smoothly when the mode changes. Purely decorative.
class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    required this.color,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  final Color color;
  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withOpacity(0.14),
                color.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.notifyOn});

  final bool notifyOn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF34D399).withOpacity(0.2),
                blurRadius: 16,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(
              'assets/icon/toad_icon.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(text: 'toad'),
                    TextSpan(
                      text: 'TIMER',
                      style: TextStyle(color: Color(0xFF34D399)),
                    ),
                  ],
                ),
              ),
              Text(
                'stay hoppy. stay focused.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: notifyOn
              ? Icons.notifications_active_rounded
              : Icons.notifications_rounded,
          tooltip: 'Notifications',
          onTap: () async {
            final granted =
                await NotificationService.instance.requestPermission();
            if (granted) {
              ref.read(settingsProvider.notifier).update(
                    ref.read(settingsProvider).copyWith(notifyOn: true),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications enabled - sessions will '
                        'ping you even in the background.'),
                  ),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Permission denied - enable alerts for '
                        'toadTIMER in system settings.'),
                  ),
                );
              }
            }
          },
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.settings_rounded,
          tooltip: 'Settings',
          onTap: () => showSettingsSheet(context),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.05),
        shape: const StadiumBorder(
          side: BorderSide(color: Color(0x1AFFFFFF)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 18, color: Colors.white.withOpacity(0.7)),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
