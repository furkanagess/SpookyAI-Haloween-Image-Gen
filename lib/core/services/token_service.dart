import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'trial_guard_service.dart';

class TokenService {
  TokenService._();
  static const String _kTokenKey = 'user_tokens_v2';
  static const String _kInitKey = 'user_tokens_initialized_v2';
  static const String _kTrialGrantedKey = 'trial_granted_once_v2';
  static const String _kDebugBalanceResetKey = 'debug_balance_reset_v1';
  static const double initialTokens = 3.0;

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  static const String _kClaimPendingKey = 'trial_claim_pending_v1';

  /// Every new install starts with [initialTokens], once per device:
  /// * a Keychain flag (iOS keeps it across reinstalls), and
  /// * the server ledger keyed by a reinstall-stable device id
  ///   ([TrialGuardService]; covers Android, where local data is wiped).
  /// If the server cannot be reached the gift is granted and the claim is
  /// recorded on a later launch, so a reinstall after that gets nothing.
  static Future<void>? _initFuture;

  static Future<void> _ensureInitialized() {
    return _initFuture ??= _initialize().catchError((Object e) {
      debugPrint('TokenService: init failed: $e');
      _initFuture = null;
    });
  }

  static Future<void> _initialize() async {
    final prefs = await _prefs();
    if (!(prefs.getBool(_kInitKey) ?? false)) {
      final usedHere = await _secure.read(key: _kTrialGrantedKey) == 'yes';
      var start = 0.0;
      if (!usedHere) {
        final decision = await TrialGuardService.claim();
        if (decision != TrialDecision.alreadyUsed) {
          start = initialTokens;
          if (decision == TrialDecision.unknown) {
            await prefs.setBool(_kClaimPendingKey, true);
          }
        }
      }
      await _secure.write(key: _kTrialGrantedKey, value: 'yes');
      await prefs.setDouble(_kTokenKey, start);
      await prefs.setBool(_kInitKey, true);
      // A fresh install keeps its starter tokens in debug builds too.
      await prefs.setBool(_kDebugBalanceResetKey, true);
    } else if (prefs.getBool(_kClaimPendingKey) ?? false) {
      // Granted while offline: record this device in the ledger now.
      unawaited(
        TrialGuardService.claim().then((d) async {
          if (d != TrialDecision.unknown) await prefs.remove(_kClaimPendingKey);
        }),
      );
    }

    // Reset the developer's persisted test balance once. This is intentionally
    // excluded from release builds so existing customer balances are untouched.
    if (kDebugMode && !(prefs.getBool(_kDebugBalanceResetKey) ?? false)) {
      await prefs.setDouble(_kTokenKey, 0.0);
      await prefs.setBool(_kDebugBalanceResetKey, true);
    }
  }

  static Future<double> getBalance() async {
    await _ensureInitialized();
    final prefs = await _prefs();
    return prefs.getDouble(_kTokenKey) ?? 0.0;
  }

  static Future<void> addTokens(double amount) async {
    final prefs = await _prefs();
    final current = await getBalance();
    final newBalance = current + amount;
    await prefs.setDouble(_kTokenKey, newBalance);
  }

  static Future<bool> consumeOne() async {
    final prefs = await _prefs();
    final current = await getBalance();
    if (current <= 0) return false;
    await prefs.setDouble(_kTokenKey, current - 1.0);
    return true;
  }

  static Future<bool> consumeTokens(double amount) async {
    final prefs = await _prefs();
    final current = await getBalance();
    if (current < amount) return false;
    await prefs.setDouble(_kTokenKey, current - amount);
    return true;
  }

  static Future<void> refundOne() async {
    await addTokens(1.0);
  }

  /// Tokens added for every Premium billing period (purchase + each renewal).
  static const int premiumTokensPerPeriod = 50;

  /// Grant one billing period's Premium tokens.
  static Future<void> grantMonthlyPremiumTokens() async {
    await addTokens(premiumTokensPerPeriod.toDouble());
  }

  /// Grants Premium tokens once per billing period. [periodId] identifies
  /// the period (RevenueCat's latest purchase date changes on every
  /// renewal). Returns true when tokens were added.
  static Future<bool> grantPremiumTokensForPeriod(String periodId) {
    // Serialized: the purchase result and RevenueCat's update listener can
    // both arrive at once and must not grant the same period twice.
    final run = _grantLock.then((_) async {
      const key = 'premium_tokens_granted_period';
      if (await _secure.read(key: key) == periodId) return false;
      await _secure.write(key: key, value: periodId);
      await grantMonthlyPremiumTokens();
      await markMonthlyTokensClaimed();
      return true;
    });
    _grantLock = run.then((_) {}, onError: (_) {});
    return run;
  }

  static Future<void> _grantLock = Future.value();

  /// Check if user can claim monthly tokens
  static Future<bool> canClaimMonthlyTokens() async {
    final lastClaimStr = await _secure.read(key: 'last_monthly_token_claim');

    if (lastClaimStr == null) return true;

    final lastClaim = DateTime.parse(lastClaimStr);
    final now = DateTime.now();
    final daysSinceLastClaim = now.difference(lastClaim).inDays;

    return daysSinceLastClaim >= 30;
  }

  /// Mark monthly tokens as claimed
  static Future<void> markMonthlyTokensClaimed() async {
    await _secure.write(
      key: 'last_monthly_token_claim',
      value: DateTime.now().toIso8601String(),
    );
  }
}

@visibleForTesting
void resetTokenServiceForTest() => TokenService._initFuture = null;
