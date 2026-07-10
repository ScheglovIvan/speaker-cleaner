import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../state/language_state.dart';
import '../theme.dart';

/// Language selection screen (screen 0004).
///
/// Ground truth: source/0004.json (375x667 reference). A white page with a
/// back button + bold "Language" title and a greyed "Save" pill top-right
/// (native x300 y34 w68 h36, r18, opacity 0.5, border #EEEEF2). Below is a
/// scrolling list of language pills (white, x16 w343 h52, r26) each holding a
/// 28x28 flag disc (x32), the language name and a trailing radio (20x20 at
/// x319). The selected row (English) carries a blue outline (#369FFF) and a
/// filled blue radio; the rest have a light-grey outline and empty radio.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const Color _selBlue = Color(0xFF369FFF);
  static const Color _idleBorder = Color(0xFFEDEEF2);

  // The canonical language list lives in [LanguageState] (shared with the
  // persistence + localization layer). Order mirrors the native list
  // (screens/0004.png): English first, then Vietnamese, the Chinese variants,
  // and the European / world languages.
  static const List<AppLanguage> _langs = LanguageState.languages;

  // Start from the persisted selection so the currently active language shows
  // as chosen when the screen opens.
  late int _selected = LanguageState.instance.selectedIndex;
  bool _dirty = false;

  void _back() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/screen/0003');
    }
  }

  /// Persist the chosen language (re-localizing the whole UI) and return to
  /// Settings — the native "Save" action (REQ-settings-language).
  Future<void> _save() async {
    await LanguageState.instance.setLanguage(_langs[_selected].code);
    if (!mounted) return;
    _back();
  }

  void _select(int i) {
    if (i == _selected) return;
    setState(() {
      _selected = i;
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _back,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.arrow_back_ios_new,
                              size: 22, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.tr('Language'),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      _SaveButton(
                        label: context.l10n.tr('Save'),
                        enabled: _dirty,
                        onTap: _dirty ? _save : null,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _langs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final lang = _langs[i];
                      final selected = i == _selected;
                      return _LangRow(
                        lang: lang,
                        selected: selected,
                        selColor: _selBlue,
                        idleBorder: _idleBorder,
                        onTap: () => _select(i),
                      );
                    },
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

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          width: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEEEEF2), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: enabled ? const Color(0xFF369FFF) : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.lang,
    required this.selected,
    required this.selColor,
    required this.idleBorder,
    required this.onTap,
  });

  final AppLanguage lang;
  final bool selected;
  final Color selColor;
  final Color idleBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: selected ? selColor : idleBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipOval(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CustomPaint(painter: _FlagPainter(lang.flag)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                lang.name,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _Radio(selected: selected, color: selColor),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? color : const Color(0xFFC9CDD4),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          : null,
    );
  }
}

/// Simple painted flag discs. These approximate each nation's flag with its
/// characteristic bands/emblems — reliable across web + native (regional-
/// indicator emoji do not render consistently in headless Chromium).
class _FlagPainter extends CustomPainter {
  _FlagPainter(this.code);

  final String code;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width;
    final h = size.height;
    Paint fill(Color c) => Paint()..color = c;

    void hBands(List<Color> colors) {
      final band = h / colors.length;
      for (var i = 0; i < colors.length; i++) {
        canvas.drawRect(
            Rect.fromLTWH(0, band * i, w, band + 0.5), fill(colors[i]));
      }
    }

    void vBands(List<Color> colors) {
      final band = w / colors.length;
      for (var i = 0; i < colors.length; i++) {
        canvas.drawRect(
            Rect.fromLTWH(band * i, 0, band + 0.5, h), fill(colors[i]));
      }
    }

    void star(Offset c, double r, Color color) {
      final path = Path();
      for (var i = 0; i < 5; i++) {
        final outer = -1.5708 + i * 1.2566;
        final inner = outer + 0.6283;
        final po = Offset(c.dx + r * math.cos(outer), c.dy + r * math.sin(outer));
        final pi = Offset(c.dx + r * 0.42 * math.cos(inner),
            c.dy + r * 0.42 * math.sin(inner));
        if (i == 0) {
          path.moveTo(po.dx, po.dy);
        } else {
          path.lineTo(po.dx, po.dy);
        }
        path.lineTo(pi.dx, pi.dy);
      }
      path.close();
      canvas.drawPath(path, fill(color));
    }

    const red = Color(0xFFCE1126);
    const blue = Color(0xFF10338C);
    const white = Colors.white;

    switch (code) {
      case 'gb': // Union Jack (approximate): blue field, white + red cross.
        canvas.drawRect(rect, fill(const Color(0xFF012169)));
        final wP = Paint()
          ..color = white
          ..strokeWidth = h * 0.34;
        final rP = Paint()
          ..color = const Color(0xFFC8102E)
          ..strokeWidth = h * 0.18;
        // Diagonals.
        canvas.drawLine(Offset(0, 0), Offset(w, h), wP..strokeWidth = h * 0.22);
        canvas.drawLine(Offset(w, 0), Offset(0, h), wP);
        // Central cross.
        canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h),
            Paint()..color = white..strokeWidth = h * 0.34);
        canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2),
            Paint()..color = white..strokeWidth = h * 0.34);
        canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h),
            rP..strokeWidth = h * 0.2);
        canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2),
            Paint()..color = const Color(0xFFC8102E)..strokeWidth = h * 0.2);
        break;
      case 'vn':
        canvas.drawRect(rect, fill(red));
        star(Offset(w / 2, h / 2), w * 0.32, const Color(0xFFFFFF00));
        break;
      case 'cn':
        canvas.drawRect(rect, fill(red));
        star(Offset(w * 0.32, h * 0.35), w * 0.16, const Color(0xFFFFDE00));
        star(Offset(w * 0.58, h * 0.2), w * 0.06, const Color(0xFFFFDE00));
        star(Offset(w * 0.66, h * 0.36), w * 0.06, const Color(0xFFFFDE00));
        star(Offset(w * 0.66, h * 0.56), w * 0.06, const Color(0xFFFFDE00));
        star(Offset(w * 0.58, h * 0.72), w * 0.06, const Color(0xFFFFDE00));
        break;
      case 'tw':
        canvas.drawRect(rect, fill(red));
        canvas.drawRect(
            Rect.fromLTWH(0, 0, w * 0.55, h * 0.55), fill(const Color(0xFF000095)));
        canvas.drawCircle(
            Offset(w * 0.27, h * 0.27), w * 0.12, fill(white));
        star(Offset(w * 0.27, h * 0.27), w * 0.11, const Color(0xFF000095));
        break;
      case 'fr':
        vBands(const [Color(0xFF0055A4), white, Color(0xFFEF4135)]);
        break;
      case 'de':
        hBands(const [Colors.black, Color(0xFFDD0000), Color(0xFFFFCE00)]);
        break;
      case 'it':
        vBands(const [Color(0xFF009246), white, Color(0xFFCE2B37)]);
        break;
      case 'nl':
        hBands(const [Color(0xFFAE1C28), white, Color(0xFF21468B)]);
        break;
      case 'ru':
        hBands(const [white, Color(0xFF0039A6), Color(0xFFD52B1E)]);
        break;
      case 'es':
        hBands(const [Color(0xFFAA151B), Color(0xFFF1BF00), Color(0xFFAA151B)]);
        break;
      case 'pt':
        vBands(const [Color(0xFF006600), Color(0xFFFF0000)]);
        canvas.drawCircle(Offset(w * 0.33, h / 2), w * 0.1,
            fill(const Color(0xFFFFCC00)));
        break;
      case 'jp':
        canvas.drawRect(rect, fill(white));
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.26, fill(const Color(0xFFBC002D)));
        break;
      case 'kr':
        canvas.drawRect(rect, fill(white));
        canvas.drawCircle(Offset(w / 2, h / 2), w * 0.2,
            fill(const Color(0xFFCD2E3A)));
        canvas.drawPath(
          Path()
            ..addArc(
                Rect.fromCircle(center: Offset(w / 2, h / 2), radius: w * 0.2),
                -1.5708, 3.1416),
          fill(blue),
        );
        break;
      default:
        canvas.drawRect(rect, fill(const Color(0xFFDDDDDD)));
    }
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) =>
      oldDelegate.code != code;
}
