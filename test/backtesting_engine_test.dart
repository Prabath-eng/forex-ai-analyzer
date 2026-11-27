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

  test('BUY trade reaches take profit using percentage fallback', () {
    final candles = [
      [10.0, 5.0, 8.0, 8.0],
      [9.0, 4.0, 5.0, 5.0],
      [12.0, 6.0, 11.0, 11.0],
      [11.0, 5.0, 6.0, 6.0],
      [14.0, 7.0, 13.0, 13.0],
      [13.0, 6.0, 7.0, 7.0],
      [15.0, 8.0, 14.0, 14.0],
      [14.0, 7.0, 13.0, 13.0],
      [18.0, 15.5, 16.0, 16.0],
      [17.0, 14.5, 16.2, 15.8],
      [17.0, 16.1, 16.8, 16.2],
    ];

    final history = List.generate(candles.length, (i) {
      final bar = candles[i];
      return {
        'datetime':
            '2026-01-01T${(i * 15 ~/ 60).toString().padLeft(2, '0')}:${(i * 15 % 60).toString().padLeft(2, '0')}:00',
        'open': bar[3],
        'high': bar[0],
        'low': bar[1],
        'close': bar[2],
      };
    });

    final result = BacktestingEngine().run(asset: 'XAU/USD', candles: history);

    expect(result.totalTrades, 1);
    expect(result.wins, 1);
    expect(result.losses, 0);
    expect(result.trades.first.direction, 'BUY');
    expect(result.trades.first.result, 'WIN');
    expect(result.trades.first.riskCalculationMethod, 'PERCENTAGE FALLBACK');
  });

  test('date filter keeps earlier candles for warm-up', () {
    final values = [
      [10.0, 5.0, 8.0, 8.0],
      [9.0, 4.0, 5.0, 5.0],
      [12.0, 6.0, 11.0, 11.0],
      [11.0, 5.0, 6.0, 6.0],
      [14.0, 7.0, 13.0, 13.0],
      [13.0, 6.0, 7.0, 7.0],
      [15.0, 8.0, 14.0, 14.0],
      [14.0, 7.0, 13.0, 13.0],
      [18.0, 15.5, 16.0, 16.0],
      [17.0, 14.5, 16.2, 15.8],
      [17.0, 16.1, 16.8, 16.2],
    ];
    final history = List.generate(values.length, (i) {
      final b = values[i];
      final day = i < 9 ? '01' : '02';
      return {
        'datetime':
            '2026-01-$day'
            'T${(i * 15 ~/ 60).toString().padLeft(2, '0')}:'
            '${(i * 15 % 60).toString().padLeft(2, '0')}:00',
        'open': b[3],
        'high': b[0],
        'low': b[1],
        'close': b[2],
      };
    });

    final result = BacktestingEngine().run(
      asset: 'XAU/USD',
      candles: history,
      startDate: DateTime(2026, 1, 2),
    );
    expect(result.totalTrades, 1);
    expect(result.wins, 1);
  });

  test('date filter excludes signals after start range', () {
    final history = List.generate(
      11,
      (i) => {
        'datetime': '2026-01-01T00:${i.toString().padLeft(2, '0')}:00',
        'open': 100.0,
        'high': 101.0,
        'low': 99.0,
        'close': 100.0,
      },
    );
    final result = BacktestingEngine().run(
      asset: 'XAU/USD',
      candles: history,
      startDate: DateTime(2026, 1, 2),
    );
    expect(result.totalTrades, 0);
  });
}
