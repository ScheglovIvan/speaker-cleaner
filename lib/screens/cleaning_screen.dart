import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/cleaner_audio.dart';
import '../l10n/app_strings.dart';
import '../state/plan_progress.dart';
import '../theme.dart';
import '../util/haptics.dart';
import 'plan_data.dart';

/// Cleaning (playing) screen — the "play tone -> Stop/complete" step of the
/// cleaning flow (app_spec state_machine "Cleaning (playing)").
///
/// This screen has no crawled ground truth of its own: in the native build the
/// running state sat behind a rewarded-ad gate (screen 0009 captured only the
/// "Loading ads…" spinner). It is rebuilt here on-brand from the app's own
/// visual language (blue->teal gradient, Poppins, the same pill/disc chrome).
///
/// Behaviour (domain_rules + REQ-play-and-stop + REQ-completion-sound):
///   * On open it plays the mapped tone (looping) — the mode's tone for the
///     quick-clean flow (0012) or the Cleaner routine's tone for a plan day.
///   * For a plan day it counts the routine's duration down second-by-second;
///     the ring fills toward completion. Quick-clean modes run open-ended.
///   * A full-width red "Stop" control (native stereo Stop pill: #FFEAE9 bg,
///     #FF3B30 label) ends the routine immediately.
///   * When the duration elapses or Stop is pressed the tone halts, the
///     completion chime plays, and — if this came from the 7-day plan — the day
///     is marked complete so the next day unlocks. A "Complete" state is shown
///     with a Done button back to the Cleaner home.
///   * Backing out mid-run (the top-left back button) aborts without completing
///     — the "Stopped (user)" terminal — so plan progress is unchanged.
class CleaningScreen extends StatefulWidget {
  const CleaningScreen({
    super.key,
    this.tone = CleanerSound.cleanDust,
    this.planDay,
  });

  /// The tone played while the routine runs (carries the mode picked on 0012;
  /// defaults to the primary Cleaner tone for the plan-day routine).
  final CleanerSound tone;

  /// The plan day this routine belongs to, when reached from the 7-day plan.
  /// On completion that day is marked done and the next unlocks. Null for the
  /// quick-clean mode flow, which does not advance plan progress.
  final PlanDay? planDay;

  @override
  State<CleaningScreen> createState() => _CleaningScreenState();
}

class _CleaningScreenState extends State<CleaningScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  Timer? _ticker;

  /// Total / remaining seconds for a timed plan-day routine (null for modes,
  /// which run open-ended until Stop).
  int? _total;
  int _remaining = 0;

  bool _done = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    final day = widget.planDay;
    if (day != null) {
      _total = day.seconds;
      _remaining = day.seconds;
      _ticker = Timer.periodic(const Duration(seconds: 1), _onTick);
    }
    // Start the calibrated cleaning tone (looping) for the duration of the run.
    CleanerAudio.instance.startTone(widget.tone);
  }

  void _onTick(Timer timer) {
    if (!mounted) return;
    setState(() => _remaining = _remaining > 0 ? _remaining - 1 : 0);
    if (_remaining <= 0) _finish();
  }

  /// Ends the routine: stop the tone, play the completion chime, mark the plan
  /// day complete (unlocking the next), and switch to the Complete state.
  Future<void> _finish() async {
    if (_finishing || _done) return;
    _finishing = true;
    _ticker?.cancel();
    _pulse.stop();
    await CleanerAudio.instance.stopTone();
    await CleanerAudio.instance.playCompletion();
    final day = widget.planDay;
    if (day != null) {
      await PlanProgress.instance.markDayComplete(day.day);
    }
    if (!mounted) return;
    // Mark the routine's end with a heavy confirmation haptic.
    Haptics.success();
    setState(() => _done = true);
  }

  /// Aborts a running routine without completing it (the "Stopped (user)"
  /// terminal): stop the tone and leave. Plan progress is unchanged.
  void _abort() {
    Haptics.tap();
    CleanerAudio.instance.stopTone();
    planPop(context);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    // Never let the tone outlive the screen (e.g. system back / route pop).
    CleanerAudio.instance.stopTone();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    final bottomInset = mq.viewPadding.bottom;
    final day = widget.planDay;
    final title = day?.title ?? context.l10n.tr(widget.tone.label);
    final meta = day != null
        ? day.meta
        : context.l10n.tr('Cleaning in progress');

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24, topInset + 72, 24, 28 + bottomInset),
            child: _done
                ? _CompleteView(
                    day: day,
                    onDone: () {
                      Haptics.tap();
                      Navigator.of(context)
                          .pushReplacementNamed('/screen/0011');
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        meta,
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
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      _RunningDial(
                        pulse: _pulse,
                        total: _total,
                        remaining: _remaining,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.l10n.tr('Cleaning your speaker…'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      _StopButton(onTap: _finish),
                    ],
                  ),
          ),
          if (!_done)
            Positioned(
              top: topInset + 8,
              left: 8,
              child: _BackButton(onTap: _abort),
            ),
        ],
      ),
    );
  }
}

/// The animated running indicator: a pulsing blue->teal disc with a fan glyph,
/// wrapped by a progress ring that fills as a timed routine counts down. For an
/// open-ended mode run (no total) the ring is a soft full track and only the
/// disc pulses.
class _RunningDial extends StatelessWidget {
  const _RunningDial({
    required this.pulse,
    required this.total,
    required this.remaining,
  });

  final Animation<double> pulse;
  final int? total;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final progress = (total != null && total! > 0)
        ? (total! - remaining) / total!
        : null;
    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 8,
                backgroundColor: AppColors.surfaceTint,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.04).animate(
                CurvedAnimation(parent: pulse, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 168,
                height: 168,
                decoration: const BoxDecoration(
                  gradient: AppColors.ctaGradient,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.toys, color: Colors.white, size: 52),
                    if (total != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${remaining}s',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
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

/// The "Complete" terminal: green check disc, a done message (naming the newly
/// unlocked day for a plan routine) and a Done button back to Cleaner home.
class _CompleteView extends StatelessWidget {
  const _CompleteView({required this.day, required this.onDone});

  final PlanDay? day;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final d = day;
    final subtitle = d == null
        ? context.l10n.tr('Your speaker is refreshed.')
        : (d.day >= kPlanDays.length
            ? context.l10n.tr('You finished the 7-day plan!')
            : '${context.l10n.tr('Day')} ${d.day + 1} ${context.l10n.tr('unlocked')}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: AppColors.successBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                size: 64, color: Color(0xFF2FA84F)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.l10n.tr('Cleaning Complete!'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        _DoneButton(onTap: onDone),
      ],
    );
  }
}

/// Full-width blue->teal gradient "Done" pill (native 343x52, r26).
class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onTap});

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
              context.l10n.tr('Done'),
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

/// Full-width Stop control — red label on a light-red pill (native stereo Stop:
/// #FFEAE9 bg, #FF3B30 text). Immediately halts playback (REQ-play-and-stop).
class _StopButton extends StatelessWidget {
  const _StopButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.dangerBg,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stop_rounded, size: 24, color: AppColors.danger),
              const SizedBox(width: 8),
              Text(
                context.l10n.tr('Stop'),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
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
