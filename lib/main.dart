import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'market_structure.dart';
import 'services/api_key_service.dart';
import 'services/market_data_service.dart';

void main() {
  runApp(const ForexAIAnalyzerApp());
}

class ForexAIAnalyzerApp extends StatelessWidget {
  const ForexAIAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Forex AI Analyzer',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080D16),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AnalyzerHome(),
    );
  }
}

class AnalyzerHome extends StatefulWidget {
  const AnalyzerHome({super.key});

  @override
  State<AnalyzerHome> createState() => _AnalyzerHomeState();
}

class _AnalyzerHomeState extends State<AnalyzerHome> {
  String selectedAsset = 'XAU/USD';
  String selectedTimeframe = '15m';
  int bottomIndex = 0;

  String signal = 'NEUTRAL';
  int signalConfidence = 50;
  String marketPrice = '--';
  String marketChange = '--';
  bool isMarketLoading = false;
  final Map<String, Map<String, String>> _quoteCache = {};
List<Map<String, dynamic>> liveCandles = [];
MarketStructure marketStructure = const MarketStructure(
  structure: 'NONE',
  trend: 'NEUTRAL',
  bos: false,
  choch: false,
);
void _updateMarketStructure() {
  marketStructure = analyzeMarketStructure(liveCandles);
}
final Map<String, List<Map<String, dynamic>>> _candleCache = {};
String marketTrend = 'WAITING';
String trendStrength = '--';
Widget _buildMarketStructureCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ICT / SMC Market Structure',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Structure: ${marketStructure.structure}',
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'Trend: ${marketStructure.trend}',
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'BOS: ${marketStructure.bos ? "YES" : "NO"}',
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          'CHOCH: ${marketStructure.choch ? "YES" : "NO"}',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  );
}
  final ApiKeyService _apiKeyService = ApiKeyService();
  final MarketDataService _marketDataService = MarketDataService();
  final TextEditingController _apiKeyController = TextEditingController();
  bool _apiKeySaved = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _calculateSignal();
    _loadMarketData();
  }

  Future<void> _loadMarketData() async {
    final cached = _quoteCache[selectedAsset];
    if (cached != null) {
      setState(() {
        marketPrice = cached['price'] ?? '--';
        marketChange = cached['change'] ?? '--';
      });
    }
    setState(() {
      isMarketLoading = true;
    });

    try {
      final quote = cached != null ? {'close': cached['price'], 'percent_change': cached['change']?.replaceAll('%', '')} : await _marketDataService.getQuote(selectedAsset);

      final price = double.tryParse(
            quote['close']?.toString() ??
                quote['price']?.toString() ??
                '',
          )?.toStringAsFixed(2) ??
          '--';

      final change = double.tryParse(
            quote['percent_change']?.toString() ?? '',
          )?.toStringAsFixed(2) ??
          '--';

      _quoteCache[selectedAsset] = {
        'price': price,
        'change': change == '--' ? '--' : '$change%',
      };
      if (!mounted) return;

      setState(() {
        marketPrice = price;
        marketChange = change == '--' ? '--' : '$change%';
        isMarketLoading = false;
      });

      try {
        final candles = _candleCache[selectedAsset] != null ? {'values': _candleCache[selectedAsset]} : await _marketDataService.getTimeSeries(selectedAsset, interval: '15min', outputsize: 100);

        final values = candles['values'];

        if (values is List && values.isNotEmpty) {
          liveCandles = values
              .whereType<Map>()
              .map((candle) => Map<String, dynamic>.from(candle))
              .toList();

          _candleCache[selectedAsset] = liveCandles;
          _updateMarketStructure();
          _calculateMarketTrend();

          if (mounted) {
            _calculateSignal();
          }

          debugPrint(
            'Live candles loaded: ${liveCandles.length}',
          );
        }
      } catch (e) {
        debugPrint('Candlestick request skipped: $e');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        marketPrice = 'API Error';
        marketChange = e.toString();
        isMarketLoading = false;
      });
    }
  }

  void _calculateMarketTrend() {
    if (liveCandles.length < 5) {
      marketTrend = 'WAITING';
      trendStrength = '--';
    }

    final recent = liveCandles.take(20).toList();

    final closes = recent
        .map((candle) => double.tryParse(
              candle['close']?.toString() ?? '',
            ))
        .whereType<double>()
        .toList();

    if (closes.length < 5) {
      marketTrend = 'WAITING';
      trendStrength = '--';
    }

    final first = closes.last;
    final last = closes.first;
    final changePercent = first == 0
        ? 0
        : ((last - first) / first) * 100;

    if (changePercent >= 0.15) {
      marketTrend = 'UPTREND';
      trendStrength = '${changePercent.abs().toStringAsFixed(2)}%';
    } else if (changePercent <= -0.15) {
      marketTrend = 'DOWNTREND';
      trendStrength = '${changePercent.abs().toStringAsFixed(2)}%';
    } else {
      marketTrend = 'SIDEWAYS';
      trendStrength = '${changePercent.abs().toStringAsFixed(2)}%';
    }
  }

  void _calculateSignal() {
    if (liveCandles.length < 5) {
      setState(() {
        signal = 'NEUTRAL';
        signalConfidence = 50;
      });
      return;
    }

    int score = 0;
    final liquidity = _liquidityLevels();
    final price = double.tryParse(marketPrice) ?? 0;
    if (liquidity["low"]! > 0 && price > 0) {
      if (price <= liquidity["low"]! * 1.001) score += 1;
    }
    if (liquidity["high"]! > 0 && price > 0) {
      if (price >= liquidity["high"]! * 0.999) score -= 1;
    }

    score += _liquiditySweepScore();

    score += _candlestickScore();
    final sr = _supportResistance();
    final currentPrice = double.tryParse(marketPrice);
    if (currentPrice != null && sr["support"]! > 0 && sr["resistance"]! > 0) {
      final range = sr["resistance"]! - sr["support"]!;
      if (range > 0) {
        final position = (currentPrice - sr["support"]!) / range;
        if (position < 0.25) score += 1;
        if (position > 0.75) score -= 1;
      }
    }
    if (marketTrend == 'UPTREND') score += 2;
    if (marketTrend == 'DOWNTREND') score -= 2;

    final closes = liveCandles
        .map((c) => double.tryParse(c['close']?.toString() ?? ''))
        .whereType<double>()
        .take(20)
        .toList();

    if (closes.length >= 5) {
      final recent = closes.take(5).reduce((a, b) => a + b) / 5;
      final older = closes.skip(5).take(5).toList();
      if (older.length >= 5) {
        final previous = older.reduce((a, b) => a + b) / older.length;
        if (recent > previous) score += 1;
        if (recent < previous) score -= 1;
      }
    }

    String newSignal = 'NEUTRAL';
    int confidence = 50;
    if (score >= 3) {
      newSignal = 'BUY';
      confidence = 75;
    } else if (score <= -3) {
      newSignal = 'SELL';
      confidence = 75;
    } else if (score > 0) {
      newSignal = 'BUY';
      confidence = 60;

    } else if (score < 0) {
      newSignal = 'SELL';
      confidence = 60;
    }

    setState(() {
      signal = newSignal;
      signalConfidence = confidence;
    });
  }
  String _candlestickLabel() {
    final score = _candlestickScore();
    if (score >= 2) return "Bullish";
    if (score <= -2) return "Bearish";
    return "Neutral";
  }

  String _liquidityLabel() {
    final score = _liquiditySweepScore();
    if (score > 0) return "Bullish Sweep";
    if (score < 0) return "Bearish Sweep";
    return "No Sweep";
  }

  Map<String, double> _supportResistance() {
    if (liveCandles.length < 10) return {"support": 0, "resistance": 0};

    final recent = liveCandles.take(20).toList();
    final highs = recent.map((c) => double.tryParse(c["high"]?.toString() ?? "")).whereType<double>().toList();
    final lows = recent.map((c) => double.tryParse(c["low"]?.toString() ?? "")).whereType<double>().toList();

    if (highs.isEmpty || lows.isEmpty) return {"support": 0, "resistance": 0};

    return {
      "support": lows.reduce(math.min),
      "resistance": highs.reduce(math.max),
    };
  }


  int _candlestickScore() {
    if (liveCandles.length < 2) return 0;

    final current = liveCandles[0];
    final previous = liveCandles[1];

    final open = double.tryParse(current["open"]?.toString() ?? "");
    final high = double.tryParse(current["high"]?.toString() ?? "");
    final low = double.tryParse(current["low"]?.toString() ?? "");
    final close = double.tryParse(current["close"]?.toString() ?? "");

    final prevOpen = double.tryParse(previous["open"]?.toString() ?? "");
    final prevClose = double.tryParse(previous["close"]?.toString() ?? "");

    if ([open, high, low, close, prevOpen, prevClose]
        .any((v) => v == null)) {
      return 0;
    }

    int score = 0;

    final body = (close! - open!).abs();
    final upperWick = high! - math.max(open, close);
    final lowerWick = math.min(open, close) - low!;

    if (close > open && lowerWick > body * 2) {
      score += 2;
    }

    if (close < open && upperWick > body * 2) {
      score -= 2;
    }

    if (close > open &&
        prevClose! < prevOpen! &&
        close > prevOpen &&
        open < prevClose) {
      score += 2;
    }

    if (close < open &&
        prevClose! > prevOpen! &&
        close < prevOpen &&
        open > prevClose) {
      score -= 2;
    }

    return score.clamp(-2, 2);
  }

  int _liquiditySweepScore() {
    if (liveCandles.length < 5) return 0;

    final liquidity = _liquidityLevels();
    final current = liveCandles[0];

    final high = double.tryParse(current["high"]?.toString() ?? "");
    final low = double.tryParse(current["low"]?.toString() ?? "");
    final close = double.tryParse(current["close"]?.toString() ?? "");

    if (high == null || low == null || close == null) return 0;

    int score = 0;

    if (liquidity["high"]! > 0 && high > liquidity["high"]! && close < liquidity["high"]!) {
      score -= 2;
    }

    if (liquidity["low"]! > 0 && low < liquidity["low"]! && close > liquidity["low"]!) {
      score += 2;
    }

    return score;
  }

  Map<String, double> _liquidityLevels() {
    if (liveCandles.length < 10) {
      return {"high": 0, "low": 0};
    }

    final recent = liveCandles.skip(1).take(30).toList();
    final highs = recent
        .map((c) => double.tryParse(c["high"]?.toString() ?? ""))
        .whereType<double>()
        .toList();
    final lows = recent
        .map((c) => double.tryParse(c["low"]?.toString() ?? ""))
        .whereType<double>()
        .toList();

    if (highs.isEmpty || lows.isEmpty) {
      return {"high": 0, "low": 0};
    }

    return {
      "high": highs.reduce(math.max),
      "low": lows.reduce(math.min),
    };
  }

  final List<String> assets = [
    'XAU/USD',
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
  ];

  final List<String> timeframes = [
    '1m',
    '5m',
    '15m',
    '30m',
    '1H',
    '4H',
    '1D',
  ];  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B111D),
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF00C853),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_graph,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forex AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Market Analyzer',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0B111D),
        selectedIndex: bottomIndex,
        onDestinationSelected: (index) {
          setState(() {
            bottomIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Analyzer',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Charts',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (bottomIndex == 1) {
      return _buildChartPage();
    }

    if (bottomIndex == 2) {
      return _buildHistoryPage();
    }

    if (bottomIndex == 3) {
      return _buildSettingsPage();
    }

    return _buildAnalyzerPage();
  }  Widget _buildAnalyzerPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAssetSelector(),
            const SizedBox(height: 12),
            _buildMarketHeader(),
            const SizedBox(height: 12),
            _buildSignalCard(),
            const SizedBox(height: 14),
            _buildChartCard(),
            const SizedBox(height: 14),
            _buildMarketStructureCard(),
            const SizedBox(height: 14),
            _buildAnalysisGrid(),
            const SizedBox(height: 14),
            _buildNewsCard(),
            const SizedBox(height: 14),
            _buildFinalAnalysisCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetSelector() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: assets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final asset = assets[index];
          final selected = asset == selectedAsset;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedAsset = asset;
              });
    _loadMarketData();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF00C853)
                    : const Color(0xFF111927),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF00C853)
                      : Colors.white10,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                asset,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.black : Colors.white70,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarketHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedAsset,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gold / Forex Market',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                isMarketLoading ? 'Loading...' : marketPrice,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                marketChange,
                style: TextStyle(
                  color: marketChange.startsWith('-')
                      ? Colors.redAccent
                      : const Color(0xFF00C853),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }  Widget _buildSignalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF063D27),
            Color(0xFF0C171F),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00C853),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.psychology,
                color: Color(0xFF00C853),
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'AI MARKET SIGNAL',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            signal,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: signal == 'BUY'
                  ? const Color(0xFF00E676)
                  : signal == 'SELL'
                      ? Colors.redAccent
                      : Colors.amber,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            signal == 'BUY'
                ? 'Bullish market structure detected'
                : signal == 'SELL'
                    ? 'Bearish market structure detected'
                    : 'Market structure is unclear',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Confidence',
                  '$signalConfidence%',
                  Icons.verified,
                ),
              ),
              Expanded(
                child: _metric(
                  'Risk',
                  'Medium',
                  Icons.warning_amber,
                ),
              ),
              Expanded(
                child: _metric(
                  'Trend',
                  signal == 'BUY'
                      ? 'Bullish'
                      : signal == 'SELL'
                          ? 'Bearish'
                          : 'Neutral',
                  signal == 'BUY'
                      ? Icons.trending_up
                      : signal == 'SELL'
                          ? Icons.trending_down
                          : Icons.remove_circle_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF00C853),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard() {
    return Container(
      decoration: _boxDecoration(),
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        14,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Price Chart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedTimeframe,
                  dropdownColor: const Color(0xFF111927),
                  items: timeframes.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(
                        time,
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedTimeframe = value;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            width: double.infinity,
            child: CustomPaint(
              painter: CandleChartPainter(candles: liveCandles),
            ),
          ),
        ],
      ),
    );
  }  Widget _buildAnalysisGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            _analysisCard(
              'ICT',
              'Bullish',
              'Liquidity sweep detected',
              Icons.track_changes,
            ),
            _analysisCard(
              'SMC',
              'Bullish',
              'Order Block + BOS',
              Icons.account_tree,
            ),
            _analysisCard(
              'Patterns',
              _candlestickLabel(),
              _candlestickLabel() == 'Bullish' ? 'Bullish candle pattern detected' : _candlestickLabel() == 'Bearish' ? 'Bearish candle pattern detected' : 'No strong candle pattern',
              Icons.candlestick_chart,
            ),
            _analysisCard(
              'Liquidity',
              _liquidityLabel(),
              _liquidityLabel() == 'Bullish Sweep'
                  ? 'Sell-side liquidity swept'
                  : _liquidityLabel() == 'Bearish Sweep'
                      ? 'Buy-side liquidity swept'
                      : 'No liquidity sweep detected',
              Icons.water_drop,
            ),
            _analysisCard(

              'Momentum',
              'Strong',
              'Buying pressure rising',
              Icons.speed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _analysisCard(
    String title,
    String value,
    String description,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF00C853),
            size: 22,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF00E676),
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white60,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.public,
                color: Color(0xFF00C853),
              ),
              SizedBox(width: 8),
              Text(
                'WORLD NEWS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _newsRow(
            'US Dollar weakens as market expects rate cuts',
            'USD',
            Icons.currency_exchange,
          ),
          const Divider(color: Colors.white10),
          _newsRow(
            'Gold demand remains strong amid uncertainty',
            'GOLD',
            Icons.auto_graph,
          ),
          const Divider(color: Colors.white10),
          _newsRow(
            'Global markets monitor central bank decisions',
            'MARKET',
            Icons.account_balance,
          ),
        ],
      ),
    );
  }

  Widget _newsRow(
    String title,
    String category,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF111927),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 19,
              color: const Color(0xFF00C853),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: Colors.white38,
          ),
        ],
      ),
    );

  }

  Widget _buildFinalAnalysisCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101923),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF263445),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Color(0xFF00E676),
              ),
              SizedBox(width: 8),
              Text(
                'FINAL AI ANALYSIS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'BUY BIAS',
            style: TextStyle(
              color: Color(0xFF00E676),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'World news, market structure, ICT, SMC, '
            'price action and momentum are currently '
            'aligned with a bullish scenario.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _finalMetric(
                  'Structure',
                  'Bullish',
                ),
              ),
              Expanded(
                child: _finalMetric(

                  'Momentum',
                  'Strong',
                ),
              ),
              Expanded(
                child: _finalMetric(
                  'Confidence',
                  '87%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _finalMetric(
    String title,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF00E676),
          ),
        ),
      ],
    );
  }

  Widget _buildChartPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Advanced Charts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Multi-timeframe market analysis',
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: _boxDecoration(),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        selectedAsset,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF063D27),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 330,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: CandleChartPainter(candles: liveCandles),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }  Widget _buildHistoryPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Signal History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Previous AI market signals',
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 16),
            _historyItem(
              'XAU/USD',
              'BUY',
              '87%',
              '15m',
              'Today, 19:42',
            ),
            _historyItem(
              'EUR/USD',
              'SELL',
              '81%',
              '1H',
              'Today, 18:25',
            ),
            _historyItem(
              'GBP/USD',
              'BUY',
              '76%',
              '30m',
              'Today, 17:10',
            ),
            _historyItem(
              'USD/JPY',
              'SELL',
              '73%',
              '4H',
              'Today, 15:48',
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyItem(
    String asset,
    String signal,
    String confidence,
    String timeframe,
    String time,
  ) {
    final bool isBuy = signal == 'BUY';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isBuy
                  ? const Color(0xFF063D27)
                  : const Color(0xFF3D1010),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isBuy
                  ? Icons.trending_up
                  : Icons.trending_down,
              color: isBuy
                  ? const Color(0xFF00E676)
                  : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time • $timeframe',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                signal,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isBuy
                      ? const Color(0xFF00E676)
                      : Colors.redAccent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                confidence,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Customize your AI analyzer',
              style: TextStyle(
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 16),
            _settingsTile(
              Icons.notifications_none,
              'Notifications',
              'Signal alerts and market updates',
              true,
            ),
            _settingsTile(
              Icons.public,
              'World News',
              'Include global market news',
              true,
            ),
            _settingsTile(
              Icons.psychology,
              'AI Analysis',
              'Enable multi-factor analysis',
              true,
            ),
            _settingsTile(
              Icons.show_chart,
              'Price Alerts',
              'Notify when price reaches a level',
              false,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: _boxDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Twelve Data API',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Connect live forex and gold market data',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Paste your Twelve Data API key',
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save_outlined),
                        onPressed: _saveApiKey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveApiKey,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Save API Key Securely'),
                    ),
                  ),
                  if (_apiKeySaved) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'API key saved securely on this device.',
                      style: TextStyle(
                        color: Color(0xFF00C853),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: _boxDecoration(),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis Engine',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'World News → Price Action → '
                    'Chart Patterns → ICT → SMC → '
                    'Momentum → Final Signal',
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Forex AI Analyzer',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();

    if (key.isEmpty) {
    }

    await _apiKeyService.saveApiKey(key);

    if (!mounted) {
    }

    setState(() {
      _apiKeySaved = true;
    });

    _apiKeyController.clear();
  }

  Widget _settingsTile(
    IconData icon,
    String title,
    String subtitle,
    bool enabled,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: _boxDecoration(),
      child: SwitchListTile(
        value: enabled,
        onChanged: (value) {},
        secondary: Icon(
          icon,
          color: const Color(0xFF00C853),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        activeThumbColor: const Color(0xFF00C853),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: const Color(0xFF101923),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: const Color(0xFF1D2A3A),
      ),
    );
  }
}

class CandleChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> candles;

  CandleChartPainter({required this.candles});
  final List<double> prices = [
    2640,
    2643,
    2641,
    2647,
    2645,
    2650,
    2648,
    2654,
    2651,
    2657,
    2655,
    2660,
    2658,
    2663,
    2661,
    2666,
    2664,
    2670,
    2668,
    2674,
    2671,
    2677,
    2675,
    2680,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final candlePaint = Paint()
      ..style = PaintingStyle.fill;

    final double chartWidth = size.width;
    final double chartHeight = size.height;

    const double leftPadding = 8;
    const double rightPadding = 45;
    final List<double> chartPrices = candles.isNotEmpty ? candles.reversed.map((c) => double.tryParse(c["close"]?.toString() ?? "") ?? 0).where((p) => p > 0).toList() : prices;
    const double topPadding = 12;
    const double bottomPadding = 22;

    final double usableWidth =
        chartWidth - leftPadding - rightPadding;

    final double usableHeight =
        chartHeight - topPadding - bottomPadding;

    double minPrice = chartPrices.reduce(math.min);
    double maxPrice = chartPrices.reduce(math.max);

    final double range = maxPrice - minPrice;

    minPrice -= range * 0.18;
    maxPrice += range * 0.18;

    final double priceRange = maxPrice - minPrice;

    for (int i = 0; i <= 5; i++) {
      final double y =
          topPadding + usableHeight * i / 5;

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(
          chartWidth - rightPadding,
          y,
        ),
        gridPaint,
      );

      final double price =
          maxPrice - priceRange * i / 5;

      final textPainter = TextPainter(
        text: TextSpan(
          text: price.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          chartWidth - rightPadding + 6,
          y - textPainter.height / 2,
        ),
      );
    }

    for (int i = 0; i <= 6; i++) {
      final double x =
          leftPadding + usableWidth * i / 6;

      canvas.drawLine(
        Offset(x, topPadding),
        Offset(
          x,
          chartHeight - bottomPadding,
        ),
        gridPaint,
      );
    }

    final double candleStep =
        usableWidth / chartPrices.length;

    final double candleWidth =
        candleStep * 0.58;

    double priceToY(double price) {
      return topPadding +
          (maxPrice - price) /
              priceRange *
              usableHeight;
    }

    for (int i = 0; i < chartPrices.length; i++) {
      final double close = chartPrices[i];

      final double open = i == 0
          ? close - 2
          : chartPrices[i - 1];

      final double high =
          math.max(open, close) +
          2.2 +
          (i % 3) * 0.6;

      final double low =
          math.min(open, close) -
          2.0 -
          (i % 2) * 0.7;

      final double x =
          leftPadding +
          candleStep * i +
          candleStep / 2;

      final double openY = priceToY(open);
      final double closeY = priceToY(close);
      final double highY = priceToY(high);
      final double lowY = priceToY(low);

      final bool bullish = close >= open;

      candlePaint.color = bullish
          ? const Color(0xFF00C853)
          : const Color(0xFFFF5252);

      canvas.drawLine(
        Offset(x, highY),
        Offset(x, lowY),
        candlePaint,
      );

      final double bodyTop =
          math.min(openY, closeY);

      final double bodyBottom =
          math.max(openY, closeY);

      final double bodyHeight =
          math.max(2, bodyBottom - bodyTop);

      final Rect rect = Rect.fromLTWH(
        x - candleWidth / 2,
        bodyTop,
        candleWidth,
        bodyHeight,
      );

      canvas.drawRect(
        rect,
        candlePaint,
      );
    }

    final linePaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final Path path = Path();

    for (int i = 0; i < chartPrices.length; i++) {
      final double x =
          leftPadding +
          candleStep * i +
          candleStep / 2;

      final double y = priceToY(chartPrices[i]);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    final double currentPrice = chartPrices.last;
    final double currentY = priceToY(currentPrice);

    final markerPaint = Paint()
      ..color = const Color(0xFF00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(leftPadding, currentY),
      Offset(
        chartWidth - rightPadding,
        currentY,
      ),
      markerPaint,
    );

    final TextPainter currentText = TextPainter(
      text: TextSpan(
        text: currentPrice.toStringAsFixed(1),
        style: const TextStyle(
          color: Color(0xFF00E676),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    currentText.layout();

    currentText.paint(
      canvas,
      Offset(
        chartWidth - rightPadding + 5,
        currentY - currentText.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(
    covariant CandleChartPainter oldDelegate,
  ) {
    return false;
  }
}
