import 'package:flutter/material.dart';
import '../../../../core/theme/seasons/season_palette.dart';

class PurchaseFailedDialog extends StatelessWidget {
  const PurchaseFailedDialog({super.key, required this.reason});

  final String reason;

  static Future<void> show(BuildContext context, {required String reason}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PurchaseFailedDialog(reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: SeasonPalette.inputFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 40,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'Purchase Failed',
              style: TextStyle(
                color: SeasonPalette.text,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Reason
            Text(
              reason,
              style: TextStyle(
                color: SeasonPalette.mutedText,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: SeasonPalette.accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
