import 'package:flutter/material.dart';

import '../theme.dart';

/// Progress state of one day in the 7-day cleaning plan.
///
/// This is a *derived* state — a day's real lock/unlock/completed status comes
/// from [PlanProgress] (persisted high-water mark), not from the static content
/// below. See `state/plan_progress.dart`.
enum PlanDayStatus { completed, unlocked, locked }

/// One day of the guided "7-Day Cleaning Plan" — pure content (its runtime
/// progression status is computed by [PlanProgress]).
///
/// Content ground truth (app_spec.json content.summary + screens 0006/0007/0010):
///   Day 1 Water Ejection 36s, Day 2 Deep Clean 83s, Day 3 Dust Removal 59s,
///   Day 4 Speaker Check, then Days 5-7. Only days 1-4 were captured in the
///   crawl; 5-7 are filled with on-theme routines so the locked list matches
///   the six locked/`padlock` rows seen in the native scroll.
class PlanDay {
  const PlanDay({
    required this.day,
    required this.title,
    required this.seconds,
    required this.subtitle,
  });

  final int day;
  final String title;
  final int seconds;

  /// Short target line — shown plain in the list ("Shake out hidden dust")
  /// and prefixed with "Target: " on the day-detail screen.
  final String subtitle;

  /// "Day 2 • 83 seconds"
  String get meta => 'Day $day • $seconds seconds';
}

/// The seven plan days, in order. Runtime lock/unlock/completed state is applied
/// on top of this list by [PlanProgress] (Day 1 completed by default).
const List<PlanDay> kPlanDays = <PlanDay>[
  PlanDay(
    day: 1,
    title: 'Water Ejection',
    seconds: 36,
    subtitle: 'Flush trapped water from the grille',
  ),
  PlanDay(
    day: 2,
    title: 'Deep Clean',
    seconds: 83,
    subtitle: 'Remove stubborn debris from speakers',
  ),
  PlanDay(
    day: 3,
    title: 'Dust Removal',
    seconds: 59,
    subtitle: 'Shake out hidden dust',
  ),
  PlanDay(
    day: 4,
    title: 'Speaker Check',
    seconds: 45,
    subtitle: 'Verify clear, balanced sound',
  ),
  PlanDay(
    day: 5,
    title: 'Moisture Guard',
    seconds: 52,
    subtitle: 'Push out lingering moisture',
  ),
  PlanDay(
    day: 6,
    title: 'Sound Boost',
    seconds: 68,
    subtitle: 'Restore full speaker volume',
  ),
  PlanDay(
    day: 7,
    title: 'Final Refresh',
    seconds: 90,
    subtitle: 'Complete your 7-day cleanup',
  ),
];

/// Blue card border seen on the plan cards (native `#9BD3FF`).
const Color kPlanCardBorder = Color(0xFF9BD3FF);

/// Illustrated hero used by the plan header and the day-detail card.
///
/// The native build shows a stock photo (hands wiping a phone). No such asset
/// is bundled in `media.json` (only ad creatives), so this renders an on-brand
/// gradient with a phone + cleaning glyph in its place.
class CleaningArt extends StatelessWidget {
  const CleaningArt({super.key, this.borderRadius});

  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9EEF2), Color(0xFFD7DEE4)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Icon(
              Icons.water_drop,
              size: 120,
              color: AppColors.primary.withOpacity(0.10),
            ),
          ),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), blurRadius: 12),
              ],
            ),
            child: const Icon(
              Icons.cleaning_services_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigates back if possible, otherwise routes to the home shell so the
/// standalone web preview (`/#/screen/0007`) never dead-ends.
void planPop(BuildContext context) {
  final nav = Navigator.of(context);
  if (nav.canPop()) {
    nav.pop();
  } else {
    nav.pushReplacementNamed('/screen/0011');
  }
}
