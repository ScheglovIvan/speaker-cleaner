import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/plan_data.dart';

/// Persistent progression state for the "7-Day Cleaning Plan".
///
/// Domain rules (app_spec.json business_logic.domain_rules):
///   * The plan advances one day at a time; future days are shown locked.
///   * A day is marked complete after its routine finishes; completing a day
///     unlocks the next day.
///   * A completed day can be re-run ("Run Again") without changing progress.
///
/// Progress is a single high-water mark — [highestCompletedDay] — persisted
/// on-device via shared_preferences (content.persistence: "local (offline)").
/// Day 1 starts completed and Day 2 unlocked, matching the captured screens
/// (0006 shows Day 1 done, 0010 shows Day 2 unlocked / Day 3+ locked).
///
/// A single [instance] is shared app-wide; screens listen to it (it is a
/// [ChangeNotifier]) so the plan list, day detail and home routine card all
/// reflect the same progression and rebuild the moment a day completes.
class PlanProgress extends ChangeNotifier {
  PlanProgress._();

  /// App-wide singleton.
  static final PlanProgress instance = PlanProgress._();

  static const String _kKey = 'plan_highest_completed_day';

  /// Day 1 ships completed (Water Ejection), so Day 2 is the first current day.
  static const int _defaultHighestCompleted = 1;

  int _highestCompletedDay = _defaultHighestCompleted;
  bool _loaded = false;

  /// Highest plan day the user has completed (1-based). 0 means nothing done.
  int get highestCompletedDay => _highestCompletedDay;

  /// True once persisted progress has been read (or failed to read).
  bool get isLoaded => _loaded;

  int get totalDays => kPlanDays.length;

  /// The "today's routine" day: the first not-yet-completed day, clamped to the
  /// final day once the whole plan is finished.
  int get currentDay =>
      _highestCompletedDay >= totalDays ? totalDays : _highestCompletedDay + 1;

  /// The [PlanDay] record for [currentDay].
  PlanDay get currentPlanDay =>
      kPlanDays.firstWhere((d) => d.day == currentDay,
          orElse: () => kPlanDays.last);

  /// True once every day in the plan has been completed.
  bool get isPlanComplete => _highestCompletedDay >= totalDays;

  /// Lock/unlock state for [day] given current progress.
  PlanDayStatus statusFor(int day) {
    if (day <= _highestCompletedDay) return PlanDayStatus.completed;
    if (day == _highestCompletedDay + 1) return PlanDayStatus.unlocked;
    return PlanDayStatus.locked;
  }

  /// Whether [day] can be opened (completed days re-run, the next day starts).
  bool isTappable(int day) => day <= _highestCompletedDay + 1;

  /// Loads persisted progress. Safe to call once at startup; failures fall back
  /// to the default (Day 1 complete) so headless/web previews still render.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_kKey);
      if (stored != null) {
        _highestCompletedDay = stored.clamp(0, totalDays).toInt();
      }
    } catch (_) {
      // Persistence unavailable — keep the default progression.
    }
    _loaded = true;
    notifyListeners();
  }

  /// Marks [day] complete after its routine finishes. Completing the current
  /// day advances the high-water mark and unlocks the next day; re-running an
  /// already-completed day ("Run Again") leaves progression unchanged.
  Future<void> markDayComplete(int day) async {
    if (day == _highestCompletedDay + 1) {
      _highestCompletedDay = day.clamp(0, totalDays).toInt();
      notifyListeners();
      await _persist();
    }
    // Re-running a completed (or not-yet-unlocked) day is a no-op here.
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kKey, _highestCompletedDay);
    } catch (_) {
      // Ignore write failures; in-memory state stays authoritative this session.
    }
  }

  /// Resets progress to the initial state (Day 1 complete). Not surfaced in the
  /// UI, but useful for tests / a future "restart plan" affordance.
  @visibleForTesting
  Future<void> reset() async {
    _highestCompletedDay = _defaultHighestCompleted;
    notifyListeners();
    await _persist();
  }
}
