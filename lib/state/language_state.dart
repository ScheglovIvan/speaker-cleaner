import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One selectable UI language.
///
/// [code] is the locale key used to look up translations (see
/// `l10n/app_strings.dart`), [name] is the display label shown in the picker
/// (always rendered in its own language, matching the native list — English,
/// Vietnamese, Chinese (Simplified)…) and [flag] is the painter code used to
/// draw its flag disc on the Language screen.
class AppLanguage {
  const AppLanguage(this.code, this.name, this.flag);

  final String code;
  final String name;
  final String flag;
}

/// App-wide selected-language / localization state.
///
/// Domain rules (app_spec.json workflow "Change language" +
/// REQ-settings-language): the user opens Settings -> Change Language, picks a
/// language (radio), taps Save, and "the app UI updates to the chosen
/// language". The choice is persisted on-device (content.persistence: "local
/// (offline) — … selected language … stored on-device").
///
/// A single [instance] is shared app-wide. It is a [ChangeNotifier], and the
/// root wraps the app in a `LanguageScope` (`InheritedNotifier`) bound to it, so
/// every screen that reads a localized string via `context.l10n` re-renders in
/// the new language the moment [setLanguage] is called — no restart required.
class LanguageState extends ChangeNotifier {
  LanguageState._();

  /// App-wide singleton.
  static final LanguageState instance = LanguageState._();

  static const String _kKey = 'selected_language_code';

  /// The languages offered on the Language screen (screen 0004), in the native
  /// order (English selected by default). Display names stay in their own
  /// language exactly as the original app shows them.
  static const List<AppLanguage> languages = <AppLanguage>[
    AppLanguage('en', 'English', 'gb'),
    AppLanguage('vi', 'Vietnamese', 'vn'),
    AppLanguage('zh-Hans', 'Chinese (Simplified)', 'cn'),
    AppLanguage('zh-Hant', 'Chinese (Traditional)', 'tw'),
    AppLanguage('fr', 'French', 'fr'),
    AppLanguage('de', 'German', 'de'),
    AppLanguage('it', 'Italian', 'it'),
    AppLanguage('nl', 'Dutch', 'nl'),
    AppLanguage('ru', 'Russian', 'ru'),
    AppLanguage('es', 'Spanish', 'es'),
    AppLanguage('pt', 'Portuguese', 'pt'),
    AppLanguage('ja', 'Japanese', 'jp'),
    AppLanguage('ko', 'Korean', 'kr'),
  ];

  static const String _defaultCode = 'en';

  String _code = _defaultCode;
  bool _loaded = false;

  /// Current locale code (e.g. 'en', 'fr', 'zh-Hans'). Persisted locally.
  String get code => _code;

  /// True once the persisted choice has been read (or the read failed).
  bool get isLoaded => _loaded;

  /// The currently selected [AppLanguage].
  AppLanguage get current => languages.firstWhere(
        (l) => l.code == _code,
        orElse: () => languages.first,
      );

  /// Index of the current language in [languages] (0 if unknown).
  int get selectedIndex {
    final i = languages.indexWhere((l) => l.code == _code);
    return i < 0 ? 0 : i;
  }

  /// Loads the persisted language. Safe to call once at startup; failures fall
  /// back to English so headless/web previews still render.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kKey);
      if (stored != null && languages.any((l) => l.code == stored)) {
        _code = stored;
      }
    } catch (_) {
      // Persistence unavailable — keep the default (English).
    }
    _loaded = true;
    notifyListeners();
  }

  /// Selects [code], persists it and re-localizes the UI (the "Save" action on
  /// the Language screen). No-op if the language is unchanged.
  Future<void> setLanguage(String code) async {
    if (!languages.any((l) => l.code == code) || code == _code) return;
    _code = code;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, code);
    } catch (_) {
      // Ignore write failures; in-memory state stays authoritative this session.
    }
  }
}
