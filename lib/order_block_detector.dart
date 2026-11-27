double? _findLatestSwingHigh(List<Map<String, double>> bars) {
  if (bars.length < 3) return null;
  for (int i = 1; i < bars.length - 1; i++) {
    final high = bars[i]["high"]!;
    if (high > bars[i - 1]["high"]! && high > bars[i + 1]["high"]!) {
      return high;
    }
  }
  return null;
}

double? _findLatestSwingLow(List<Map<String, double>> bars) {
  if (bars.length < 3) return null;
  for (int i = 1; i < bars.length - 1; i++) {
    final low = bars[i]["low"]!;
    if (low < bars[i - 1]["low"]! && low < bars[i + 1]["low"]!) {
      return low;
    }
  }
  return null;
}

class OrderBlock {
  final String direction;
  final double top;
  final double bottom;
  final bool filled;
  final bool confirmed;
  final bool mitigated;
  final bool invalidated;

  String get status {
    if (invalidated) return 'INVALIDATED';
    if (filled) return 'FILLED';
    if (mitigated) return 'MITIGATED';
    return 'FRESH';
  }

  const OrderBlock({
    required this.direction,
    required this.top,
    required this.bottom,
    required this.filled,
    required this.confirmed,
    this.mitigated = false,
    this.invalidated = false,
  });
}

List<OrderBlock> detectOrderBlocks(List<Map<String, dynamic>> candles) {
  final blocks = <OrderBlock>[];

  double? price(Map<String, dynamic> candle, String key) {
    return double.tryParse(candle[key]?.toString() ?? '');
  }

  final bars = <Map<String, double>>[];

  for (final candle in candles) {
    final open = price(candle, 'open');
    final high = price(candle, 'high');
    final low = price(candle, 'low');
    final close = price(candle, 'close');

    if (open == null || high == null || low == null || close == null) {
      continue;
    }

    if (high < low ||
        open < low ||
        open > high ||
        close < low ||
        close > high) {
      continue;
    }

    bars.add({'open': open, 'high': high, 'low': low, 'close': close});
  }

  if (bars.length < 9) return blocks;

  double bodySize(Map<String, double> candle) {
    return (candle['close']! - candle['open']!).abs();
  }

  for (int i = 0; i <= bars.length - 6; i++) {
    final impulse = bars[i];
    final impulseBody = bodySize(impulse);

    double averageBody = 0;
    for (int j = i + 1; j <= i + 5; j++) {
      averageBody += bodySize(bars[j]);
    }
    averageBody /= 5;

    if (averageBody == 0 || impulseBody < averageBody * 1.5) {
      continue;
    }

    final bullishImpulse = impulse['close']! > impulse['open']!;
    final bearishImpulse = impulse['close']! < impulse['open']!;

    if (!bullishImpulse && !bearishImpulse) {
      continue;
    }

    final direction = bullishImpulse ? 'BULLISH' : 'BEARISH';

    int? orderBlockIndex;

    for (int j = i + 1; j <= i + 5; j++) {
      final candle = bars[j];
      final isBearish = candle['close']! < candle['open']!;
      final isBullish = candle['close']! > candle['open']!;

      if (direction == 'BULLISH' && isBearish ||
          direction == 'BEARISH' && isBullish) {
        orderBlockIndex = j;
        break;
      }
    }

    if (orderBlockIndex == null) continue;

    final obCandle = bars[orderBlockIndex];

    // Use only candles older than the order block to find its swing level.
    final olderBars = bars.sublist(orderBlockIndex + 1);
    final swingLevel = direction == 'BULLISH'
        ? _findLatestSwingHigh(olderBars)
        : _findLatestSwingLow(olderBars);

    // Exclude bars[0], which may still be forming.
    if (i < 2 || swingLevel == null) continue;

    // Require two consecutive completed closes beyond the swing level.
    final confirmed = direction == 'BULLISH'
        ? bars[i]['close']! > swingLevel && bars[i - 1]['close']! > swingLevel
        : bars[i]['close']! < swingLevel && bars[i - 1]['close']! < swingLevel;

    if (!confirmed) continue;

    final top = obCandle['high']!;
    final bottom = obCandle['low']!;

    bool filled = false;
    bool mitigated = false;
    bool invalidated = false;

    for (int m = 0; m < orderBlockIndex; m++) {
      if (m == i) continue;

      final candle = bars[m];
      final high = candle['high']!;
      final low = candle['low']!;
      final close = candle['close']!;

      if (direction == 'BULLISH') {
        if (close < bottom) invalidated = true;
        if (high >= bottom && low <= top) mitigated = true;
        if (low <= bottom) filled = true;
      } else {
        if (close > top) invalidated = true;
        if (high >= bottom && low <= top) mitigated = true;
        if (high >= top) filled = true;
      }
    }

    blocks.add(
      OrderBlock(
        direction: direction,
        top: top,
        bottom: bottom,
        filled: filled,
        confirmed: true,
        mitigated: mitigated,
        invalidated: invalidated,
      ),
    );
  }

  return blocks;
}
