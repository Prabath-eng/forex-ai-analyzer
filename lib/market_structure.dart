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

  final swingHighs = <Map<String, double>>[];
  final swingLows = <Map<String, double>>[];

  // Confirmed swing points, ordered from older to newer.
  for (int i = bars.length - 2; i >= 1; i--) {
    final high = bars[i]['high']!;
    final low = bars[i]['low']!;

    if (high > bars[i - 1]['high']! &&
        high > bars[i + 1]['high']!) {
      swingHighs.add({'level': high, 'index': i.toDouble()});
    }

    if (low < bars[i - 1]['low']! &&
        low < bars[i + 1]['low']!) {
      swingLows.add({'level': low, 'index': i.toDouble()});
    }
  }

  if (swingHighs.length < 2 || swingLows.length < 2) {
    return neutral;
  }

  final previousHigh = swingHighs[swingHighs.length - 2]['level']!;
  final latestHigh = swingHighs.last['level']!;
  final previousLow = swingLows[swingLows.length - 2]['level']!;
  final latestLow = swingLows.last['level']!;

  String structure = 'NONE';
  String trend = 'NEUTRAL';

  if (latestHigh > previousHigh && latestLow > previousLow) {
    structure = 'HH / HL';
    trend = 'BULLISH';
  } else if (latestHigh < previousHigh && latestLow < previousLow) {
    structure = 'LH / LL';
    trend = 'BEARISH';
  }

  // Check two consecutive closes occurring AFTER the swing candle.
  // bars are newest first, so smaller indices are newer candles.
  bool twoClosesBeyond(
    Map<String, double> swing,
    bool above,
  ) {
    final pivotIndex = swing['index']!.toInt();

    // The latest two candles must both be newer than the swing.
    if (pivotIndex < 2) return false;

    final latestClose = bars[0]['close']!;
    final previousClose = bars[1]['close']!;
    final level = swing['level']!;

    if (above) {
      return previousClose > level && latestClose > level;
    }

    return previousClose < level && latestClose < level;
  }

  bool bos = false;
  bool choch = false;

  if (trend == 'BULLISH') {
    bos = twoClosesBeyond(swingHighs.last, true);
    choch = twoClosesBeyond(swingLows.last, false);
  } else if (trend == 'BEARISH') {
    bos = twoClosesBeyond(swingLows.last, false);
    choch = twoClosesBeyond(swingHighs.last, true);
  }

  return MarketStructure(
    structure: structure,
    trend: trend,
    bos: bos,
    choch: choch,
  );
}
