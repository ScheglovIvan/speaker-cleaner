import 'package:flutter/material.dart';

import 'screens/cleaning_screen.dart';
import 'screens/dbmeter_screen.dart';
import 'screens/home_screen.dart';
import 'screens/language_screen.dart';
import 'screens/mode_screen.dart';
import 'screens/paywall_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/plan_day_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/prepare_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/stereo_screen.dart';

/// Metadata for one crawled screen (ids match app_spec.json / screens.json).
class ScreenInfo {
  const ScreenInfo({
    required this.id,
    required this.name,
    required this.builder,
    this.tabIndex,
  });

  final String id;
  final String name;
  final WidgetBuilder builder;

  /// If set, this screen lives inside the bottom tab shell at this index.
  final int? tabIndex;
}

/// The four bottom tabs, in native order: Cleaner / Mode / dB Meter / Stereo.
/// (design_tokens.ios_adaptation -> UITabBar Cleaner/Mode/dB Meter/Stereo.)
const List<String> kTabScreenIds = <String>['0011', '0012', 'dbmeter', '0002'];

/// Central registry of every screen.
///
/// Screen-building tasks REPLACE the `builder` here (or edit the placeholder
/// file it points to) with the real screen widget. Keep the ids stable — the
/// deep-link router (`iosforge://screen/<id>`) and the web preview route
/// (`/screen/<id>`) resolve against these keys.
final Map<String, ScreenInfo> kScreens = <String, ScreenInfo>{
  '0000': ScreenInfo(
    id: '0000',
    name: 'Splash / Loading',
    builder: (_) => const SplashScreen(),
  ),
  '0001': ScreenInfo(
    id: '0001',
    name: 'Pro Paywall',
    builder: (_) => const PaywallScreen(),
  ),
  '0002': ScreenInfo(
    id: '0002',
    name: 'Stereo Mixer',
    tabIndex: 3,
    builder: (_) => const StereoScreen(),
  ),
  '0003': ScreenInfo(
    id: '0003',
    name: 'Settings',
    builder: (_) => const SettingsScreen(),
  ),
  '0004': ScreenInfo(
    id: '0004',
    name: 'Language Selection',
    builder: (_) => const LanguageScreen(),
  ),
  '0005': ScreenInfo(
    id: '0005',
    name: 'Splash (transition)',
    builder: (_) => const SplashScreen(),
  ),
  '0006': ScreenInfo(
    id: '0006',
    name: '7-Day Cleaning Plan',
    builder: (_) => const PlanScreen(),
  ),
  '0007': ScreenInfo(
    id: '0007',
    name: 'Plan — Day Detail (Deep Clean)',
    builder: (_) => const PlanDayScreen(),
  ),
  '0008': ScreenInfo(
    id: '0008',
    name: 'Before You Start',
    builder: (_) => const PrepareScreen(),
  ),
  '0009': ScreenInfo(
    id: '0009',
    name: 'Before You Start (preparing)',
    builder: (_) => const PrepareScreen(preparing: true),
  ),
  '0010': ScreenInfo(
    id: '0010',
    name: 'Plan — Day List',
    builder: (_) => const PlanScreen(),
  ),
  '0011': ScreenInfo(
    id: '0011',
    name: 'Cleaner (Home)',
    tabIndex: 0,
    builder: (_) => const HomeScreen(),
  ),
  '0012': ScreenInfo(
    id: '0012',
    name: 'Cleaning Modes',
    tabIndex: 1,
    builder: (_) => const ModeScreen(),
  ),
  'dbmeter': ScreenInfo(
    id: 'dbmeter',
    name: 'dB Meter',
    tabIndex: 2,
    builder: (_) => const DbMeterScreen(),
  ),
  // Synthetic screen (no crawl id): the "Cleaning (playing)" state reached from
  // Before You Start. Standalone it renders a mode run (no plan day), so the
  // web preview shows the tone-playing UI with the Stop control.
  'cleaning': ScreenInfo(
    id: 'cleaning',
    name: 'Cleaning (playing)',
    builder: (_) => const CleaningScreen(),
  ),
};

/// Renders the screen for [id] standalone (used by the `/screen/:id` web
/// preview route and by non-tab deep links). Falls back to a not-found page.
Widget buildScreenById(BuildContext context, String id) {
  final info = kScreens[id];
  if (info == null) {
    return PlaceholderScreen(id: id, name: 'Unknown screen "$id"');
  }
  return info.builder(context);
}
