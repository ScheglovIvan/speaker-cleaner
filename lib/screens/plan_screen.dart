import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/plan_progress.dart';
import '../theme.dart';
import 'plan_data.dart';
import 'plan_day_screen.dart';

/// "7-Day Cleaning Plan" (screens 0006 + 0010).
///
/// Ground truth: source/0006.json & source/0010.json (375x667, safe-area 20).
/// These are the same screen captured at two scroll offsets, so one widget
/// serves both ids. Layout, top to bottom:
///   * Hero illustration with a white rounded sheet overlapping its bottom,
///     and a circular back button floating over the hero (native 40pt disc at
///     x12 y28).
///   * Centered title "7-Day Cleaning Plan" + subtitle
///     "Complete 7 days to fully refresh your speakers".
///   * A scrolling list: Day 1 as a completed "Run Again" card (green check,
///     #DFFDEB disc), then the remaining days as rows — the unlocked day shows
///     a numbered blue disc + chevron, locked days are dimmed with a padlock.
///
/// The native build painted a 343x250 Google native ad between the header and
/// the list; this clone is ad-free, so the list reflows directly under the
/// header with no reserved gap.
class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          // Hero pinned behind the sheet.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 210,
            child: CleaningArt(),
          ),
          // White sheet + header text + scrolling day list.
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 168),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          context.l10n.tr('7-Day Cleaning Plan'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n
                              .tr('Complete 7 days to fully refresh your speakers'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          // Rebuilds whenever a day is completed so newly
                          // unlocked days appear and completed days flip to the
                          // green-check "Run Again" card.
                          child: AnimatedBuilder(
                            animation: PlanProgress.instance,
                            builder: (context, _) {
                              final progress = PlanProgress.instance;
                              return ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 28),
                                itemCount: kPlanDays.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 14),
                                itemBuilder: (context, i) {
                                  final day = kPlanDays[i];
                                  final status = progress.statusFor(day.day);
                                  if (status == PlanDayStatus.completed) {
                                    return _CompletedCard(
                                      day: day,
                                      onRunAgain: () => _openDay(context, day),
                                    );
                                  }
                                  return _DayRow(
                                    day: day,
                                    locked: status == PlanDayStatus.locked,
                                    onTap: () => _openDay(context, day),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating circular back button over the hero.
          Positioned(
            top: topInset + 8,
            left: 12,
            child: _BackButton(onTap: () => planPop(context)),
          ),
        ],
      ),
    );
  }
}

/// Opens the day-detail screen (0007) for a specific plan day. Used by both the
/// unlocked-day rows and the completed cards' "Run Again" pill.
void _openDay(BuildContext context, PlanDay day) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/screen/0007'),
      builder: (_) => PlanDayScreen(day: day),
    ),
  );
}

/// A completed routine, shown as a highlighted "Run Again" card
/// (native: 343x75, r20, blue border, green #DFFDEB check disc).
class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.day, required this.onRunAgain});

  final PlanDay day;
  final VoidCallback onRunAgain;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: kPlanCardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 22, color: Color(0xFF2FA84F)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.meta,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _RunAgainPill(onTap: onRunAgain),
        ],
      ),
    );
  }
}

/// Light-blue "Run Again" pill (native: #EBF6FF bg, r14.5, blue label).
class _RunAgainPill extends StatelessWidget {
  const _RunAgainPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceTint,
      borderRadius: BorderRadius.circular(14.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.5),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            context.l10n.tr('Run Again'),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A plan day row — unlocked (numbered blue disc + chevron, tappable) or
/// locked (dimmed to 0.5 with a padlock). Native cards: 343 wide, r20,
/// #9BD3FF border, #EBF6FF number disc.
class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.locked,
    required this.onTap,
  });

  final PlanDay day;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: kPlanCardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceTint,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  day.meta,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  day.subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            locked ? Icons.lock_outline : Icons.chevron_right,
            size: locked ? 20 : 26,
            color: locked ? AppColors.textSecondary : AppColors.primary,
          ),
        ],
      ),
    );

    if (locked) {
      return Opacity(opacity: 0.5, child: card);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: card,
      ),
    );
  }
}

/// 40pt white circular back button with a soft shadow (native x12 y28, r20).
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
