import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/pro_entitlement.dart';
import '../theme.dart';

/// Settings screen (screen 0003).
///
/// Ground truth: source/0003.json (375x667 reference). A plain white page with
/// a back button + bold "Settings" title (native title glyph at x56 y38), a
/// blue promo card (#67B9FF, x16 y90 w343 h144, r20) advertising Pro with a
/// watery-phone hero on the left, "Full access to all features" and a white
/// "Get Pro" pill (x182 y171 w157 h36, r18), then a light-blue settings card
/// (#F5FBFF, x16 y254, r20) whose rows are Change Language / Share App /
/// Feedback (icon x36/40, title y274/332/389, chevron x330).
///
/// Ad-free clone: the native GADNativeAdView (screens.json 0003, 343x250 at
/// y417) is removed entirely — the settings card simply sizes to its rows and
/// the page ends there, with no reserved banner strip.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _promoBlue = Color(0xFF67B9FF);
  static const Color _cardTint = Color(0xFFF5FBFF);
  static const Color _rowIcon = Color(0xFF369FFF);
  static const Color _chevron = Color(0xFF8A929E);

  void _back(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/screen/0011');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title bar: back chevron + bold "Settings".
                  Row(
                    children: [
                      _BackButton(onTap: () => _back(context)),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.tr('Settings'),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  // "Get Pro" upsell banner — hidden once subscribed
                  // (REQ-1104 / spec: "Pro banner hidden when already
                  // subscribed"); the settings card then reflows upward with no
                  // reserved gap.
                  AnimatedBuilder(
                    animation: ProEntitlement.instance,
                    builder: (context, _) {
                      if (ProEntitlement.instance.isPro) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProCard(
                            onGetPro: () =>
                                Navigator.of(context).pushNamed('/screen/0001'),
                          ),
                          const SizedBox(height: 34),
                        ],
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardTint,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.public,
                          iconColor: _rowIcon,
                          title: context.l10n.tr('Change Language'),
                          subtitle:
                              context.l10n.tr('Select your preferred language'),
                          chevronColor: _chevron,
                          onTap: () =>
                              Navigator.of(context).pushNamed('/screen/0004'),
                        ),
                        _SettingsRow(
                          icon: Icons.share_outlined,
                          iconColor: _rowIcon,
                          title: context.l10n.tr('Share App'),
                          subtitle: context.l10n.tr('Share this app with friends'),
                          chevronColor: _chevron,
                          onTap: () => _showInfo(context, context.l10n.tr('Share App'),
                              'Invite your friends to Speaker Cleaner.'),
                        ),
                        _SettingsRow(
                          icon: Icons.mail_outline,
                          iconColor: _rowIcon,
                          title: context.l10n.tr('Feedback'),
                          subtitle: context.l10n.tr('Tell us what you think'),
                          chevronColor: _chevron,
                          onTap: () => _showInfo(context, context.l10n.tr('Feedback'),
                              'We would love to hear your feedback.'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String body) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Circular-tap back chevron mirroring the native 40x40 hit target at x8 y32.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox(
        width: 40,
        height: 40,
        child: Icon(Icons.arrow_back_ios_new,
            size: 22, color: AppColors.textPrimary),
      ),
    );
  }
}

/// Blue "Full access to all features" promo card with the watery-phone hero
/// and the white "Get Pro" pill (native card #67B9FF, r20, 343x144).
class _ProCard extends StatelessWidget {
  const _ProCard({required this.onGetPro});

  final VoidCallback onGetPro;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 144,
      decoration: BoxDecoration(
        color: SettingsScreen._promoBlue,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Watery-phone hero bleeding off the left edge.
          Positioned(
            left: -18,
            top: 8,
            bottom: 8,
            width: 150,
            child: CustomPaint(painter: _DropletHeroPainter()),
          ),
          // Right column: two-line headline + Get Pro pill.
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            width: 172,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.tr('Full access to all features'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onGetPro,
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      context.l10n.tr('Get Pro'),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
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

/// One tappable settings row: leading tinted icon, title + subtitle, chevron.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.chevronColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color chevronColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Icon(icon, size: 26, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
            Icon(Icons.chevron_right, size: 26, color: chevronColor),
          ],
        ),
      ),
    );
  }
}

/// The promo-card hero: a white disc with a phone tilted into it and a spray of
/// blue water droplets, reconstructing the SwiftUI-drawn illustration (no
/// bundled asset in the archive for this node).
class _DropletHeroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.42, h * 0.5);
    final radius = h * 0.46;

    // White disc backdrop.
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);

    // Phone: a dark rounded slab tilted across the disc.
    canvas.save();
    canvas.translate(center.dx - radius * 0.35, center.dy - radius * 0.15);
    canvas.rotate(-0.5);
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: radius * 0.9, height: radius * 1.7),
      const Radius.circular(7),
    );
    canvas.drawRRect(
      phoneRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF3A3F4A), Color(0xFF1D2129)],
        ).createShader(phoneRect.outerRect),
    );
    // Screen sliver.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset.zero, width: radius * 0.62, height: radius * 1.4),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFEDEFF3),
    );
    canvas.restore();

    // Water droplets spraying out to the right.
    void drop(Offset o, double r) {
      final path = Path()
        ..moveTo(o.dx, o.dy - r * 1.4)
        ..cubicTo(o.dx + r, o.dy - r * 0.2, o.dx + r, o.dy + r * 0.4,
            o.dx, o.dy + r)
        ..cubicTo(o.dx - r, o.dy + r * 0.4, o.dx - r, o.dy - r * 0.2,
            o.dx, o.dy - r * 1.4)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: const [Color(0xFFBFE9FF), Color(0xFF4FB4F5)],
          ).createShader(path.getBounds()),
      );
      canvas.drawCircle(
        Offset(o.dx - r * 0.3, o.dy),
        r * 0.28,
        Paint()..color = Colors.white.withOpacity(0.7),
      );
    }

    drop(Offset(w * 0.74, h * 0.32), h * 0.11);
    drop(Offset(w * 0.86, h * 0.55), h * 0.16);
    drop(Offset(w * 0.66, h * 0.66), h * 0.09);
  }

  @override
  bool shouldRepaint(covariant _DropletHeroPainter oldDelegate) => false;
}
