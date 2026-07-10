import 'package:flutter/material.dart';

import '../audio/cleaner_audio.dart';
import '../l10n/app_strings.dart';
import '../theme.dart';
import '../util/haptics.dart';
import 'cleaning_screen.dart';
import 'plan_data.dart';

/// "Before You Start" checklist (screens 0008 default + 0009 preparing).
///
/// Ground truth: source/0008.json & source/0009.json (375x667, safe-area 20).
/// The native build is a vertical scroll of:
///   * a circular back button top-left (40pt disc at x8 y20),
///   * an "(i) Before You Start" section header,
///   * three white checklist cards (native 343x74, r20, 1px #EEEEF2 border,
///     soft y+1/blur2 shadow) — each a blue hand glyph + title + caption,
///   * a full-width blue->teal "Start Cleaning" pill (native 343x52, r26)
///     with a fan glyph.
///
/// The native layout wrapped this in a 343x250 native ad (top) and a 375x59
/// banner (bottom); per the ad-free clone both are dropped and the checklist
/// occupies the space naturally — no reserved gap remains.
///
/// Screen 0009 is the same screen mid-transition: tapping "Start Cleaning"
/// shows a centered "preparing" loader before the cleaner opens. (The native
/// loader was a rewarded-ad spinner; here it is a plain preparing indicator.)
class PrepareScreen extends StatefulWidget {
  const PrepareScreen({
    super.key,
    this.preparing = false,
    this.planDay,
    this.cleaningTone = CleanerSound.cleanDust,
  });

  /// Renders directly into the preparing state — used by the standalone
  /// `/screen/0009` web preview / deep link.
  final bool preparing;

  /// The plan day this checklist precedes, when reached from the 7-day plan
  /// (0007). When its routine finishes, that day is marked complete and the
  /// next day unlocks. Null for the quick-clean mode flow (0012), which does
  /// not advance plan progress.
  final PlanDay? planDay;

  /// The cleaning tone played while the routine runs — carries the mode picked
  /// on screen 0012 ("Clean Dust" / "Vibrate Cleaner" / "Blow to Clean"), and
  /// defaults to the primary Cleaner tone for the plan-day routine.
  final CleanerSound cleaningTone;

  @override
  State<PrepareScreen> createState() => _PrepareScreenState();
}

class _PrepareScreenState extends State<PrepareScreen> {
  static const List<_Checklist> _items = <_Checklist>[
    _Checklist(
      title: 'Set volume to maximum',
      caption: 'Generate strong vibration power',
    ),
    _Checklist(
      title: 'Place speaker facing down',
      caption: 'Help debris move out of the grill.',
    ),
    _Checklist(
      title: 'Keep device on a flat surface',
      caption: 'Maintain stable vibration.',
    ),
  ];

  late bool _preparing = widget.preparing;

  void _startCleaning() {
    if (_preparing) return;
    Haptics.impact();
    setState(() => _preparing = true);
    // Brief "preparing" beat (native screen 0009 showed a rewarded-ad spinner
    // here; ad-free, it is a plain preparing indicator), then open the Cleaning
    // (playing) screen where the tone plays and a Stop control runs the routine
    // to completion — marking the plan day done / unlocking the next day.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/screen/cleaning'),
          builder: (_) => CleaningScreen(
            tone: widget.cleaningTone,
            planDay: widget.planDay,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    // Respect the home-indicator / gesture inset so the CTA never sits under it.
    final bottomInset = mq.viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 52, 16, 24 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 24, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.tr('Before You Start'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _items.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _ChecklistCard(item: _items[i]),
                ],
                const Spacer(),
                _StartCleaningButton(onTap: _startCleaning),
              ],
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 8,
            child: _BackButton(onTap: () {
              Haptics.tap();
              planPop(context);
            }),
          ),
          if (_preparing) const _PreparingOverlay(),
        ],
      ),
    );
  }
}

class _Checklist {
  const _Checklist({required this.title, required this.caption});
  final String title;
  final String caption;
}

/// White rounded checklist row: blue hand glyph, bold title, gray caption.
/// Native 343x74, r20, 1px #EEEEF2 border, y+1/blur2 #0000000D shadow.
class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.item});

  final _Checklist item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: const Color(0xFFEEEEF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_outlined,
              size: 24, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.tr(item.title),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.tr(item.caption),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width blue->teal gradient CTA with a fan glyph (native 343x52, r26).
class _StartCleaningButton extends StatelessWidget {
  const _StartCleaningButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.ctaGradient,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.toys, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                context.l10n.tr('Start Cleaning'),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dim scrim + centered dark rounded loader shown while the cleaner spins up
/// (native 128x120 box, r14, #000000B2). Ad-free: a plain preparing spinner.
class _PreparingOverlay extends StatelessWidget {
  const _PreparingOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0x61000000),
        child: Center(
          child: Container(
            width: 128,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xB2000000),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.l10n.tr('Preparing…'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 40pt white circular back button with a soft shadow (native x8 y20, r20).
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.tr('Back'),
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back_ios_new,
                size: 18, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
