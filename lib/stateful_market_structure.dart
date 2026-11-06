import 'market_structure.dart';

class _AssetStructureState {
  MarketStructure? current;
  String? lastCandleTime;
  String? pendingTrend;
}

class StatefulMarketStructure {
  final Map<String, _AssetStructureState> _states = {};

  String? pendingTrendFor(String asset) {
    return _states[asset.trim().toUpperCase()]?.pendingTrend;
  }

  MarketStructure update({
    required String asset,
    required List<Map<String, dynamic>> candles,
  }) {
    final key = asset.trim().toUpperCase();
    final state = _states.putIfAbsent(key, () => _AssetStructureState());

    if (candles.isEmpty) {
      return state.current ?? _neutral();
    }

    final latestTime = candles.first['datetime']?.toString();

    if (latestTime == null || latestTime.isEmpty) {
      return state.current ?? _neutral();
    }

    if (latestTime == state.lastCandleTime && state.current != null) {
      return state.current!;
    }

    state.lastCandleTime = latestTime;
    final detected = analyzeMarketStructure(candles);

    if (state.current == null || state.current!.trend == 'NEUTRAL') {
      state.current = detected;
      return detected;
    }

    final previousTrend = state.current!.trend;
    final detectedTrend = detected.trend;

    if (detected.choch) {
      if (previousTrend == 'BULLISH' && detectedTrend == 'BULLISH') {
        state.pendingTrend = 'BEARISH';
      } else if (previousTrend == 'BEARISH' && detectedTrend == 'BEARISH') {
        state.pendingTrend = 'BULLISH';
      }
    }

    if (state.pendingTrend == 'BEARISH' && detectedTrend == 'BEARISH') {
      state.current = detected;
      state.pendingTrend = null;
      return detected;
    }

    if (state.pendingTrend == 'BULLISH' && detectedTrend == 'BULLISH') {
      state.current = detected;
      state.pendingTrend = null;
      return detected;
    }

    if (state.pendingTrend != null) {
      if (detectedTrend == previousTrend && detected.bos) {
        state.pendingTrend = null;
        state.current = detected;
        return detected;
      }

      state.current = MarketStructure(
        structure: detected.structure,
        trend: previousTrend,
        bos: detected.bos,
        choch: detected.choch,
      );
      return state.current!;
    }

    if (detectedTrend == previousTrend) {
      state.current = detected;
    }

    return state.current!;
  }

  void reset({String? asset}) {
    if (asset == null) {
      _states.clear();
    } else {
      _states.remove(asset.trim().toUpperCase());
    }
  }

  MarketStructure _neutral() {
    return const MarketStructure(
      structure: 'NONE',
      trend: 'NEUTRAL',
      bos: false,
      choch: false,
    );
  }
}
