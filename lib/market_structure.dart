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

                                                                                                        return const MarketStructure(
                                                                                                            structure: "NONE",
                                                                                                                trend: "NEUTRAL",
                                                                                                                    bos: false,
                                                                                                                        choch: false,
                                                                                                                          );
                                                                                                                          }