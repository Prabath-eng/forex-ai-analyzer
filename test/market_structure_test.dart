import 'package:flutter_test/flutter_test.dart';
import 'package:forex_ai_analyzer/market_structure.dart';

void main() {
  test('Insufficient candles return neutral', () {
    final result = analyzeMarketStructure([
      {'high': 10, 'low': 5, 'close': 8},
      {'high': 11, 'low': 6, 'close': 9},
      {'high': 12, 'low': 7, 'close': 10},
    ]);

    expect(result.structure, 'NONE');
    expect(result.trend, 'NEUTRAL');
    expect(result.bos, false);
    expect(result.choch, false);
  });

  test('Detects bullish market structure', () {
    final candles = [
      {'high': 10.0, 'low': 5.0, 'close': 8.0},
      {'high': 9.0, 'low': 4.0, 'close': 5.0},
      {'high': 12.0, 'low': 6.0, 'close': 11.0},
      {'high': 11.0, 'low': 5.0, 'close': 6.0},
      {'high': 14.0, 'low': 7.0, 'close': 13.0},
      {'high': 13.0, 'low': 6.0, 'close': 7.0},
      {'high': 15.0, 'low': 8.0, 'close': 14.0},
    ];

    final result = analyzeMarketStructure(candles.reversed.toList());

    expect(result.structure, 'HH / HL');
    expect(result.trend, 'BULLISH');
  });

  test('Checks bullish BOS detection', () {
    final candles = [
      {'high': 10.0, 'low': 5.0, 'close': 8.0},
      {'high': 9.0, 'low': 4.0, 'close': 5.0},
      {'high': 12.0, 'low': 6.0, 'close': 11.0},
      {'high': 11.0, 'low': 5.0, 'close': 6.0},
      {'high': 14.0, 'low': 7.0, 'close': 13.0},
      {'high': 13.0, 'low': 6.0, 'close': 7.0},
      {'high': 15.0, 'low': 8.0, 'close': 14.0},
    ];

    final result = analyzeMarketStructure(candles.reversed.toList());

    expect(result.trend, 'BULLISH');
    expect(result.bos, true);
  });

  test('Checks CHOCH detection', () {
    final candles = [
      {'high': 10.0, 'low': 5.0, 'close': 8.0},
      {'high': 9.0, 'low': 4.0, 'close': 5.0},
      {'high': 12.0, 'low': 6.0, 'close': 11.0},
      {'high': 11.0, 'low': 5.0, 'close': 6.0},
      {'high': 14.0, 'low': 7.0, 'close': 13.0},
      {'high': 13.0, 'low': 6.0, 'close': 7.0},
      {'high': 6.0, 'low': 3.0, 'close': 3.5},
    ];

    final result = analyzeMarketStructure(candles.reversed.toList());

    expect(result.choch, true);
  });
}
