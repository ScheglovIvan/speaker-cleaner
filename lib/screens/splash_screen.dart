import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/pro_entitlement.dart';
import '../theme.dart';

/// Branded splash / loading screen (screens 0000 + 0005).
///
/// Ground truth: source/0000.json & source/0005.json — a full-bleed
/// `#EBF6FF` field with a centered 120x120 rounded (r=24) app icon carrying a
/// soft drop shadow, the "Speaker Cleaner" wordmark below it, and near the
/// bottom a "Loading wonderful places…" caption above a 296x4 (r=2) progress
/// track. Geometry is captured on a 375x667 reference and reproduced
/// proportionally so it holds on any viewport.
///
/// The original build also painted a bottom banner-ad strip and a
/// "This action may contain Ads" disclosure under the progress bar; this clone
/// ships ad-free, so both are dropped and the layout closes up naturally.
///
/// Boot gating (flow-paywall-gate): when [gate] is true this splash is the
/// app's launch screen, so once its loading animation has played and the Pro
/// entitlement has resolved it hands off to the next screen in the native flow
/// (screens.json 0000 -> 0001) — the Pro paywall for a free user, or straight to
/// the Cleaner home (0011) for an already-subscribed user. When [gate] is false
/// (the `/screen/0000` web-preview / deep-link route) it just renders the splash
/// standalone with no auto-advance, so headless verification sees a stable frame.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.gate = false});

  /// When true, auto-advance to the paywall/home gate after loading.
  final bool gate;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _loader;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _fade = CurvedAnimation(parent: _entrance, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _entrance, curve: Curves.easeOutBack),
    );
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    if (widget.gate) _runGate();
  }

  /// Splash -> paywall -> home gate (screens.json 0000 -> 0001, spec launch
  /// flow). Holds the branded splash for a beat so the loader reads as real
  /// startup work, waits for the persisted Pro entitlement to resolve, then
  /// replaces itself with the paywall (free user) or the Cleaner home shell (an
  /// already-subscribed user, upsell suppressed). pushReplacement means the
  /// splash is not left on the back stack, so dismissing the paywall lands on
  /// home rather than briefly flashing the splash again.
  Future<void> _runGate() async {
    final entitlement = ProEntitlement.instance;
    // Minimum on-screen time for the branded splash (loader plays ~1.5 cycles).
    final minSplash =
        Future<void>.delayed(const Duration(milliseconds: 2200));
    if (!entitlement.isLoaded) {
      await entitlement.load();
    }
    await minSplash;
    if (!mounted) return;
    final target = entitlement.isPro ? '/screen/0011' : '/screen/0001';
    Navigator.of(context).pushReplacementNamed(target);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF2B2F3B);
    const captionColor = Color(0xFF6D7A93);

    return Scaffold(
      backgroundColor: AppColors.surfaceTint, // #EBF6FF field
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Icon side scales gently with width but stays close to the native
            // 120pt on a 375pt-wide reference.
            final iconSide = (constraints.maxWidth * 0.32).clamp(104.0, 132.0);
            return Column(
              children: [
                // Icon centre sits ~40% down the field (native y≈269/667).
                const Spacer(flex: 40),
                FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: _AppIcon(side: iconSide),
                  ),
                ),
                SizedBox(height: iconSide * 0.34),
                FadeTransition(
                  opacity: _fade,
                  child: const Text(
                    'Speaker Cleaner',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const Spacer(flex: 55),
                Text(
                  context.l10n.tr('Loading wonderful places…'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: captionColor,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _LoaderBar(animation: _loader),
                ),
                const Spacer(flex: 6),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Indeterminate 4pt-tall track (native: 296x4, r=2) with a white bed and a
/// sliding `#369FFF` segment — the branded loader from the reference.
class _LoaderBar extends StatelessWidget {
  const _LoaderBar({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      width: 296,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LayoutBuilder(
          builder: (context, c) {
            final trackWidth = c.maxWidth;
            const segFraction = 0.32;
            final segWidth = trackWidth * segFraction;
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                // Ease the segment across the track and back so it reads as a
                // living loader rather than a static bar.
                final t = Curves.easeInOut.transform(
                  (animation.value <= 0.5)
                      ? animation.value * 2
                      : (1 - animation.value) * 2,
                );
                final left = t * (trackWidth - segWidth);
                return Stack(
                  children: [
                    Container(color: Colors.white),
                    Positioned(
                      left: left,
                      top: 0,
                      bottom: 0,
                      width: segWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight, // #369FFF
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// The 120x120, r=24 app icon. The original native icon is drawn by SwiftUI
/// (no bundled asset in the archive), so it is reconstructed here: a watery
/// blue tile with cyan droplets ejecting from a phone's charging port — the
/// Speaker Cleaner brand mark.
class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.side});

  final double side;

  @override
  Widget build(BuildContext context) {
    final radius = side * 0.20; // native 24/120
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000), // #00000026
            blurRadius: 8.4,
            offset: Offset(0, 0.8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CustomPaint(
          painter: _IconPainter(),
          size: Size(side, side),
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Watery blue background.
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2E86F0), Color(0xFF1667D8)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Dark phone edge across the top — a charcoal slab tucked behind droplets.
    final phone = Paint()..color = const Color(0xFF3A3E45);
    final phoneRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.10, -h * 0.10, w * 0.80, h * 0.52),
      bottomLeft: Radius.circular(w * 0.10),
      bottomRight: Radius.circular(w * 0.10),
    );
    canvas.drawRRect(phoneRect, phone);
    // Speaker grille dots along the phone's lower edge.
    final grille = Paint()..color = const Color(0xFF23262B);
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(w * (0.20 + i * 0.045), h * 0.40),
        w * 0.012,
        grille,
      );
    }

    // A rounded charging-connector nub poking down from the phone.
    final connector = Paint()..color = const Color(0xFF9AA0A8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.40, h * 0.30, w * 0.20, h * 0.16),
        Radius.circular(w * 0.05),
      ),
      connector,
    );

    // Cyan water droplets ejecting from the grille.
    _drawDrop(canvas, Offset(w * 0.42, h * 0.60), w * 0.085);
    _drawDrop(canvas, Offset(w * 0.60, h * 0.62), w * 0.095);
    _drawDrop(canvas, Offset(w * 0.52, h * 0.74), w * 0.070);
  }

  void _drawDrop(Canvas canvas, Offset c, double r) {
    final path = Path();
    // Rounded teardrop: pointed top, circular bottom.
    path.moveTo(c.dx, c.dy - r * 2.2);
    path.quadraticBezierTo(c.dx - r * 1.05, c.dy - r * 0.6, c.dx - r, c.dy);
    path.arcToPoint(
      Offset(c.dx + r, c.dy),
      radius: Radius.circular(r),
      clockwise: false,
    );
    path.quadraticBezierTo(c.dx + r * 1.05, c.dy - r * 0.6, c.dx, c.dy - r * 2.2);
    path.close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFF7FE4FB), Color(0xFF19B6E8)],
      ).createShader(
        Rect.fromCircle(center: c, radius: r * 2.2),
      );
    canvas.drawPath(path, fill);

    // Glossy highlight.
    final gloss = Paint()..color = const Color(0x99FFFFFF);
    canvas.drawCircle(Offset(c.dx - r * 0.3, c.dy - r * 0.3), r * 0.28, gloss);
  }

  @override
  bool shouldRepaint(covariant _IconPainter oldDelegate) => false;
}
