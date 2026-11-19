/// Single source of truth for what each generation costs, in tokens.
///
/// Costs are based on a 10-token pack priced at $1.79, with a conservative
/// 30% store fee and a target of at least 50% margin after API costs.
class TokenCosts {
  TokenCosts._();

  static const double textToImage = 1.0;
  static const double imageToImage = 2.0;
  static const double imageToVideo = 4.0;

  /// Whole-number label for UI copy: "1 token", "3 tokens".
  static String label(double cost) {
    final n = cost == cost.roundToDouble()
        ? cost.toInt().toString()
        : cost.toString();
    return '$n token${cost == 1 ? '' : 's'}';
  }
}
