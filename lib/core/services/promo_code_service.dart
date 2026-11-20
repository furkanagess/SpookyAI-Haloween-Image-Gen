import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'token_service.dart';
import 'trial_guard_service.dart';

/// Redeem codes live in Firestore at `promo_codes/{CODE}` (doc id = the code
/// in upper case). Fields, all set from the Firebase console:
///
/// - `tokens` (number): tokens one redemption adds.
/// - `maxUses` (number): total redemptions allowed (informational).
/// - `remainingUses` (number): redemptions left; set equal to `maxUses`.
/// - `expiresAt` (timestamp, optional): no redemptions after this moment.
/// - `active` (bool, optional, default true): switch a code off.
///
/// Each redemption writes `promo_codes/{CODE}/redemptions/{deviceId}`, so a
/// device can use a code once. firestore.rules enforce the same limits.
class PromoRedeemResult {
  final bool success;
  final String message;
  final int tokensGranted;

  const PromoRedeemResult({
    required this.success,
    required this.message,
    this.tokensGranted = 0,
  });
}

/// Why a code cannot be redeemed, or null when it can.
enum PromoRejection { notFound, inactive, expired, exhausted, alreadyUsed }

class PromoCodeService {
  static const collection = 'promo_codes';
  static const redemptionsSub = 'redemptions';

  @visibleForTesting
  static FirebaseFirestore Function()? firestoreOverride;

  static String normalize(String code) =>
      code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  /// Pure check of a code document; used by [redeem] and by tests.
  static PromoRejection? evaluate(
    Map<String, dynamic>? data, {
    required DateTime now,
    required bool alreadyUsed,
  }) {
    if (data == null) return PromoRejection.notFound;
    if (data['active'] == false) return PromoRejection.inactive;
    final tokens = (data['tokens'] as num?)?.toInt() ?? 0;
    if (tokens <= 0) return PromoRejection.inactive;
    final expiresAt = data['expiresAt'];
    if (expiresAt is Timestamp && !now.isBefore(expiresAt.toDate())) {
      return PromoRejection.expired;
    }
    if (alreadyUsed) return PromoRejection.alreadyUsed;
    final remaining = (data['remainingUses'] as num?)?.toInt() ?? 0;
    if (remaining <= 0) return PromoRejection.exhausted;
    return null;
  }

  static String messageFor(PromoRejection r) => switch (r) {
        PromoRejection.notFound => 'This code is not valid.',
        PromoRejection.inactive => 'This code is no longer active.',
        PromoRejection.expired => 'This code has expired.',
        PromoRejection.exhausted => 'This code has reached its usage limit.',
        PromoRejection.alreadyUsed =>
          'You have already redeemed this code on this device.',
      };

  static Future<PromoRedeemResult> redeem(String rawCode) async {
    final code = normalize(rawCode);
    if (code.isEmpty || code.length > 64 || code.contains('/')) {
      return PromoRedeemResult(
        success: false,
        message: messageFor(PromoRejection.notFound),
      );
    }
    if (firestoreOverride == null && Firebase.apps.isEmpty) {
      return const PromoRedeemResult(
        success: false,
        message: 'Promo codes are not available right now.',
      );
    }
    final deviceId = await TrialGuardService.deviceId();
    if (deviceId == null || deviceId.isEmpty) {
      return const PromoRedeemResult(
        success: false,
        message: 'Could not verify this device. Please try again.',
      );
    }

    final db = firestoreOverride?.call() ?? FirebaseFirestore.instance;
    final codeRef = db.collection(collection).doc(code);
    final useRef = codeRef.collection(redemptionsSub).doc(deviceId);

    try {
      final tokens = await db.runTransaction<int>((tx) async {
        final codeSnap = await tx.get(codeRef);
        final useSnap = await tx.get(useRef);
        final data = codeSnap.data();
        final rejection = evaluate(
          data,
          now: DateTime.now(),
          alreadyUsed: useSnap.exists,
        );
        if (rejection != null) throw _Rejected(rejection);
        tx.update(codeRef, {
          'remainingUses': FieldValue.increment(-1),
          // Lets the rules tie this decrement to the redemption doc below.
          'lastRedeemedBy': deviceId,
        });
        tx.set(useRef, {
          'redeemedAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        });
        return (data!['tokens'] as num).toInt();
      });
      await TokenService.addTokens(tokens.toDouble());
      return PromoRedeemResult(
        success: true,
        message: 'Code redeemed: +$tokens tokens.',
        tokensGranted: tokens,
      );
    } on _Rejected catch (e) {
      return PromoRedeemResult(success: false, message: messageFor(e.reason));
    } on FirebaseException catch (e) {
      debugPrint('Promo redeem failed: ${e.code}');
      // The rules deny reads of codes that do not exist as well as writes
      // that break a limit; both read as an invalid code to the user.
      return PromoRedeemResult(
        success: false,
        message: e.code == 'permission-denied'
            ? messageFor(PromoRejection.notFound)
            : 'Could not redeem the code. Please check your connection.',
      );
    }
  }
}

class _Rejected implements Exception {
  final PromoRejection reason;
  const _Rejected(this.reason);
}
