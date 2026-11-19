import 'package:flutter_test/flutter_test.dart';
import 'package:forex_ai_analyzer/backtesting_engine.dart';

void main() {
  test('bearish signal reaches take profit', () {
    final candles = [
      {'datetime': '2026-01-01T00:00', 'open': 13.0, 'high': 15.0, 'low': 10.0, 'close': 12.0},
      {'datetime': '2026-01-01T00:15', 'open': 12.0, 'high': 16.0, 'low': 11.0, 'close': 15.0},
      {'datetime': '2026-01-01T00:30', 'open': 14.0, 'high': 14.0, 'low': 8.0, 'close': 9.0},
      {'datetime': '2026-01-01T00:45', 'open': 9.0, 'high': 15.0, 'low': 9.0, 'close': 14.0},
      {'datetime': '2026-01-01T01:00', 'open': 13.0, 'high': 13.0, 'low': 6.0, 'close': 7.0},
      {'datetime': '2026-01-01T01:15', 'open': 7.0, 'high': 14.0, 'low': 7.0, 'close': 13.0},
      {'datetime': '2026-01-01T01:30', 'open': 12.0, 'high': 12.0, 'low': 5.0, 'close': 6.0},
      {'datetime': '2026-01-01T01:45', 'open': 7.0, 'high': 13.0, 'low': 6.0, 'close': 7.0},
      {'datetime': '2026-01-01T02:00', 'open': 5.0, 'high': 5.0, 'low': 3.0, 'close': 4.0},
      {'datetime': '2026-01-01T02:15', 'open': 4.5, 'high': 16.5, 'low': 2.0, 'close': 3.5},
      {'datetime': '2026-01-01T02:30', 'open': 3.5, 'high': 3.6, 'low': 3.0, 'close': 3.1},
      {'datetime': '2026-01-01T02:45', 'open': 3.5, 'high': 3.52, 'low': 3.4, 'close': 3.42},
    ];

    final engine = BacktestingEngine();
    final result = engine.run(asset: 'XAU/USD', candles: candles);

    expect(result.totalTrades, 1);
    expect(result.wins, 1);
    expect(result.losses, 0);
    expect(result.trades.first.direction, 'SELL');
    expect(result.trades.first.result, 'WIN');
  });
}
