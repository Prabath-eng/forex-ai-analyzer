
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
        if (candles.length < 5) {
            return const MarketStructure(
                  structure: "NONE",
                        trend: "NEUTRAL",
                              bos: false,
                                    choch: false,
                                        );
                                          }


  final highs = <double>[];
                                              final lows = <double>[];

                                                for (final candle in candles) {
                                                    final high = double.tryParse(candle["high"]?.toString() ?? "");
                                                        final low = double.tryParse(candle["low"]?.toString() ?? "");

                                                            if (high != null) highs.add(high);
                                                                if (low != null) lows.add(low);
                                                                  }

if (highs.length < 3 || lows.length < 3) {
  return const MarketStructure(
    structure: "NONE",
    trend: "NEUTRAL",
    bos: false,
    choch: false,
  );
}

  final recentHigh1 = highs[0];                                                                                               
  final recentHigh2 = highs[1];
  final recentLow1 = lows[0];
  final recentLow2 = lows[1];
bool bos = false;
bool choch = false;

final previousHigh = recentHigh2;
final previousLow = recentLow2;
  String structure = "NONE";
  String trend = "NEUTRAL";
  if (recentHigh1 > recentHigh2 && recentLow1 > recentLow2) {
    structure = "HH / HL";
    trend = "BULLISH";
  } else if (recentHigh1 < recentHigh2 && recentLow1 < recentLow2) {
    structure = "LH / LL";
    trend = "BEARISH";
  } else if (recentHigh1 > recentHigh2) {
    structure = "HH";
    trend = "BULLISH";
  } else if (recentLow1 > recentLow2) {
    structure = "HL";
    trend = "BULLISH";
  } else if (recentHigh1 < recentHigh2) {
    structure = "LH";
    trend = "BEARISH";
  } else if (recentLow1 < recentLow2) {
    structure = "LL";
    trend = "BEARISH";
  }
if (trend == "BULLISH" && recentHigh1 > previousHigh) {
  bos = true;
} else if (trend == "BEARISH" && recentLow1 < previousLow) {
  bos = true;
}
if (trend == "BULLISH" && recentLow1 < previousLow) {
  choch = true;
} else if (trend == "BEARISH" && recentHigh1 > previousHigh) {
  choch = true;
}
  return MarketStructure(
    structure: structure,
    trend: trend,
    bos: bos,
    choch: choch,
  );
                                                                                                        
                                                                                                                          }