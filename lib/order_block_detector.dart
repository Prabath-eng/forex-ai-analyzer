class OrderBlock {
  final String direction;
  final double top;
  final double bottom;
  final bool filled;
  final bool confirmed;

  const OrderBlock({
    required this.direction,
    required this.top,
    required this.bottom,
    required this.filled,
    required this.confirmed,
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
    double referenceLevel = direction == 'BULLISH' ? 0 : double.infinity;

    final end = orderBlockIndex + 5 < bars.length
        ? orderBlockIndex + 5
        : bars.length - 1;

    if (end <= orderBlockIndex) continue;

    for (int k = orderBlockIndex + 1; k <= end; k++) {
      if (direction == 'BULLISH') {
        if (bars[k]['high']! > referenceLevel) {
          referenceLevel = bars[k]['high']!;
        }
      } else {
        if (bars[k]['low']! < referenceLevel) {
          referenceLevel = bars[k]['low']!;
        }
      }
    }

    final confirmed = direction == 'BULLISH'
        ? impulse['close']! > referenceLevel
        : impulse['close']! < referenceLevel;

    if (!confirmed) continue;

    final top = obCandle['high']!;
    final bottom = obCandle['low']!;

    bool filled = false;

    for (int m = 0; m < orderBlockIndex; m++) {
      if (m == i) continue;
      if (direction == 'BULLISH' && bars[m]['low']! <= bottom) {
        filled = true;
        break;
      }

      if (direction == 'BEARISH' && bars[m]['high']! >= top) {
        filled = true;
        break;
      }
    }

    blocks.add(
      OrderBlock(
        direction: direction,
        top: top,
        bottom: bottom,
        filled: filled,
        confirmed: true,
      ),
    );
  }

  return blocks;
}
