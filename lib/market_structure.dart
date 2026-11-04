class MarketStructure {
  final String structure;
  final String trend;
  final bool bos;
  final bool choch;

  const MarketStructure({
    required this.structure,
    required this.trend,
    required this.bos,
    required this.choch,
  });
}

MarketStructure analyzeMarketStructure(
  List<Map<String, dynamic>> candles,
) {
  const neutral = MarketStructure(
    structure: 'NONE',
    trend: 'NEUTRAL',
    bos: false,
    choch: false,
  );

  if (candles.length < 7) return neutral;

  // Candles must be ordered newest first.
  final bars = <Map<String, double>>[];

  for (final candle in candles) {
    final high = double.tryParse(candle['high']?.toString() ?? '');
    final low = double.tryParse(candle['low']?.toString() ?? '');
    final close = double.tryParse(candle['close']?.toString() ?? '');

    if (high == null || low == null || close == null) continue;
    if (high < low || close < low || close > high) continue;

    bars.add({
      'high': high,
      'low': low,
      'close': close,
    });
  }

  if (bars.length < 7) return neutral;

  // Reserve the latest two candles for BOS / CHOCH confirmation.
  final hasConfirmationCandles = bars.length >= 9;

  final structureBars = hasConfirmationCandles
      ? bars.sublist(2)
      : bars;

  final swingHighs = <double>[];
  final swingLows = <double>[];

  // Detect confirmed swings from older to newer candles.
  for (int i = structureBars.length - 2; i >= 1; i--) {
    final high = structureBars[i]['high']!;
    final low = structureBars[i]['low']!;

    if (high > structureBars[i - 1]['high']! &&
        high > structureBars[i + 1]['high']!) {
      swingHighs.add(high);
    }

    if (low < structureBars[i - 1]['low']! &&
        low < structureBars[i + 1]['low']!) {
      swingLows.add(low);
    }
  }

  if (swingHighs.length < 2 || swingLows.length < 2) {
    return neutral;
  }

  final previousHigh = swingHighs[swingHighs.length - 2];
  final latestHigh = swingHighs.last;
  final previousLow = swingLows[swingLows.length - 2];
  final latestLow = swingLows.last;

  String structure = 'NONE';
  String trend = 'NEUTRAL';

  if (latestHigh > previousHigh && latestLow > previousLow) {
    structure = 'HH / HL';
    trend = 'BULLISH';
  } else if (latestHigh < previousHigh && latestLow < previousLow) {
    structure = 'LH / LL';
    trend = 'BEARISH';
  }

  bool twoClosesBeyond(double level, bool above) {
    if (!hasConfirmationCandles) return false;

    final latestClose = bars[0]['close']!;
    final previousClose = bars[1]['close']!;

    if (above) {
      return previousClose > level && latestClose > level;
    }

    return previousClose < level && latestClose < level;
  }

  bool bos = false;
  bool choch = false;

  if (trend == 'BULLISH') {
    bos = twoClosesBeyond(latestHigh, true);
    choch = twoClosesBeyond(latestLow, false);
  } else if (trend == 'BEARISH') {
    bos = twoClosesBeyond(latestLow, false);
    choch = twoClosesBeyond(latestHigh, true);
  }

  return MarketStructure(
    structure: structure,
    trend: trend,
    bos: bos,
    choch: choch,
  );
}
