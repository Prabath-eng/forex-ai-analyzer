import 'package:flutter_test/flutter_test.dart';

import 'package:forex_ai_analyzer/atr_calculator.dart';

void main() {
  group('ATR Calculator', () {
    final calculator = AtrCalculator();

    test('calculates ATR from newest-first candles', () {
      final candles = List.generate(
        15,
        (i) => {'high': 105.0, 'low': 100.0, 'close': 102.0},
      );
      expect(calculator.calculate(candles), 5.0);
    });

    test('calculates BUY stop loss and take profit', () {
      final risk = calculator.calculateRisk(
        direction: 'BUY',
        entryPrice: 100,
        atr: 2,
      );
      expect(risk!['stopLoss'], 97);
      expect(risk['takeProfit'], 106);
    });

    test('calculates SELL stop loss and take profit', () {
      final risk = calculator.calculateRisk(
        direction: 'SELL',
        entryPrice: 100,
        atr: 2,
      );
      expect(risk!['stopLoss'], 103);
      expect(risk['takeProfit'], 94);
    });
  });

  group('ATR validation', () {
    final calculator = AtrCalculator();

    test('returns null when candles are insufficient', () {
      expect(
        calculator.calculate(
          List.generate(
            10,
            (i) => {'high': 105.0, 'low': 100.0, 'close': 102.0},
          ),
        ),
        isNull,
      );
    });

    test('returns null for invalid OHLC data', () {
      final candles = List.generate(
        15,
        (i) => {'high': 105.0, 'low': 100.0, 'close': 102.0},
      );
      candles[0]['high'] = double.nan;
      expect(calculator.calculate(candles), isNull);
    });

    test('returns null when high is below low', () {
      final candles = List.generate(
        15,
        (i) => {'high': 99.0, 'low': 100.0, 'close': 102.0},
      );
      expect(calculator.calculate(candles), isNull);
    });

    test('rejects invalid entry price', () {
      expect(
        calculator.calculateRisk(direction: 'BUY', entryPrice: 0, atr: 2),
        isNull,
      );
    });

    test('rejects invalid direction', () {
      expect(
        calculator.calculateRisk(direction: 'HOLD', entryPrice: 100, atr: 2),
        isNull,
      );
    });
  });
}
