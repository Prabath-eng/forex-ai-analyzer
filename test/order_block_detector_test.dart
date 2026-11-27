import 'package:flutter_test/flutter_test.dart';
import 'package:forex_ai_analyzer/order_block_detector.dart';

void main() {
  group('Order Block Detector', () {
    final bullishCandles = [
      {"open": 14.0, "high": 15.0, "low": 13.5, "close": 14.5},
      {"open": 13.5, "high": 14.5, "low": 13.2, "close": 14.0},
      {"open": 12.0, "high": 15.5, "low": 11.8, "close": 15.0},
      {"open": 12.5, "high": 13.0, "low": 11.5, "close": 12.0},
      {"open": 11.0, "high": 11.5, "low": 10.5, "close": 11.2},
      {"open": 11.2, "high": 13.5, "low": 10.8, "close": 11.3},
      {"open": 11.0, "high": 11.8, "low": 9.8, "close": 10.9},
      {"open": 10.5, "high": 12.0, "low": 10.0, "close": 10.8},
      {"open": 10.0, "high": 10.8, "low": 9.0, "close": 10.2},
    ];

    final bearishCandles = [
      {"open": 9.0, "high": 9.5, "low": 8.0, "close": 8.8},
      {"open": 10.0, "high": 10.2, "low": 8.5, "close": 9.0},
      {"open": 14.0, "high": 14.2, "low": 9.0, "close": 10.0},
      {"open": 12.0, "high": 13.5, "low": 11.5, "close": 13.0},
      {"open": 12.5, "high": 13.0, "low": 11.8, "close": 12.3},
      {"open": 12.0, "high": 12.5, "low": 10.5, "close": 12.1},
      {"open": 12.0, "high": 13.0, "low": 11.2, "close": 12.2},
      {"open": 12.5, "high": 13.0, "low": 11.5, "close": 12.4},
      {"open": 13.0, "high": 14.0, "low": 12.0, "close": 13.2},
    ];

    test("rejects order block without BOS confirmation", () {
      final candles = List<Map<String, dynamic>>.from(bullishCandles);
      candles[1] = {"open": 13.5, "high": 14.0, "low": 12.8, "close": 13.0};
      expect(detectOrderBlocks(candles), isEmpty);
    });

    test("ignores weak impulse without displacement", () {
      final candles = List<Map<String, dynamic>>.from(bullishCandles);
      candles[2] = {"open": 12.0, "high": 13.0, "low": 11.8, "close": 12.5};
      expect(detectOrderBlocks(candles), isEmpty);
    });

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

    test("detects fresh bullish order block", () {
      final result = detectOrderBlocks(bullishCandles);
      expect(result.first.status, "FRESH");
      expect(result.first.mitigated, isFalse);
      expect(result.first.invalidated, isFalse);
    });

    test("detects mitigated bullish order block", () {
      final candles = [
        {"open": 12.0, "high": 12.5, "low": 11.8, "close": 12.1},
        ...bullishCandles,
      ];
      final result = detectOrderBlocks(candles);
      expect(result.first.status, "MITIGATED");
      expect(result.first.mitigated, isTrue);
      expect(result.first.filled, isFalse);
    });

    test("detects filled bullish order block", () {
      final candles = [
        {"open": 12.0, "high": 12.5, "low": 11.0, "close": 12.0},
        ...bullishCandles,
      ];
      final result = detectOrderBlocks(candles);
      expect(result.first.status, "FILLED");
      expect(result.first.filled, isTrue);
    });

    test("detects invalidated bullish order block", () {
      final candles = [
        {"open": 7.5, "high": 8.0, "low": 7.0, "close": 7.5},
        ...bullishCandles,
      ];
      final result = detectOrderBlocks(candles);
      expect(result.first.status, "INVALIDATED");
      expect(result.first.invalidated, isTrue);
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
