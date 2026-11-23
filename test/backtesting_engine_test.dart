import 'package:flutter_test/flutter_test.dart';

import 'package:forex_ai_analyzer/backtesting_engine.dart';

void main() {
  test('empty candles returns zero trades', () {
    final engine = BacktestingEngine();
    final result = engine.run(asset: 'XAU/USD', candles: []);
    expect(result.totalTrades, 0);
    expect(result.wins, 0);
    expect(result.losses, 0);
  });
  test('insufficient candles return zero trades', () {
    final result = BacktestingEngine().run(
      asset: 'XAU/USD',
      candles: List.generate(
        5,
        (i) => {
          'datetime': '2026-01-01T00:0$i:00',
          'open': 100.0,
          'high': 101.0,
          'low': 99.0,
          'close': 100.0,
        },
      ),
    );
    expect(result.totalTrades, 0);
  });

  test('BacktestTrade defaults to percentage fallback', () {
    final trade = BacktestTrade(
      direction: 'BUY',
      signalTime: '2026-01-01T00:00:00',
      entryTime: '2026-01-01T00:15:00',
      entryPrice: 100.0,
      stopLoss: 99.0,
      takeProfit: 102.0,
    );

    expect(trade.riskCalculationMethod, 'PERCENTAGE FALLBACK');
  });

  test('BacktestTrade records ATR-based risk method', () {
    final trade = BacktestTrade(
      direction: 'BUY',
      signalTime: '2026-01-01T00:00:00',
      entryTime: '2026-01-01T00:15:00',
      entryPrice: 100.0,
      stopLoss: 98.0,
      takeProfit: 104.0,
      riskCalculationMethod: 'ATR-BASED',
    );

    expect(trade.riskCalculationMethod, 'ATR-BASED');
  });
}
