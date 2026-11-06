import 'package:flutter_test/flutter_test.dart';
import 'package:forex_ai_analyzer/stateful_market_structure.dart';

void main() {
  group('Stateful Market Structure', () {
    test('resets only the selected asset state', () {
      final analyzer = StatefulMarketStructure();
      analyzer.update(asset: 'XAU/USD', candles: addTimes(bullishBars(), 0));
      analyzer.reset(asset: 'XAU/USD');
      final result = analyzer.update(
        asset: 'XAU/USD',
        candles: addTimes(bearishBars(), 0),
      );
      expect(result.trend, 'BEARISH');
    });

    test('ignores duplicate candle timestamps', () {
      final analyzer = StatefulMarketStructure();
      final first = analyzer.update(
        asset: 'XAU/USD',
        candles: addTimes(bullishBars(), 2),
      );
      final duplicate = analyzer.update(
        asset: 'XAU/USD',
        candles: addTimes(bearishBars(), 0),
      );
      expect(first.trend, 'BULLISH');
      expect(duplicate.trend, 'BULLISH');
    });

    test('keeps XAU and EUR states separate', () {
      final analyzer = StatefulMarketStructure();

      analyzer.update(asset: 'XAU/USD', candles: addTimes(bullishBars(), 0));

      final eur = analyzer.update(
        asset: 'EUR/USD',
        candles: addTimes(bearishBars(), 20),
      );

      expect(eur.trend, 'BEARISH');

      final xau = analyzer.update(
        asset: 'XAU/USD',
        candles: addTimes(bullishChochBars(), 30),
      );

      expect(xau.trend, 'BULLISH');
      expect(analyzer.pendingTrendFor('XAU/USD'), 'BEARISH');
      expect(analyzer.pendingTrendFor('EUR/USD'), isNull);
    });

    test('keeps bullish trend while bearish CHOCH is pending', () {
      final analyzer = StatefulMarketStructure();

      final first = analyzer.update(
        asset: 'XAU/USD',
        candles: addTimes(bullishBars(), 0),
      );

      expect(first.trend, 'BULLISH');

      final result = analyzer.update(
        asset: 'XAU/USD',
        candles: addTimes(bullishChochBars(), 10),
      );

      expect(result.trend, 'BULLISH');
      expect(result.choch, true);
      expect(analyzer.pendingTrendFor('XAU/USD'), 'BEARISH');
    });

    test('confirms bearish reversal after bearish structure', () {
      final analyzer = StatefulMarketStructure();
      analyzer.update(asset: 'XAU/USD', candles: addTimes(bullishBars(), 0));
      analyzer.update(
        asset: 'XAU/USD',
        candles: addTimes(bullishChochBars(), 10),
      );

      final result = analyzer.update(
        asset: 'XAU/USD',
        candles: addTimes(bearishBars(), 20),
      );

      expect(result.trend, 'BEARISH');
      expect(analyzer.pendingTrendFor('XAU/USD'), isNull);
    });
  });
}

List<Map<String, dynamic>> addTimes(
  List<Map<String, dynamic>> bars,
  int start,
) {
  return bars
      .asMap()
      .entries
      .map((entry) {
        final minute = start + entry.key;
        return {
          ...entry.value,
          'datetime': '2026-11-06T00:${minute.toString().padLeft(2, '0')}:00',
        };
      })
      .toList()
      .reversed
      .toList();
}

List<Map<String, dynamic>> bullishBars() {
  return [
    {'high': 10.0, 'low': 5.0, 'close': 8.0},
    {'high': 9.0, 'low': 4.0, 'close': 5.0},
    {'high': 12.0, 'low': 6.0, 'close': 11.0},
    {'high': 11.0, 'low': 5.0, 'close': 6.0},
    {'high': 14.0, 'low': 7.0, 'close': 13.0},
    {'high': 13.0, 'low': 6.0, 'close': 7.0},
    {'high': 15.0, 'low': 8.0, 'close': 14.0},
  ];
}

List<Map<String, dynamic>> bullishChochBars() {
  return [
    {'high': 10.0, 'low': 5.0, 'close': 8.0},
    {'high': 9.0, 'low': 4.0, 'close': 5.0},
    {'high': 12.0, 'low': 6.0, 'close': 11.0},
    {'high': 11.0, 'low': 5.0, 'close': 6.0},
    {'high': 14.0, 'low': 7.0, 'close': 13.0},
    {'high': 13.0, 'low': 6.0, 'close': 7.0},
    {'high': 15.0, 'low': 8.0, 'close': 14.0},
    {'high': 9.0, 'low': 2.0, 'close': 3.0},
    {'high': 8.0, 'low': 1.0, 'close': 2.0},
  ];
}

List<Map<String, dynamic>> bearishBars() {
  return [
    {'high': 15.0, 'low': 10.0, 'close': 12.0},
    {'high': 16.0, 'low': 11.0, 'close': 15.0},
    {'high': 14.0, 'low': 8.0, 'close': 9.0},
    {'high': 15.0, 'low': 9.0, 'close': 14.0},
    {'high': 13.0, 'low': 6.0, 'close': 7.0},
    {'high': 14.0, 'low': 7.0, 'close': 13.0},
    {'high': 12.0, 'low': 5.0, 'close': 6.0},
    {'high': 18.0, 'low': 11.0, 'close': 17.0},
    {'high': 19.0, 'low': 12.0, 'close': 18.0},
  ];
}
