class AtrCalculator {
  final int period;
  final double stopLossMultiplier;
  final double riskRewardRatio;

  const AtrCalculator({
    this.period = 14,
    this.stopLossMultiplier = 1.5,
    this.riskRewardRatio = 2.0,
  }) : assert(period > 0),
       assert(stopLossMultiplier > 0),
       assert(riskRewardRatio > 0);

  double? calculate(List<Map<String, dynamic>> candles) {
    if (candles.length < period + 1) return null;

    double number(Map<String, dynamic> candle, String key) {
      return double.tryParse(candle[key]?.toString() ?? '') ?? double.nan;
    }

    final ranges = <double>[];

    for (int i = 0; i < period; i++) {
      final current = candles[i];
      final previous = candles[i + 1];

      final high = number(current, 'high');
      final low = number(current, 'low');
      final previousClose = number(previous, 'close');

      if (!high.isFinite ||
          !low.isFinite ||
          !previousClose.isFinite ||
          high <= 0 ||
          low <= 0 ||
          previousClose <= 0 ||
          high < low) {
        return null;
      }

      final range = [
        high - low,
        (high - previousClose).abs(),
        (low - previousClose).abs(),
      ].reduce((a, b) => a > b ? a : b);

      ranges.add(range);
    }

    return ranges.reduce((a, b) => a + b) / period;
  }

  Map<String, double>? calculateRisk({
    required String direction,
    required double entryPrice,
    required double atr,
  }) {
    if (entryPrice <= 0 || atr <= 0 ||
        !entryPrice.isFinite || !atr.isFinite) {
      return null;
    }

    final distance = atr * stopLossMultiplier;
    final isBuy = direction.toUpperCase() == 'BUY';

    if (!isBuy && direction.toUpperCase() != 'SELL') return null;

    final stopLoss = isBuy
        ? entryPrice - distance
        : entryPrice + distance;

    final takeProfit = isBuy
        ? entryPrice + distance * riskRewardRatio
        : entryPrice - distance * riskRewardRatio;

    if (stopLoss <= 0 || takeProfit <= 0) return null;

    return {
      'stopLoss': stopLoss,
      'takeProfit': takeProfit,
    };
  }
}
