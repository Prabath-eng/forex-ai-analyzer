import 'atr_calculator.dart';
import 'stateful_market_structure.dart';

class BacktestTrade {
  final String direction;
  final String signalTime;
  final String entryTime;
  final double entryPrice;
  final double stopLoss;
  final double takeProfit;
  final String? exitTime;
  final double? exitPrice;
  final String? result;
  final double? profitPercent;
  final String riskCalculationMethod;

  const BacktestTrade({
    required this.direction,
    required this.signalTime,
    required this.entryTime,
    required this.entryPrice,
    required this.stopLoss,
    required this.takeProfit,
    this.exitTime,
    this.exitPrice,
    this.result,
    this.profitPercent,
    this.riskCalculationMethod = 'PERCENTAGE FALLBACK',
  });
}

class BacktestResult {
  final int totalTrades;
  final int wins;
  final int losses;
  final double winRate;
  final double netProfitPercent;
  final double maxDrawdownPercent;
  final List<BacktestTrade> trades;
  final double profitFactor;
  final double averageWinPercent;
  final double averageLossPercent;
  final int maxConsecutiveWins;
  final int maxConsecutiveLosses;
  final List<double> equityCurvePercent;

  const BacktestResult({
    required this.totalTrades,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.netProfitPercent,
    required this.maxDrawdownPercent,
    required this.trades,
    this.profitFactor = 0,
    this.averageWinPercent = 0,
    this.averageLossPercent = 0,
    this.maxConsecutiveWins = 0,
    this.maxConsecutiveLosses = 0,
    this.equityCurvePercent = const [],
  });
}

class BacktestingEngine {
  final double stopLossPercent;
  final double takeProfitPercent;

  BacktestingEngine({this.stopLossPercent = 1.0, this.takeProfitPercent = 2.0})
    : assert(stopLossPercent > 0),
      assert(takeProfitPercent > 0);

  final StatefulMarketStructure _structure = StatefulMarketStructure();
  final AtrCalculator _atrCalculator = const AtrCalculator();

  void reset() {
    _structure.reset();
  }

  double _number(Map<String, dynamic> candle, String key) {
    return double.tryParse(candle[key]?.toString() ?? '') ?? 0;
  }

  String _marketTrend(List<Map<String, dynamic>> candles) {
    if (candles.length < 5) return 'WAITING';

    final recent = candles.take(20).toList();
    final closes = recent
        .map((c) => _number(c, 'close'))
        .where((v) => v > 0)
        .toList();

    if (closes.length < 5) return 'WAITING';

    final oldest = closes.last;
    final newest = closes.first;
    final change = ((newest - oldest) / oldest) * 100;

    if (change >= 0.15) return 'UPTREND';
    if (change <= -0.15) return 'DOWNTREND';
    return 'SIDEWAYS';
  }

  int _candlestickScore(List<Map<String, dynamic>> candles) {
    if (candles.length < 2) return 0;

    final current = candles[0];
    final previous = candles[1];

    final open = _number(current, 'open');
    final high = _number(current, 'high');
    final low = _number(current, 'low');
    final close = _number(current, 'close');
    final prevOpen = _number(previous, 'open');
    final prevClose = _number(previous, 'close');

    final body = (close - open).abs();
    final upperWick = high - (open > close ? open : close);
    final lowerWick = (open < close ? open : close) - low;

    int score = 0;

    if (lowerWick > body * 2) score += 2;
    if (upperWick > body * 2) score -= 2;

    if (close > open &&
        prevClose < prevOpen &&
        close > prevOpen &&
        open < prevClose) {
      score += 2;
    }

    if (close < open &&
        prevClose > prevOpen &&
        close < prevOpen &&
        open > prevClose) {
      score -= 2;
    }

    return score.clamp(-2, 2);
  }

  Map<String, double> _liquidityLevels(List<Map<String, dynamic>> candles) {
    if (candles.length < 10) return {'high': 0, 'low': 0};

    final recent = candles.skip(1).take(30).toList();
    final highs = recent.map((c) => _number(c, 'high')).where((v) => v > 0);
    final lows = recent.map((c) => _number(c, 'low')).where((v) => v > 0);

    if (highs.isEmpty || lows.isEmpty) return {'high': 0, 'low': 0};

    return {
      'high': highs.reduce((a, b) => a > b ? a : b),
      'low': lows.reduce((a, b) => a < b ? a : b),
    };
  }

  int _liquiditySweepScore(List<Map<String, dynamic>> candles) {
    if (candles.length < 10) return 0;

    final levels = _liquidityLevels(candles);
    final current = candles.first;
    final high = _number(current, 'high');
    final low = _number(current, 'low');
    final close = _number(current, 'close');

    if (high > levels['high']! && close < levels['high']!) return -2;
    if (low < levels['low']! && close > levels['low']!) return 2;

    return 0;
  }

  Map<String, double> _supportResistance(List<Map<String, dynamic>> candles) {
    if (candles.length < 10) {
      return {'support': 0, 'resistance': 0};
    }

    final recent = candles.take(20).toList();
    final lows = recent.map((c) => _number(c, 'low')).where((v) => v > 0);
    final highs = recent.map((c) => _number(c, 'high')).where((v) => v > 0);

    if (lows.isEmpty || highs.isEmpty) {
      return {'support': 0, 'resistance': 0};
    }

    return {
      'support': lows.reduce((a, b) => a < b ? a : b),
      'resistance': highs.reduce((a, b) => a > b ? a : b),
    };
  }

  int _momentumScore(List<Map<String, dynamic>> candles) {
    final closes = candles
        .map((c) => _number(c, 'close'))
        .where((v) => v > 0)
        .take(20)
        .toList();

    if (closes.length < 10) return 0;

    final recent = closes.take(5).reduce((a, b) => a + b) / 5;
    final older = closes.skip(5).take(5).reduce((a, b) => a + b) / 5;

    if (recent > older) return 1;
    if (recent < older) return -1;
    return 0;
  }

  int _liquidityLevelScore(List<Map<String, dynamic>> candles) {
    if (candles.isEmpty) return 0;
    final levels = _liquidityLevels(candles);
    final price = _number(candles.first, 'close');
    var score = 0;
    if (levels['low']! > 0 && price > 0 && price <= levels['low']! * 1.001) {
      score++;
    }
    if (levels['high']! > 0 && price > 0 && price >= levels['high']! * 0.999) {
      score--;
    }
    return score;
  }

  String _signalForCandles(List<Map<String, dynamic>> candles, String asset) {
    if (candles.length < 10) return 'NEUTRAL';
    final trend = _marketTrend(candles);
    final structure = _structure.update(asset: asset, candles: candles);
    if (structure.choch) return 'NEUTRAL';
    final liquidityScore = _liquidityLevelScore(candles);
    final sweepScore = _liquiditySweepScore(candles);
    final candleScore = _candlestickScore(candles);
    final momentumScore = _momentumScore(candles);
    final levels = _supportResistance(candles);
    final price = _number(candles.first, 'close');
    var srScore = 0;
    if (levels['support']! > 0 && price <= levels['support']! * 1.002) {
      srScore = 1;
    } else if (levels['resistance']! > 0 &&
        price >= levels['resistance']! * 0.998) {
      srScore = -1;
    }
    final trendScore = trend == 'UPTREND'
        ? 2
        : trend == 'DOWNTREND'
        ? -2
        : 0;
    final total =
        liquidityScore +
        sweepScore +
        candleScore +
        momentumScore +
        srScore +
        trendScore;
    if (trend == 'UPTREND' && structure.trend == 'BULLISH' && total >= 3) {
      return 'BUY';
    }
    if (trend == 'DOWNTREND' && structure.trend == 'BEARISH' && total <= -3) {
      return 'SELL';
    }
    return 'NEUTRAL';
  }

  BacktestResult run({
    required String asset,
    required List<Map<String, dynamic>> candles,
  }) {
    reset();
    final history = List<Map<String, dynamic>>.from(candles);
    history.sort(
      (a, b) => (a['datetime'] ?? '').toString().compareTo(
        (b['datetime'] ?? '').toString(),
      ),
    );
    final trades = <BacktestTrade>[];
    var wins = 0;
    var losses = 0;
    var equity = 0.0;
    var peak = 0.0;
    var maxDrawdown = 0.0;
    var grossProfit = 0.0;
    var grossLoss = 0.0;
    var currentWinStreak = 0;
    var currentLossStreak = 0;
    var maxWinStreak = 0;
    var maxLossStreak = 0;
    final equityCurve = <double>[0.0];
    var nextAvailableIndex = 10;
    if (history.length < 11) {
      return BacktestResult(
        totalTrades: 0,
        wins: 0,
        losses: 0,
        winRate: 0,
        netProfitPercent: 0,
        maxDrawdownPercent: 0,
        trades: [],
      );
    }
    for (var i = 9; i < history.length - 1; i++) {
      if (i < nextAvailableIndex) continue;
      final available = history.sublist(0, i + 1).reversed.toList();
      final signal = _signalForCandles(available, asset);
      if (signal != 'BUY' && signal != 'SELL') continue;
      final entry = history[i + 1];
      final entryPrice = _number(entry, 'open');
      if (entryPrice <= 0) continue;
      final isBuy = signal == 'BUY';
      final atr = _atrCalculator.calculate(available);
      final atrRisk = atr == null
          ? null
          : _atrCalculator.calculateRisk(
              direction: signal,
              entryPrice: entryPrice,
              atr: atr,
            );
      final sl =
          atrRisk?['stopLoss'] ??
          entryPrice * (1 + (isBuy ? -1 : 1) * stopLossPercent / 100);
      final tp =
          atrRisk?['takeProfit'] ??
          entryPrice * (1 + (isBuy ? 1 : -1) * takeProfitPercent / 100);
      var exitTime = '';
      var exitPrice = 0.0;
      var result = 'OPEN';
      var exitIndex = -1;
      for (var j = i + 1; j < history.length; j++) {
        final bar = history[j];
        final high = _number(bar, 'high');
        final low = _number(bar, 'low');
        if (isBuy ? low <= sl : high >= sl) {
          result = 'LOSS';
          exitPrice = sl;
          exitTime = (bar['datetime'] ?? '').toString();
          exitIndex = j;
          break;
        } else if (isBuy ? high >= tp : low <= tp) {
          result = 'WIN';
          exitPrice = tp;
          exitTime = (bar['datetime'] ?? '').toString();
          exitIndex = j;
          break;
        }
      }
      if (result == 'OPEN') continue;
      nextAvailableIndex = exitIndex + 1;
      final profit =
          ((exitPrice - entryPrice) / entryPrice) * 100 * (isBuy ? 1 : -1);
      trades.add(
        BacktestTrade(
          direction: signal,
          signalTime: (history[i]['datetime'] ?? '').toString(),
          entryTime: (entry['datetime'] ?? '').toString(),
          entryPrice: entryPrice,
          stopLoss: sl,
          takeProfit: tp,
          exitTime: exitTime,
          exitPrice: exitPrice,
          result: result,
          profitPercent: profit,
          riskCalculationMethod: atrRisk != null
              ? 'ATR-BASED'
              : 'PERCENTAGE FALLBACK',
        ),
      );
      if (result == 'WIN') {
        wins++;
        grossProfit += profit;
        currentWinStreak++;
        currentLossStreak = 0;
        if (currentWinStreak > maxWinStreak) maxWinStreak = currentWinStreak;
      } else {
        losses++;
        grossLoss += profit.abs();
        currentLossStreak++;
        currentWinStreak = 0;
        if (currentLossStreak > maxLossStreak) {
          maxLossStreak = currentLossStreak;
        }
      }
      equity += profit;
      equityCurve.add(equity);
      if (equity > peak) peak = equity;
      final drawdown = peak - equity;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    }
    final total = trades.length;
    return BacktestResult(
      totalTrades: total,
      wins: wins,
      losses: losses,
      winRate: total == 0 ? 0 : wins / total * 100,
      netProfitPercent: equity,
      maxDrawdownPercent: maxDrawdown,
      trades: trades,
      profitFactor: grossLoss == 0
          ? (grossProfit > 0 ? double.infinity : 0)
          : grossProfit / grossLoss,
      averageWinPercent: wins == 0 ? 0 : grossProfit / wins,
      averageLossPercent: losses == 0 ? 0 : grossLoss / losses,
      maxConsecutiveWins: maxWinStreak,
      maxConsecutiveLosses: maxLossStreak,
      equityCurvePercent: equityCurve,
    );
  }
}
