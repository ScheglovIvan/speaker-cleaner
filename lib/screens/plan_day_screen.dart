import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme.dart';
import 'plan_data.dart';
import 'prepare_screen.dart';

/// Day Detail — "Deep Clean" (screen 0007).
///
/// Ground truth: source/0007.json (375x667, safe-area 20). Layout:
///   * Circular back button top-left (native 40pt disc at x8 y20).
///   * Centered blue day meta "Day 2 • 83 seconds".
///   * Centered bold title "Deep Clean".
///   * Centered gray target "Target: Remove stubborn debris from speakers".
///   * A rounded illustration card (native 343x150, r16).
///   * A full-width blue->teal gradient "Start Cleaning" pill with a fan icon,
///     pinned near the bottom.
///
/// The native build placed a 343x250 native ad between the illustration and the
/// button; per app_spec this collapses in the clone and the button reflows up,
/// so no ad chrome or reserved gap remains.
class PlanDayScreen extends StatelessWidget {
  const PlanDayScreen({super.key, this.day});

  final PlanDay? day;

  @override
  Widget build(BuildContext context) {
    final d = day ?? kPlanDays[1]; // default: Day 2, Deep Clean
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, topInset + 60, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  d.meta,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  d.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Target: ${d.subtitle}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3A3D45),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: const AspectRatio(
                    aspectRatio: 343 / 170,
                    child: CleaningArt(),
                  ),
                ),
                const Spacer(),
                _StartCleaningButton(
                  // Carry the day into the prepare flow so its routine, when it
                  // finishes, marks THIS day complete and unlocks the next.
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(name: '/screen/0008'),
                      builder: (_) => PrepareScreen(planDay: d),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: topInset + 8,
            left: 8,
            child: _BackButton(onTap: () => planPop(context)),
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

/// 40pt white circular back button with a soft shadow (native x8 y20, r20).
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
          child: Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.primary),
        ),
      ),
    );
  }
}
