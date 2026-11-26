import 'package:flutter_test/flutter_test.dart';
import 'package:forex_ai_analyzer/backtesting_engine.dart';

void main() {
  test('flat market returns zero performance metrics', () {
    final candles = List.generate(
      20,
      (i) => {
        'datetime':
            '2026-01-01T${(i ~/ 4).toString().padLeft(2, '0')}:${((i % 4) * 15).toString().padLeft(2, '0')}:00',
        'open': 100.0,
        'high': 101.0,
        'low': 99.0,
        'close': 100.0,
      },
    );

    final result = BacktestingEngine().run(asset: 'XAU/USD', candles: candles);

    expect(result.totalTrades, 0);
    expect(result.wins, 0);
    expect(result.losses, 0);
    expect(result.winRate, 0);
    expect(result.netProfitPercent, 0);
    expect(result.maxDrawdownPercent, 0);
    expect(result.profitFactor, 0);
    expect(result.equityCurvePercent, [0.0]);
  });
}
