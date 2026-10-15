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

  // Candles are ordered newest first.
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
      swingHighs.add({
        'level': high,
        'index': i.toDouble(),
      });
    }

    if (low < bars[i - 1]['low']! &&
        low < bars[i + 1]['low']!) {
      swingLows.add({
        'level': low,
        'index': i.toDouble(),
      });
    }
  }

  if (swingHighs.length < 2 || swingLows.length < 2) {
    return neutral;
  }

  final previousHigh = swingHighs[swingHighs.length - 2];
  final latestHigh = swingHighs.last;
  final previousLow = swingLows[swingLows.length - 2];
  final latestLow = swingLows.last;

  final oldHigh = previousHigh['level']!;
  final newHigh = latestHigh['level']!;
  final oldLow = previousLow['level']!;
  final newLow = latestLow['level']!;

  String structure = 'NONE';
  String trend = 'NEUTRAL';

  if (newHigh > oldHigh && newLow > oldLow) {
    structure = 'HH / HL';
    trend = 'BULLISH';
  } else if (newHigh < oldHigh && newLow < oldLow) {
    structure = 'LH / LL';
    trend = 'BEARISH';
  }

  bool wasBrokenAfter(Map<String, double> swing, String field) {
    final pivotIndex = swing['index']!.toInt();
    final level = swing['level']!;

    // Search candles newer than this swing point.
    for (int i = pivotIndex - 1; i >= 0; i--) {
      if (field == 'high' && bars[i]['close']! > level) {
        return true;
      }
      if (field == 'low' && bars[i]['close']! < level) {
        return true;
      }
    }
    return false;
  }

  final bullishBreak = wasBrokenAfter(previousHigh, 'high');
  final bearishBreak = wasBrokenAfter(previousLow, 'low');

  final bos = (trend == 'BULLISH' && bullishBreak) ||
      (trend == 'BEARISH' && bearishBreak);

  // Do not claim CHOCH without a known prior structure direction.
  final choch = (trend == 'BULLISH' && bearishBreak) ||
      (trend == 'BEARISH' && bullishBreak);

  return MarketStructure(
    structure: structure,
    trend: trend,
    bos: bos,
    choch: choch,
  );
}
