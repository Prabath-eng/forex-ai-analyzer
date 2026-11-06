class FairValueGap {
  final String direction;
  final double top;
  final double bottom;
  final double gapSize;
  final bool filled;

  const FairValueGap({
    required this.direction,
    required this.top,
    required this.bottom,
    required this.gapSize,
    required this.filled,
  });
}

List<FairValueGap> detectFairValueGaps(
  List<Map<String, dynamic>> candles,
) {
  final gaps = <FairValueGap>[];

  double? getPrice(Map<String, dynamic> candle, String key) {
    return double.tryParse(candle[key]?.toString() ?? '');
  }

  for (int i = 0; i <= candles.length - 3; i++) {
    final newer = candles[i];
    final middle = candles[i + 1];
    final older = candles[i + 2];

    final newerHigh = getPrice(newer, 'high');
    final newerLow = getPrice(newer, 'low');
    final middleHigh = getPrice(middle, 'high');
    final middleLow = getPrice(middle, 'low');
    final olderHigh = getPrice(older, 'high');
    final olderLow = getPrice(older, 'low');

    if (newerHigh == null ||
        newerLow == null ||
        middleHigh == null ||
        middleLow == null ||
        olderHigh == null ||
        olderLow == null) {
      continue;
    }

    if (newerHigh < newerLow ||
        middleHigh < middleLow ||
        olderHigh < olderLow) {
      continue;
    }

    // Bullish FVG
    if (newerLow > olderHigh) {
      final top = newerLow;
      final bottom = olderHigh;

      bool filled = false;

      for (int j = 0; j < i; j++) {
        final low = getPrice(candles[j], 'low');

        if (low != null && low <= bottom) {
          filled = true;
          break;
        }
      }

      gaps.add(FairValueGap(
        direction: 'BULLISH',
        top: top,
        bottom: bottom,
        gapSize: top - bottom,
        filled: filled,
      ));
    }

    // Bearish FVG
    else if (newerHigh < olderLow) {
      final top = olderLow;
      final bottom = newerHigh;

      bool filled = false;

      for (int j = 0; j < i; j++) {
        final high = getPrice(candles[j], 'high');

        if (high != null && high >= top) {
          filled = true;
          break;
        }
      }

      gaps.add(FairValueGap(
        direction: 'BEARISH',
        top: top,
        bottom: bottom,
        gapSize: top - bottom,
        filled: filled,
      ));
    }
  }

  return gaps;
}
