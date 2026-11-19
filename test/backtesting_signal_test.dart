import 'package:flutter_test/flutter_test.dart';
import 'package:forex_ai_analyzer/backtesting_engine.dart';

void main() {
  test('bullish signal reaches take profit', () {
    final candles = [
      {
        'datetime': '2026-01-01T00:00',
        'open': 7.0,
        'high': 10.0,
        'low': 5.0,
        'close': 8.0,
      },
      {
        'datetime': '2026-01-01T00:15',
        'open': 8.0,
        'high': 9.0,
        'low': 4.0,
        'close': 5.0,
      },
      {
        'datetime': '2026-01-01T00:30',
        'open': 6.0,
        'high': 12.0,
        'low': 6.0,
        'close': 11.0,
      },
      {
        'datetime': '2026-01-01T00:45',
        'open': 11.0,
        'high': 11.0,
        'low': 5.0,
        'close': 6.0,
      },
      {
        'datetime': '2026-01-01T01:00',
        'open': 7.0,
        'high': 14.0,
        'low': 7.0,
        'close': 13.0,
      },
      {
        'datetime': '2026-01-01T01:15',
        'open': 13.0,
        'high': 13.0,
        'low': 6.0,
        'close': 7.0,
      },
      {
        'datetime': '2026-01-01T01:30',
        'open': 8.0,
        'high': 15.0,
        'low': 8.0,
        'close': 14.0,
      },
      {
        'datetime': '2026-01-01T01:45',
        'open': 13.0,
        'high': 14.0,
        'low': 7.0,
        'close': 13.0,
      },
      {
        'datetime': '2026-01-01T02:00',
        'open': 15.0,
        'high': 17.0,
        'low': 15.0,
        'close': 16.0,
      },
      {
        'datetime': '2026-01-01T02:15',
        'open': 15.5,
        'high': 18.0,
        'low': 3.5,
        'close': 16.5,
      },
      {
        'datetime': '2026-01-01T02:30',
        'open': 16.5,
        'high': 17.0,
        'low': 16.4,
        'close': 16.9,
      },
      {
        'datetime': '2026-01-01T02:45',
        'open': 16.5,
        'high': 17.0,
        'low': 16.4,
        'close': 16.9,
      },
    ];
    final engine = BacktestingEngine();
    final result = engine.run(asset: 'XAU/USD', candles: candles);
    expect(result.totalTrades, 1);
    expect(result.wins, 1);
    expect(result.losses, 0);
    expect(result.trades.first.result, 'WIN');
  });
}
