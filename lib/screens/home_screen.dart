import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/plan_progress.dart';
import '../state/pro_entitlement.dart';
import '../theme.dart';
import '../util/haptics.dart';
import 'plan_data.dart';
import 'plan_day_screen.dart';

/// Home / "Cleaner" tab (screen 0011).
///
/// Ground truth: source/0011.json (375x667 reference, safe-area top 20).
/// Layout, top to bottom:
///   * Header — "Speaker Cleaner" wordmark, plus two circular white buttons
///     with #007AFF glyphs: a crown (Pro paywall) and a gear (Settings).
///   * "Deep Clean" today's-routine card — light-blue panel (border #D3ECFF,
///     r=20) with a #369FFF icon disc, title + subtitle, a "Day 2 - 83 seconds"
///     line and a blue->teal gradient "Start Today's Routine" pill.
///   * "Tips & Test Speaker" card — white panel with a left blue accent, a
///     lightbulb disc, title + subtitle and a forward chevron.
///
/// The original screen also painted a Google native ad ("Install" / MyHero
/// block) above the routine card and an ad strip beneath the tab bar. This
/// clone ships ad-free, so both are dropped and the cards reflow upward — no
/// reserved gap is left behind.
///
/// The bottom tab bar is owned by [AppShell]; this widget renders content only.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: const [
                  _RoutineCard(),
                  SizedBox(height: 22),
                  _TipsCard(),
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
          // Crown = Pro upsell while unsubscribed (opens the paywall). Once the
          // Pro entitlement is granted the upsell is replaced by a "PRO" badge
          // (REQ-1104: subscribed users see upsells hidden / a Pro badge).
          AnimatedBuilder(
            animation: ProEntitlement.instance,
            builder: (context, _) {
              if (ProEntitlement.instance.isPro) return const _ProBadge();
              return _CircleButton(
                icon: Icons.workspace_premium,
                semanticsLabel: 'Upgrade to Pro',
                onTap: () {
                  Haptics.tap();
                  Navigator.of(context).pushNamed('/screen/0001');
                },
              );
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

/// Small gradient "PRO" pill shown in place of the crown once the user is
/// subscribed — a status badge, not an upsell (no navigation).
class _ProBadge extends StatelessWidget {
  const _ProBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: AppColors.ctaGradient,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      alignment: Alignment.center,
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, size: 16, color: Colors.white),
          SizedBox(width: 5),
          Text(
            'PRO',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Today's-routine card. Its content tracks the plan's current day
/// ([PlanProgress.currentDay]) — Day 2 "Deep Clean" until Day 2 is completed,
/// then Day 3, and so on — so it rebuilds as progress advances.
class _RoutineCard extends StatelessWidget {
  const _RoutineCard();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PlanProgress.instance,
      builder: (context, _) {
        final progress = PlanProgress.instance;
        final day = progress.currentPlanDay;
        final done = progress.isPlanComplete;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFEAF5FF), Color(0xFFF6FBFF)],
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: const Color(0xFFD3ECFF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.waves, color: Colors.white, size: 24),
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
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          day.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Day ${day.day} - ${day.seconds} seconds',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2B2F3B),
                ),
              ),
              const SizedBox(height: 14),
              _GradientButton(
                label: done
                    ? context.l10n.tr('Run Again')
                    : context.l10n.tr("Start Today's Routine"),
                onTap: () => _openDay(context, day),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Opens the day-detail screen (0007) for [day] (keeps the 0007 route name so
/// analytics / deep-link semantics are unchanged).
void _openDay(BuildContext context, PlanDay day) {
  Haptics.impact();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/screen/0007'),
      builder: (_) => PlanDayScreen(day: day),
    ),
  );
}

/// Full-width blue->teal gradient CTA pill (native: 311x51, r≈25).
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap});

  final String label;
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
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Tips & Test Speaker" card — white panel with a left blue accent bar.
class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Haptics.tap();
          Navigator.of(context).pushNamed('/screen/0010');
        },
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryLight, // blue base -> shows as left accent
            borderRadius: BorderRadius.circular(AppRadii.md),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4097D2FF),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.only(left: 6),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(15),
                right: Radius.circular(AppRadii.md),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 18, 12, 18),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceTint,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tr('Tips & Test Speaker'),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.tr(
                            'Follow simple steps to clean your speaker better.'),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right,
                    color: AppColors.primary, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
