import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'paywall_dialog.dart';

/// Shown when the token balance drops below the cost of a generation.
///
/// Opens the token packs screen with an "out of tokens" header, so the
/// user can pick and buy a pack in one step.
class LowBalanceDialog {
  LowBalanceDialog._();

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return PaywallDialog.show(context, outOfTokens: true);
  }
}
