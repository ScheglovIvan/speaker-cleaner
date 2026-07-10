import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/pro_entitlement.dart';
import '../theme.dart';
import '../util/haptics.dart';

/// Pro subscription paywall (screen 0001).
///
/// Spec: app_spec.json screens[0001] — "Speaker Deep Clean Pro" with a 3-day
/// free trial then $6.99/week, a full-width gradient CTA and Privacy / Terms
/// links. Ground truth geometry from source/0001.json (375x667 reference):
/// a full-bleed light-blue field with a watery phone hero up top, a
/// crown+laurel "5,000,000+ Users Trust Us" social-proof band, a bold two-line
/// title, the offer + price, a 343x55 (r=27.25) pill CTA, then the two legal
/// links (native frames y=609: Privacy at x=24, Term Of Use at x=279) and the
/// fine-print disclaimer.
///
/// The hero illustration, the "Clean Now" pill and the bubble / timer badges
/// are drawn by SwiftUI in the original (no bundled asset in the archive), so
/// they are reconstructed here with widgets + CustomPaint — the same approach
/// used for the splash app icon.
///
/// Ad-free clone: the original build used this paywall to also strip ads; no
/// ad banner ever appeared on this screen, so nothing ad-related is recreated.
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _purchasing = false;
  bool _restoring = false;

  static const Color _ink = Color(0xFF1A1E27); // bold near-black headings
  static const Color _muted = Color(0xFF7C8698); // price / disclaimer grey
  static const Color _fieldTop = Color(0xFFDBF0F7); // watery light-blue top
  static const Color _fieldBottom = Color(0xFFFFFFFF);

  /// Dismiss to the home tab shell. On a deep-link / web-preview entry there is
  /// nothing to pop, so route to the Cleaner home (spec navigates_to 0011).
  void _dismiss() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/screen/0011');
    }
  }

  /// Start Free Trial -> StoreKit purchase (spec REQ-purchase-subscription).
  /// Drives [ProEntitlement.purchase]; on success the Pro entitlement is granted
  /// and persisted (unlocking all features / hiding upsells), then the paywall
  /// dismisses to home.
  Future<void> _startTrial() async {
    if (_purchasing || _restoring) return;
    Haptics.impact();
    setState(() => _purchasing = true);
    final ok = await ProEntitlement.instance.purchase();
    if (!mounted) return;
    setState(() => _purchasing = false);
    if (ok) {
      Haptics.success();
      _dismiss();
    }
  }

  /// Restore Purchases -> StoreKit restore (spec paywall "restore" interaction).
  /// Re-checks the store for an existing entitlement; if found, dismisses to the
  /// now-unlocked app, otherwise tells the user nothing was found.
  Future<void> _restore() async {
    if (_purchasing || _restoring) return;
    setState(() => _restoring = true);
    final found = await ProEntitlement.instance.restore();
    if (!mounted) return;
    setState(() => _restoring = false);
    if (found) {
      _dismiss();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous purchase to restore.')),
      );
    }
  }

  void _openLegal(String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(
          '$title for Speaker Deep Clean Pro.\n\nThe subscription is billed '
          'through your App Store account. Cancel anytime up to 24 hours '
          'before the trial ends.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fieldBottom,
      body: Stack(
        children: [
          // Full-bleed watery field with drifting bubbles behind everything.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_fieldTop, _fieldBottom],
                  stops: [0.0, 0.42],
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _BubbleFieldPainter()),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _HeroSection(),
                      const SizedBox(height: 4),
                      const _SocialProof(),
                      const SizedBox(height: 22),
                      // Title (native two lines, bold ~34).
                      const Text(
                        'Speaker Deep\nClean Pro',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 34,
                          height: 1.08,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.l10n.tr('3-DAY FREE TRIAL'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // then $6.99/week, cancel anytime  (price emphasised).
                      Text.rich(
                        const TextSpan(
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 21,
                            fontWeight: FontWeight.w500,
                            color: _muted,
                            height: 1.2,
                          ),
                          children: [
                            TextSpan(text: 'then '),
                            TextSpan(
                              text: r'$6.99',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                            TextSpan(text: '/week, cancel anytime'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 26),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _StartTrialButton(
                          purchasing: _purchasing,
                          onTap: _startTrial,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Restore Purchases (StoreKit restore) for returning subs.
                      _RestoreLink(
                        restoring: _restoring,
                        onTap: _restore,
                      ),
                      const SizedBox(height: 14),
                      // Legal links: Privacy (left) / Term Of Use (right).
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _LegalLink(
                              label: context.l10n.tr('Privacy'),
                              onTap: () => _openLegal('Privacy Policy'),
                            ),
                            _LegalLink(
                              label: context.l10n.tr('Term Of Use'),
                              onTap: () => _openLegal('Terms of Use'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'No commitment. Cancel anytime. You can cancel your '
                          'subscription anytime through your App Store account '
                          'settings up to 24 hours before the end of the free '
                          'trial period.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: _muted,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Circular X close (native 28x28, r=14, #00000033, at 16/28).
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: _CloseButton(onTap: _dismiss),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The watery phone hero: a white rounded phone frame filled with a blue water
/// surface, a centered "Clean Now" pill, and the orange-bubble / purple-timer
/// badges that flank it.
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Phone frame with water fill.
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              width: 240,
              height: 296,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                border: Border.all(color: Colors.white, width: 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                child: CustomPaint(
                  painter: _WaterPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          // Orange bubble badge on the left (native circle ~x -38 overlap).
          Positioned(
            left: 8,
            top: 88,
            child: _CircleBadge(
              size: 92,
              glow: const Color(0xFFFF7A1A),
              child: CustomPaint(
                size: const Size(56, 56),
                painter: _BubbleClusterPainter(),
              ),
            ),
          ),
          // Purple timer badge on the right.
          Positioned(
            right: 4,
            top: 150,
            child: _CircleBadge(
              size: 96,
              glow: const Color(0xFF7C6BF0),
              child: const Icon(Icons.timer_outlined,
                  size: 46, color: Color(0xFF7C6BF0)),
            ),
          ),
          // "Clean Now" pill centered over the phone.
          Positioned(
            top: 158,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B9BFF), Color(0xFF2F7BF0)],
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2F7BF0).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.tr('Clean Now'),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

/// Crown + laurel band with the "5,000,000+ Users Trust Us" social proof.
class _SocialProof extends StatelessWidget {
  const _SocialProof();

  @override
  Widget build(BuildContext context) {
    const laurel = Color(0xFF2E8FE0);
    return Column(
      children: [
        const Icon(Icons.workspace_premium, size: 34, color: Color(0xFF2E8FE0)),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
              child: CustomPaint(
                size: const Size(46, 74),
                painter: _LaurelPainter(color: laurel),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '5,000,000+',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1E27),
                    ),
                  ),
                  Text(
                    'Users Trust Us',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3A4150),
                    ),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: const Size(46, 74),
              painter: _LaurelPainter(color: laurel),
            ),
          ],
        ),
      ],
    );
  }
}

/// Full-width blue->teal gradient CTA pill (native 343x55, r=27.25).
class _StartTrialButton extends StatelessWidget {
  const _StartTrialButton({required this.purchasing, required this.onTap});

  final bool purchasing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          gradient: AppColors.ctaGradient,
          borderRadius: BorderRadius.circular(31),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: purchasing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                context.l10n.tr('Start Free Trial'),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

/// Centered "Restore Purchases" link; shows a small spinner while the StoreKit
/// restore is in flight.
class _RestoreLink extends StatelessWidget {
  const _RestoreLink({required this.restoring, required this.onTap});

  final bool restoring;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: restoring
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C7688)),
              ),
            )
          : Text(
              context.l10n.tr('Restore Purchases'),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6C7688),
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF6C7688),
              ),
            ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: Color(0xFF6C7688),
          decoration: TextDecoration.underline,
          decorationColor: Color(0xFF6C7688),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          color: Color(0x59000000), // ~#00000033 tuned for contrast
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 16, color: Colors.white),
      ),
    );
  }
}

/// A soft white circle with a colored outer glow, used for the hero badges.
class _CircleBadge extends StatelessWidget {
  const _CircleBadge({required this.size, required this.glow, required this.child});

  final double size;
  final Color glow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: glow.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: glow.withOpacity(0.28),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Water surface inside the phone frame: a pale-to-deep blue field with a
/// couple of wave crests and a scatter of rising bubbles.
class _WaterPainter extends CustomPainter {
  const _WaterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base vertical gradient — bright sky at top into deeper water.
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFEAF6FC), Color(0xFFBFE4F2), Color(0xFF7FC3E6)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Wave crest band near the top third.
    final crestY = h * 0.30;
    final wave = Path()..moveTo(0, crestY);
    for (var x = 0.0; x <= w; x += w / 4) {
      wave.relativeQuadraticBezierTo(w / 8, -12, w / 4, 0);
    }
    wave
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final waterFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6FBCE6), Color(0xFF3E97D6)],
      ).createShader(Rect.fromLTWH(0, crestY, w, h - crestY));
    canvas.drawPath(wave, waterFill);

    // Foam highlight along the crest.
    final foam = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final crest = Path()..moveTo(0, crestY);
    for (var x = 0.0; x <= w; x += w / 4) {
      crest.relativeQuadraticBezierTo(w / 8, -12, w / 4, 0);
    }
    canvas.drawPath(crest, foam);

    // Rising bubbles in the deep water.
    final bubble = Paint()..color = Colors.white.withOpacity(0.55);
    const seeds = <Offset>[
      Offset(0.62, 0.44),
      Offset(0.70, 0.52),
      Offset(0.55, 0.58),
      Offset(0.78, 0.62),
      Offset(0.40, 0.70),
      Offset(0.66, 0.74),
    ];
    for (final s in seeds) {
      canvas.drawCircle(Offset(s.dx * w, s.dy * h), 3.2, bubble);
    }
  }

  @override
  bool shouldRepaint(covariant _WaterPainter oldDelegate) => false;
}

/// Orange bubble cluster for the left hero badge.
class _BubbleClusterPainter extends CustomPainter {
  const _BubbleClusterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    Paint fill(Color a, Color b, Offset center, double r) => Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [a, b],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    void bubble(Offset o, double r) {
      canvas.drawCircle(
        o,
        r,
        fill(const Color(0xFFFFB067), const Color(0xFFFF7A1A), o, r),
      );
      canvas.drawCircle(
        Offset(o.dx - r * 0.3, o.dy - r * 0.3),
        r * 0.28,
        Paint()..color = Colors.white.withOpacity(0.7),
      );
    }

    bubble(c.translate(-2, 2), size.width * 0.30);
    bubble(c.translate(size.width * 0.22, -size.height * 0.14), size.width * 0.17);
    bubble(c.translate(-size.width * 0.24, size.height * 0.22), size.width * 0.12);
    bubble(c.translate(size.width * 0.06, size.height * 0.28), size.width * 0.09);
  }

  @override
  bool shouldRepaint(covariant _BubbleClusterPainter oldDelegate) => false;
}

/// A single laurel branch (leaves fanning up along a curved stem). Drawn once
/// and mirrored for the opposite side of the social-proof number.
class _LaurelPainter extends CustomPainter {
  const _LaurelPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stem = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // Curved stem sweeping from bottom-inner up to top.
    final path = Path()
      ..moveTo(w * 0.85, h)
      ..quadraticBezierTo(w * 0.1, h * 0.7, w * 0.35, 0);
    canvas.drawPath(path, stem);

    final leaf = Paint()..color = color;
    // Sample points along the stem and sprout leaves outward.
    const n = 6;
    for (var i = 0; i < n; i++) {
      final t = 0.12 + i * (0.8 / n);
      // Approximate the quadratic stem position.
      final p0 = Offset(w * 0.85, h);
      final p1 = Offset(w * 0.1, h * 0.7);
      final p2 = Offset(w * 0.35, 0);
      final mt = 1 - t;
      final pos = Offset(
        mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx,
        mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy,
      );
      final angle = -math.pi / 3 - i * 0.06;
      _drawLeaf(canvas, pos, angle, w * 0.34, h * 0.14, leaf);
    }
  }

  void _drawLeaf(
      Canvas canvas, Offset at, double angle, double len, double wid, Paint p) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * 0.5, -wid, len, 0)
      ..quadraticBezierTo(len * 0.5, wid, 0, 0)
      ..close();
    canvas.drawPath(leaf, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LaurelPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Faint decorative bubbles drifting across the light-blue field, mirroring the
/// scattered bubbles in the top corners of the native paywall.
class _BubbleFieldPainter extends CustomPainter {
  const _BubbleFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fill = Paint()..color = Colors.white.withOpacity(0.35);

    // Relative positions (x, y, radius) concentrated in the top corners.
    const spots = <List<double>>[
      [0.10, 0.05, 6],
      [0.16, 0.08, 4],
      [0.07, 0.11, 3],
      [0.13, 0.13, 5],
      [0.04, 0.16, 3],
      [0.88, 0.04, 7],
      [0.93, 0.07, 4],
      [0.84, 0.09, 3],
      [0.90, 0.12, 5],
      [0.96, 0.15, 3],
      [0.80, 0.14, 2.5],
    ];
    for (final s in spots) {
      final o = Offset(s[0] * w, s[1] * h);
      final r = s[2];
      canvas.drawCircle(o, r, fill);
      canvas.drawCircle(o, r, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleFieldPainter oldDelegate) => false;
}
