import 'package:flutter/material.dart';

import '../audio/cleaner_audio.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import '../util/haptics.dart';
import 'prepare_screen.dart';

/// Opens the "Before You Start" flow (0008) for [tone] — its cleaning routine
/// plays the mode's mapped tone (content.audio) and the completion chime when
/// it finishes.
void _startMode(BuildContext context, CleanerSound tone) {
  Haptics.tap();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/screen/0008'),
      builder: (_) => PrepareScreen(cleaningTone: tone),
    ),
  );
}

/// "Mode" tab (screen 0012) — the cleaning-modes list.
///
/// Ground truth: source/0012.json (375x667 reference, safe-area top 20).
/// Layout, top to bottom:
///   * Header — identical to the Cleaner tab: "Speaker Cleaner" wordmark plus
///     two 40pt white circle buttons with #007AFF glyphs (crown -> paywall,
///     gear -> settings).
///   * A scrolling list of mode cards, each a white panel with a #D3ECFF
///     border:
///       - "Clean Dust" — image panel on the left, title + subtitle on the
///         right, a blue forward arrow (r=20 card).
///       - "Vibrate Cleaner" — title + subtitle on the left, a blue disc with
///         a vibrating-phone glyph on the right (r=16 card).
///       - "Blow to Clean" — title + subtitle on the left, a blue disc with a
///         fan glyph on the right (r=16 card).
///
/// The original screen painted a Google native ad (a 375x250 "Install" block)
/// between the first and second cards and a 375x59 banner ad beneath the tab
/// bar. This clone ships ad-free, so both are dropped entirely and the cards
/// reflow — no reserved gap is left behind. The captured screenshot also shows
/// a "Loading ads…" reward-loading overlay; that is ad chrome and is likewise
/// not reproduced.
///
/// The bottom tab bar is owned by [AppShell]; this widget renders content only.
class ModeScreen extends StatelessWidget {
  const ModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: const [
                  _CleanDustCard(),
                  SizedBox(height: 20),
                  _ModeCard(
                    title: 'Vibrate Cleaner',
                    subtitle: 'Use vibration to push out dust and water',
                    icon: Icons.vibration,
                    tone: CleanerSound.vibrate,
                  ),
                  SizedBox(height: 20),
                  _ModeCard(
                    title: 'Blow to Clean',
                    subtitle: 'Clean your speaker with air sound',
                    icon: Icons.toys_outlined,
                    tone: CleanerSound.blow,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Speaker Cleaner',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          _CircleButton(
            icon: Icons.workspace_premium,
            semanticsLabel: 'Upgrade to Pro',
            onTap: () {
              Haptics.tap();
              Navigator.of(context).pushNamed('/screen/0001');
            },
          ),
          const SizedBox(width: 8),
          _CircleButton(
            icon: Icons.settings,
            semanticsLabel: 'Settings',
            onTap: () {
              Haptics.tap();
              Navigator.of(context).pushNamed('/screen/0003');
            },
          ),
        ],
      ),
    );
  }
}

/// 40pt white disc with a soft shadow and a #007AFF glyph (native crown/gear).
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.tr(semanticsLabel),
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        elevation: 1.5,
        shadowColor: const Color(0x33007AFF),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 22, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

/// The "Clean Dust" card — a left image panel with title/subtitle on the right
/// and a blue forward arrow. (Native: 343x132, r=20, border #D3ECFF.)
class _CleanDustCard extends StatelessWidget {
  const _CleanDustCard();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      radius: AppRadii.md,
      onTap: () => _startMode(context, CleanerSound.cleanDust),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 132,
        child: Row(
          children: [
            // Left image panel. The native art is a SwiftUI-drawn photo with no
            // exported asset, so we approximate it with a dark rounded panel and
            // a cleaning glyph.
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadii.md),
              ),
              child: Container(
                width: 150,
                height: 132,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3A4150), Color(0xFF20242E)],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.cleaning_services_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      context.l10n.tr('Clean Dust'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.tr('Clear your speaker for better sound'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.arrow_forward,
                          color: AppColors.primary, size: 24),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A "Vibrate Cleaner" / "Blow to Clean" style card — title + subtitle on the
/// left, a blue glyph disc on the right and a blue forward arrow below the
/// text. (Native: 343x130, r=16, border #D3ECFF.)
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final CleanerSound tone;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      radius: AppRadii.sm,
      onTap: () => _startMode(context, tone),
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
      child: SizedBox(
        height: 94,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.l10n.tr(title),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.tr(subtitle),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.arrow_forward,
                      color: AppColors.primary, size: 24),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 44),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared white card panel: #D3ECFF hairline border, rounded corners and a soft
/// blue shadow, with an ink ripple on tap.
class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    required this.radius,
    required this.onTap,
    required this.padding,
  });

  final Widget child;
  final double radius;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(radius),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: const Color(0xFFD3ECFF)),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
