import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_service.dart';
import 'trial_guard_service.dart';
import 'version_service.dart';

/// What this device has done with ratings so far. Kept in the keychain /
/// keystore so it survives reinstalls on iOS.
class RatingHistory {
  const RatingHistory({
    this.totalRatings = 0,
    this.lowRatings = 0,
    this.apologiesGranted = 0,
    this.lastApologyAt,
    this.ratingsSinceApology = 0,
  });

  final int totalRatings;
  final int lowRatings;
  final int apologiesGranted;
  final DateTime? lastApologyAt;

  /// Ratings submitted after the last apology token.
  final int ratingsSinceApology;

  RatingHistory record({
    required bool low,
    required bool apology,
    required DateTime now,
  }) => RatingHistory(
    totalRatings: totalRatings + 1,
    lowRatings: lowRatings + (low ? 1 : 0),
    apologiesGranted: apologiesGranted + (apology ? 1 : 0),
    lastApologyAt: apology ? now : lastApologyAt,
    ratingsSinceApology: apology ? 0 : ratingsSinceApology + 1,
  );

  Map<String, Object?> toJson() => {
    't': totalRatings,
    'l': lowRatings,
    'a': apologiesGranted,
    'at': lastApologyAt?.millisecondsSinceEpoch,
    's': ratingsSinceApology,
  };

  factory RatingHistory.fromJson(Map<String, dynamic> j) => RatingHistory(
    totalRatings: (j['t'] as num?)?.toInt() ?? 0,
    lowRatings: (j['l'] as num?)?.toInt() ?? 0,
    apologiesGranted: (j['a'] as num?)?.toInt() ?? 0,
    lastApologyAt: j['at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch((j['at'] as num).toInt()),
    ratingsSinceApology: (j['s'] as num?)?.toInt() ?? 0,
  );
}

/// Decides whether a low rating earns a 1-token apology.
///
/// - The first 1–2 star rating on a device always gets one.
/// - After that it is rare: at most [maxApologies] in total, at least
///   [cooldown] and [minRatingsBetween] ratings since the last one, only
///   while the device does not rate almost everything low, and then only
///   with [repeatChance] probability.
class RatingRewardPolicy {
  static const int lowThreshold = 2;
  static const int maxApologies = 3;
  static const Duration cooldown = Duration(days: 14);
  static const int minRatingsBetween = 5;
  static const double maxLowShare = 0.6;
  static const double repeatChance = 0.25;

  static bool isLow(int stars) => stars <= lowThreshold;

  /// [roll] is a uniform random number in [0, 1).
  static bool grantsApology(
    RatingHistory h,
    int stars, {
    required DateTime now,
    required double roll,
  }) {
    if (!isLow(stars)) return false;
    if (h.apologiesGranted == 0) return true;
    if (h.apologiesGranted >= maxApologies) return false;
    final last = h.lastApologyAt;
    if (last != null && now.difference(last) < cooldown) return false;
    if (h.ratingsSinceApology < minRatingsBetween) return false;
    final total = h.totalRatings + 1;
    final low = h.lowRatings + 1;
    if (low / total > maxLowShare) return false;
    return roll < repeatChance;
  }
}

/// Sends star ratings for generated images to Firestore (`image_ratings`)
/// together with the prompt, and pays out the apology token.
class RatingService {
  RatingService._();

  static const _secure = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _kHistory = 'image_rating_history_v1';

  /// One document per prompt (`prompts/{promptKey}`) with running totals,
  /// and every rating for it in `prompts/{promptKey}/ratings`.
  static const collection = 'prompts';
  static const ratingsSub = 'ratings';

  /// Library styles use their id; free-text prompts use a stable hash of
  /// the text so the same prompt always lands in the same document.
  @visibleForTesting
  static String promptKey({String? styleId, required String prompt}) {
    final id = styleId?.trim() ?? '';
    if (id.isNotEmpty) {
      final safe = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      return 'style_$safe';
    }
    // FNV-1a 64-bit over the normalised text.
    var h = BigInt.parse('cbf29ce484222325', radix: 16);
    final prime = BigInt.parse('100000001b3', radix: 16);
    final mask = (BigInt.one << 64) - BigInt.one;
    for (final b in utf8.encode(prompt.trim().toLowerCase())) {
      h = ((h ^ BigInt.from(b)) * prime) & mask;
    }
    return 'custom_${h.toRadixString(16).padLeft(16, '0')}';
  }

  static final Random _random = Random();

  static Future<RatingHistory> _load() async {
    try {
      final raw = await _secure.read(key: _kHistory);
      if (raw == null) return const RatingHistory();
      return RatingHistory.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const RatingHistory();
    }
  }

  static Future<void> _save(RatingHistory h) async {
    try {
      await _secure.write(key: _kHistory, value: jsonEncode(h.toJson()));
    } catch (_) {}
  }

  /// Returns true when an apology token was added to the balance.
  static Future<bool> submit({
    required int stars,
    required String prompt,
    required String mode,
    String? styleId,
    String? styleTitle,
  }) async {
    assert(stars >= 1 && stars <= 5);
    final now = DateTime.now();
    final history = await _load();
    final apology = RatingRewardPolicy.grantsApology(
      history,
      stars,
      now: now,
      roll: _random.nextDouble(),
    );
    // Save first so a crash or quick retry can never pay twice.
    await _save(
      history.record(
        low: RatingRewardPolicy.isLow(stars),
        apology: apology,
        now: now,
      ),
    );
    if (apology) await TokenService.addTokens(1);

    await _upload(
      stars: stars,
      prompt: prompt,
      mode: mode,
      styleId: styleId,
      styleTitle: styleTitle,
      apology: apology,
    );
    return apology;
  }

  static Future<void> _upload({
    required int stars,
    required String prompt,
    required String mode,
    required bool apology,
    String? styleId,
    String? styleTitle,
  }) async {
    if (Firebase.apps.isEmpty) return;
    try {
      final version = await VersionService.getVersionInfo();
      final db = FirebaseFirestore.instance;
      final text = prompt.length > 4000 ? prompt.substring(0, 4000) : prompt;
      final promptRef = db
          .collection(collection)
          .doc(promptKey(styleId: styleId, prompt: prompt));
      final deviceId = await TrialGuardService.deviceId();
      // A transaction so the average is always starsTotal / ratingCount,
      // even when two people rate the same prompt at once.
      await db.runTransaction((tx) async {
        final snap = await tx.get(promptRef);
        final old = snap.data() ?? const <String, dynamic>{};
        final count = ((old['ratingCount'] as num?)?.toInt() ?? 0) + 1;
        final total = ((old['starsTotal'] as num?)?.toInt() ?? 0) + stars;
        tx.set(promptRef.collection(ratingsSub).doc(), {
          'stars': stars,
          'prompt': text,
          'mode': mode,
          'styleId': styleId,
          'styleTitle': styleTitle,
          'apologyToken': apology,
          'deviceId': deviceId,
          'platform': defaultTargetPlatform.name,
          'appVersion': version['fullVersion'],
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.set(promptRef, {
          'prompt': text,
          'styleId': styleId,
          'styleTitle': styleTitle,
          'ratingCount': count,
          'starsTotal': total,
          'averageRating': total / count,
          'stars$stars': ((old['stars$stars'] as num?)?.toInt() ?? 0) + 1,
          'lastRatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Rating upload failed: $e');
    }
  }
}
