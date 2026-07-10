import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_shell.dart';
import 'l10n/app_strings.dart';
import 'screen_registry.dart';
import 'screens/splash_screen.dart';
import 'state/language_state.dart';
import 'state/plan_progress.dart';
import 'state/pro_entitlement.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore persisted 7-day plan progress, the Pro subscription entitlement and
  // the selected UI language before the first frame; listening screens rebuild
  // once each resolves (all are safe no-ops if persistence is unavailable, e.g.
  // web previews).
  PlanProgress.instance.load();
  ProEntitlement.instance.load();
  LanguageState.instance.load();
  runApp(const SpeakerCleanerApp());
}

class SpeakerCleanerApp extends StatelessWidget {
  const SpeakerCleanerApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return MaterialApp(
      title: 'Speaker Cleaner',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Light appearance only — no dark mode observed (ios_adaptation).
      themeMode: ThemeMode.light,
      initialRoute: '/',
      onGenerateRoute: _onGenerateRoute,
      // Wrap the whole app (above the Navigator) in the language scope so that
      // changing the language on the Language screen re-localizes every visible
      // screen — including already-pushed routes — with no restart.
      builder: (context, child) => LanguageScope(
        state: LanguageState.instance,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Routes:
///   `/`                 -> the launch gate: the branded splash, which after
///                          loading advances to the paywall (free user) or the
///                          Cleaner tab shell (subscribed). See [SplashScreen].
///   `/screen/<id>`      -> canonical web preview / deep-link target for a
///                          screen. Tab screens open the shell at their tab;
///                          everything else renders standalone.
///   `iosforge://screen/<id>` -> delivered by the platform as the same name and
///                          resolved identically via [_extractScreenId].
Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  final name = settings.name;
  if (name == null || name.isEmpty || name == '/') {
    // Cold-launch entry: splash -> paywall -> home gating flow. The splash
    // renders standalone at `/screen/0000`; only this boot entry auto-advances.
    return _page(const SplashScreen(gate: true), settings);
  }

  final id = _extractScreenId(name);
  if (id != null) {
    final info = kScreens[id];
    if (info?.tabIndex != null) {
      return _page(AppShell(initialTab: info!.tabIndex!), settings);
    }
    return _page(
      Builder(builder: (context) => buildScreenById(context, id)),
      settings,
    );
  }

  // Unknown route: fall back to the shell so the app never dead-ends.
  return _page(const AppShell(), settings);
}

MaterialPageRoute<dynamic> _page(Widget child, RouteSettings settings) =>
    MaterialPageRoute<dynamic>(builder: (_) => child, settings: settings);

/// Pulls the screen id out of a route name / deep-link URI.
///
/// Handles `/screen/0011`, `iosforge://screen/0011`, `/#/screen/0011`
/// (already stripped to `/screen/0011` by the web engine) and bare `/0011`.
String? _extractScreenId(String name) {
  final uri = Uri.tryParse(name);
  if (uri == null) return null;
  final segments = <String>[
    uri.host,
    ...uri.pathSegments,
  ].where((s) => s.isNotEmpty && s != 'screen').toList();
  if (segments.isEmpty) return null;
  return segments.last;
}
