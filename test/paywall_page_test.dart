import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spooky_ai/core/services/purchase_provider.dart';
import 'package:spooky_ai/core/services/token_provider.dart';
import 'package:spooky_ai/features/home/presentation/widgets/paywall_dialog.dart';

void main() {
  for (final size in const [Size(375, 667), Size(430, 932)]) {
    testWidgets('paywall page lays out at $size', (tester) async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => PurchaseProvider()),
            ChangeNotifierProvider(create: (_) => TokenProvider()),
          ],
          child: const MaterialApp(home: PaywallDialog()),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('Bring your ideas to life'), findsOneWidget);
      expect(find.text('Restore purchases'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
