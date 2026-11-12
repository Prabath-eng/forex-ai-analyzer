import 'package:flutter_test/flutter_test.dart';
import 'package:forex_ai_analyzer/order_block_detector.dart';

void main() {
  group('Order Block Detector', () {
    final bullishCandles = [
      {"open": 12.0, "high": 16.0, "low": 11.0, "close": 15.0},
      {"open": 10.0, "high": 11.0, "low": 8.0, "close": 9.0},
      {"open": 9.0, "high": 10.0, "low": 8.5, "close": 9.5},
      {"open": 9.5, "high": 10.5, "low": 9.0, "close": 10.0},
      {"open": 10.0, "high": 11.0, "low": 9.5, "close": 10.5},
      {"open": 10.5, "high": 11.5, "low": 10.0, "close": 11.0},
      {"open": 11.0, "high": 12.0, "low": 10.5, "close": 11.5},
      {"open": 11.5, "high": 12.5, "low": 11.0, "close": 12.0},
      {"open": 12.0, "high": 13.0, "low": 11.5, "close": 12.5},
    ];
    test("rejects order block without BOS confirmation", () {
      final candles = List<Map<String, dynamic>>.from(bullishCandles);
      candles[0] = {"open": 10.0, "high": 12.5, "low": 9.5, "close": 12.0};
      expect(detectOrderBlocks(candles), isEmpty);
    });

    test("ignores weak impulse without displacement", () {
      final candles = List<Map<String, dynamic>>.from(bullishCandles);
      candles[0] = {"open": 12.0, "high": 13.0, "low": 11.0, "close": 12.5};
      expect(detectOrderBlocks(candles), isEmpty);
    });

    final bearishCandles = [
      {"open": 15.0, "high": 16.0, "low": 9.0, "close": 9.0},
      {"open": 12.0, "high": 14.0, "low": 11.0, "close": 13.0},
      {"open": 13.0, "high": 14.0, "low": 12.0, "close": 13.5},
      {"open": 13.0, "high": 13.5, "low": 12.0, "close": 12.5},
      {"open": 12.5, "high": 13.0, "low": 11.5, "close": 12.0},
      {"open": 12.0, "high": 12.5, "low": 11.0, "close": 11.5},
      {"open": 11.5, "high": 12.0, "low": 10.5, "close": 11.0},
      {"open": 11.0, "high": 11.5, "low": 10.5, "close": 10.5},
      {"open": 10.5, "high": 11.0, "low": 9.5, "close": 10.0},
    ];
    test("detects confirmed bullish order block", () {
      final result = detectOrderBlocks(bullishCandles);
      expect(result.length, 1);
      expect(result.first.direction, "BULLISH");
      expect(result.first.confirmed, isTrue);
    });
    test("detects confirmed bearish order block", () {
      final result = detectOrderBlocks(bearishCandles);
      expect(result.length, 1);
      expect(result.first.direction, "BEARISH");
      expect(result.first.confirmed, isTrue);
    });

    test("returns empty when candles are insufficient", () {
      expect(
        detectOrderBlocks([
          {"open": 1.0, "high": 2.0, "low": 0.5, "close": 1.5},
        ]),
        isEmpty,
      );
    });
    test("ignores invalid OHLC candles", () {
      final candles = List<Map<String, dynamic>>.from(bullishCandles);
      candles[8] = {"open": 12.0, "high": 11.0, "low": 11.5, "close": 12.5};
      expect(detectOrderBlocks(candles), isEmpty);
    });
  });
}
