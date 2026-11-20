import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spooky_ai/core/services/token_service.dart';
import 'package:spooky_ai/core/services/trial_guard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late int claims;

  void setUpInstall({
    TrialDecision decision = TrialDecision.granted,
    Map<String, String> keychain = const {},
    Map<String, Object> prefs = const {},
  }) {
    SharedPreferences.setMockInitialValues({...prefs});
    FlutterSecureStorage.setMockInitialValues({...keychain});
    claims = 0;
    TrialGuardService.claimOverride = () async {
      claims++;
      return decision;
    };
    resetTokenServiceForTest();
  }

  tearDown(() => TrialGuardService.claimOverride = null);

  test('a new device starts with 3 tokens', () async {
    setUpInstall();
    expect(await TokenService.getBalance(), 3);
    expect(claims, 1);
  });

  test('reinstall on a device that already claimed starts with 0', () async {
    setUpInstall(decision: TrialDecision.alreadyUsed);
    expect(await TokenService.getBalance(), 0);
  });

  test(
    'keychain flag (iOS reinstall) blocks the gift without a call',
    () async {
      setUpInstall(keychain: {'trial_granted_once_v2': 'yes'});
      expect(await TokenService.getBalance(), 0);
      expect(claims, 0);
    },
  );

  test('offline first launch grants and records the claim later', () async {
    setUpInstall(decision: TrialDecision.unknown);
    expect(await TokenService.getBalance(), 3);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('trial_claim_pending_v1'), isTrue);

    // Next launch, now online.
    TrialGuardService.claimOverride = () async {
      claims++;
      return TrialDecision.granted;
    };
    resetTokenServiceForTest();
    expect(await TokenService.getBalance(), 3); // balance untouched
    await Future<void>.delayed(Duration.zero);
    expect(claims, 2);
    expect(prefs.getBool('trial_claim_pending_v1'), isNull);
  });

  test('concurrent first reads claim only once', () async {
    setUpInstall();
    final r = await Future.wait([
      TokenService.getBalance(),
      TokenService.getBalance(),
      TokenService.getBalance(),
    ]);
    expect(r, [3, 3, 3]);
    expect(claims, 1);
  });

  test('existing users keep their balance', () async {
    setUpInstall(
      prefs: {
        'user_tokens_initialized_v2': true,
        'user_tokens_v2': 12.0,
        'debug_balance_reset_v1': true,
      },
    );
    expect(await TokenService.getBalance(), 12);
    expect(claims, 0);
  });
}
