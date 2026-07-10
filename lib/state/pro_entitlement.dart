import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide "Pro" subscription entitlement.
///
/// Domain rules (app_spec.json business_logic + REQ-purchase-subscription /
/// REQ-1104):
///   * Tapping "Start Free Trial" initiates a StoreKit subscription purchase and,
///     on success, grants the Pro entitlement which "unlocks all features".
///   * While the user is NOT subscribed the app surfaces Pro upsell entry points
///     (the home crown icon, the Settings "Get Pro" banner) that open the paywall.
///   * A subscribed user has those upsells hidden / replaced with a Pro badge.
///   * "Restore" re-checks the store for an existing entitlement.
///
/// The real app talks to StoreKit (`Product.purchase()` / `SKPaymentQueue`,
/// receipt validation). That native flow isn't available in this offline clone,
/// so [purchase]/[restore] stand in for it and the resulting entitlement is
/// persisted on-device via shared_preferences — the same local-persistence
/// approach used by [PlanProgress]. A single [instance] is shared app-wide and
/// it is a [ChangeNotifier], so any screen wrapping an upsell in an
/// `AnimatedBuilder(animation: ProEntitlement.instance, ...)` re-renders the
/// moment Pro is granted or restored.
class ProEntitlement extends ChangeNotifier {
  ProEntitlement._();

  /// App-wide singleton.
  static final ProEntitlement instance = ProEntitlement._();

  static const String _kKey = 'pro_entitlement_active';

  // ---- Offer details (mirrors the paywall copy / StoreKit product) --------
  /// StoreKit product identifier for the weekly Pro subscription.
  static const String productId = 'com.speaker.clean.pro.weekly';

  /// Marketing name shown on the paywall.
  static const String productName = 'Speaker Deep Clean Pro';

  /// Introductory free-trial length, in days.
  static const int trialDays = 3;

  /// Displayed recurring price after the trial.
  static const String priceLabel = r'$6.99';

  /// Billing period label.
  static const String periodLabel = 'week';

  bool _isPro = false;
  bool _loaded = false;

  /// True when the user holds an active Pro entitlement (all features unlocked,
  /// upsells suppressed). Persisted locally so it survives relaunches.
  bool get isPro => _isPro;

  /// True once persisted entitlement has been read (or the read failed).
  bool get isLoaded => _loaded;

  /// Loads the persisted entitlement. Safe to call once at startup; failures
  /// fall back to "not subscribed" so headless/web previews still render.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isPro = prefs.getBool(_kKey) ?? false;
    } catch (_) {
      // Persistence unavailable — treat as not subscribed.
    }
    _loaded = true;
    notifyListeners();
  }

  /// Runs the StoreKit subscription purchase for [productId]. Returns true when
  /// the purchase completes and the Pro entitlement is granted.
  ///
  /// The native StoreKit flow is unavailable in this clone, so this simulates a
  /// brief purchase round-trip and then grants + persists the entitlement.
  Future<bool> purchase() async {
    // Stand-in for `Product.purchase()` presenting the App Store sheet.
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    await _setPro(true);
    return true;
  }

  /// Restores a previously purchased subscription (StoreKit "Restore
  /// Purchases"). Returns true if an active entitlement was found. In this clone
  /// it reflects whatever is persisted locally.
  Future<bool> restore() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!_loaded) await load();
    return _isPro;
  }

  Future<void> _setPro(bool value) async {
    if (_isPro != value) {
      _isPro = value;
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kKey, value);
    } catch (_) {
      // Ignore write failures; in-memory state stays authoritative this session.
    }
  }

  /// Clears the entitlement (e.g. a lapsed subscription). Not surfaced in the
  /// UI, but useful for tests / a future "manage subscription" affordance.
  @visibleForTesting
  Future<void> revoke() => _setPro(false);
}
