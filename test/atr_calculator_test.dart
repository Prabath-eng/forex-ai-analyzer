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
}
