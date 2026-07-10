import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme.dart';
import '../util/haptics.dart';

/// dB Meter — the "dB Meter" tab (inferred screen id `dbmeter`).
///
/// This screen was never captured as a screenshot (app_spec.json marks it
/// `source: "inferred"`), so its layout follows the spec's stated convention:
/// a nav header ("Speaker Cleaner" + crown + gear), an arc/gauge meter showing
/// the live decibel reading with current / min / avg / max, a "dB" unit label,
/// and a microphone-permission gate. It uses the app's light-blue theme and
/// Poppins headings like every other tab.
///
/// Spec states: idle -> (grant mic) -> measuring, or (deny) -> permission
/// denied. A real device would read the microphone; in the headless web
/// preview there is no mic, so the gauge is driven by a simulated live signal
/// once "measuring" starts — the geometry and states match the original.
///
/// The bottom tab bar is owned by [AppShell]; this widget renders content only.
class DbMeterScreen extends StatefulWidget {
  const DbMeterScreen({super.key});

  @override
  State<DbMeterScreen> createState() => _DbMeterScreenState();
}

enum _MeterState { idle, measuring, denied }

class _DbMeterScreenState extends State<DbMeterScreen> {
  static const double _minDb = 30;
  static const double _maxDb = 120;

  _MeterState _state = _MeterState.idle;

  double _current = _minDb;
  double _min = _maxDb;
  double _max = _minDb;
  double _sum = 0;
  int _samples = 0;

  final math.Random _rng = math.Random(42);
  Timer? _timer;
  double _target = 55;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Simulate the native microphone-permission prompt. The user either grants
  /// access (-> measuring) or denies it (-> permission denied state).
  Future<void> _requestPermission() async {
    final granted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('"Speaker Cleaner" Would Like to Access the Microphone'),
        content: const Text(
          'Measure the sound level around you to show live decibel readings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Don’t Allow'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (granted == true) {
      _startMeasuring();
    } else {
      setState(() => _state = _MeterState.denied);
    }
  }

  void _startMeasuring() {
    setState(() {
      _state = _MeterState.measuring;
      _current = 55;
      _min = _maxDb;
      _max = _minDb;
      _sum = 0;
      _samples = 0;
      _target = 55;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => _tick());
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _state = _MeterState.idle);
  }

  void _tick() {
    // Random-walk toward a wandering target for a natural, lively needle.
    if (_rng.nextInt(10) == 0) {
      _target = _minDb + _rng.nextDouble() * (_maxDb - _minDb - 20);
    }
    final delta = (_target - _current) * 0.18 + (_rng.nextDouble() - 0.5) * 6;
    final next = (_current + delta).clamp(_minDb, _maxDb);
    setState(() {
      _current = next;
      _min = math.min(_min, next);
      _max = math.max(_max, next);
      _sum += next;
      _samples++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double avg = _samples == 0 ? _current : _sum / _samples;
    final bool active = _state == _MeterState.measuring;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: _Gauge(
                          value: active ? _current : _minDb,
                          minDb: _minDb,
                          maxDb: _maxDb,
                          active: active,
                        ),
                      ),
                    ),
                    if (_state == _MeterState.denied)
                      const _DeniedNotice()
                    else
                      _StatRow(
                        min: active ? _min : 0,
                        avg: active ? avg : 0,
                        max: active ? _max : 0,
                        active: active,
                      ),
                    const SizedBox(height: 24),
                    _ActionButton(state: _state, onTap: _onAction),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAction() {
    Haptics.impact();
    switch (_state) {
      case _MeterState.idle:
      case _MeterState.denied:
        _requestPermission();
        break;
      case _MeterState.measuring:
        _stop();
        break;
    }
  }
}

/// Header — "Speaker Cleaner" wordmark plus the crown (Pro) and gear (Settings)
/// circular buttons, matching the Home tab.
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

/// 40pt white disc with a soft blue shadow and a #007AFF glyph.
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

/// Circular 270° arc gauge. Shows the current dB reading large in the centre
/// with a "dB" unit label; the coloured arc fills from the minimum toward the
/// current value and a knob marks the tip.
class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.value,
    required this.minDb,
    required this.maxDb,
    required this.active,
  });

  final double value;
  final double minDb;
  final double maxDb;
  final bool active;

  @override
  Widget build(BuildContext context) {
    // Target the tween animates toward: the live reading while measuring, or 0
    // when idle so the needle glides back to the start.
    final double target = active ? value : 0;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.min(constraints.maxWidth, constraints.maxHeight)
              .clamp(0.0, 300.0);
          // The reading is sampled in discrete 120ms steps; interpolating
          // between successive samples turns the stepped jumps into a smooth
          // sweeping needle and rolling number.
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: target),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            builder: (context, animated, _) {
              return Semantics(
                container: true,
                label: context.l10n.tr('Sound level meter'),
                value: active
                    ? '${animated.round()} ${context.l10n.tr('decibels')}'
                    : context.l10n.tr('Not measuring'),
                excludeSemantics: true,
                child: SizedBox(
                  width: side,
                  height: side,
                  child: CustomPaint(
                    painter: _GaugePainter(
                      value: active ? animated : minDb,
                      minDb: minDb,
                      maxDb: maxDb,
                      active: active,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            animated.round().toString(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 64,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'dB',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            active
                                ? context.l10n.tr(_labelFor(animated))
                                : context.l10n.tr('Tap start to measure'),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _labelFor(double db) {
    if (db < 50) return 'Quiet';
    if (db < 70) return 'Moderate';
    if (db < 90) return 'Loud';
    return 'Very Loud';
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.minDb,
    required this.maxDb,
    required this.active,
  });

  final double value;
  final double minDb;
  final double maxDb;
  final bool active;

  static const double _startAngle = math.pi * 0.75; // 135°
  static const double _sweep = math.pi * 1.5; // 270°

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const stroke = 16.0;

    final trackPaint = Paint()
      ..color = const Color(0xFFE1EEFB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track.
    canvas.drawArc(rect, _startAngle, _sweep, false, trackPaint);

    // Tick marks around the arc.
    final tickPaint = Paint()
      ..color = const Color(0xFFB9D6F2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const ticks = 27;
    for (var i = 0; i <= ticks; i++) {
      final a = _startAngle + _sweep * (i / ticks);
      final outer = radius - stroke / 2 - 3;
      final inner = outer - (i % 3 == 0 ? 9 : 5);
      final p1 = center + Offset(math.cos(a) * outer, math.sin(a) * outer);
      final p2 = center + Offset(math.cos(a) * inner, math.sin(a) * inner);
      canvas.drawLine(p1, p2, tickPaint);
    }

    if (!active) {
      return;
    }

    final frac = ((value - minDb) / (maxDb - minDb)).clamp(0.0, 1.0);
    final valueSweep = _sweep * frac;

    final valuePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.gradientTeal],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    if (valueSweep > 0.001) {
      canvas.drawArc(rect, _startAngle, valueSweep, false, valuePaint);
    }

    // Knob at the tip of the value arc.
    final knobAngle = _startAngle + valueSweep;
    final knobCenter =
        center + Offset(math.cos(knobAngle) * radius, math.sin(knobAngle) * radius);
    canvas.drawCircle(knobCenter, stroke / 2 + 3, Paint()..color = Colors.white);
    canvas.drawCircle(
      knobCenter,
      stroke / 2 - 1,
      Paint()..color = AppColors.gradientTeal,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.value != value || old.active != active;
}

/// Min / Avg / Max readout row shown beneath the gauge.
class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.min,
    required this.avg,
    required this.max,
    required this.active,
  });

  final double min;
  final double avg;
  final double max;
  final bool active;

  @override
  Widget build(BuildContext context) {
    String fmt(double v) => active ? '${v.round()}' : '--';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: const Color(0xFFD3ECFF)),
      ),
      child: Row(
        children: [
          _stat('Min', fmt(min), const Color(0xFF34C759)),
          _divider(),
          _stat('Avg', fmt(avg), AppColors.primary),
          _divider(),
          _stat('Max', fmt(max), AppColors.warning),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: const Color(0xFFE1EEFB),
      );

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              const Text(
                'dB',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown when microphone permission was denied.
class _DeniedNotice extends StatelessWidget {
  const _DeniedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_off_rounded, color: AppColors.danger, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.tr(
                  'Microphone access is needed to measure sound. Enable it to start.'),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8A2B26),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom action pill — starts, stops, or re-requests microphone access
/// depending on the current state.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.state, required this.onTap});

  final _MeterState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool measuring = state == _MeterState.measuring;
    final String label = measuring
        ? 'Stop'
        : state == _MeterState.denied
            ? 'Enable Microphone'
            : 'Start Measuring';

    if (measuring) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Center(
              child: Text(
                context.l10n.tr(label),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            ),
          ),
        ),
      );
    }

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
              context.l10n.tr(label),
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
