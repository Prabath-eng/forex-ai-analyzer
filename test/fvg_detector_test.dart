import 'package:flutter_test/flutter_test.dart';
import 'package:forex_ai_analyzer/fvg_detector.dart';

void main() {
  group('Fair Value Gap Detector', () {
    test('detects bullish FVG', () {
      final candles = [
        {'high': 14.0, 'low': 12.0},
        {'high': 11.5, 'low': 9.0},
        {'high': 10.0, 'low': 8.0},
      ];

      final gaps = detectFairValueGaps(candles);

      expect(gaps, hasLength(1));
      expect(gaps.first.direction, 'BULLISH');
      expect(gaps.first.top, 12.0);
      expect(gaps.first.bottom, 10.0);
      expect(gaps.first.gapSize, 2.0);
      expect(gaps.first.filled, false);
    });


    test('detects bearish FVG', () {
      final candles = [
        {'high': 8.0, 'low': 6.0},
        {'high': 11.0, 'low': 7.0},
        {'high': 12.0, 'low': 10.0},
      ];

      final gaps = detectFairValueGaps(candles);

      expect(gaps, hasLength(1));
      expect(gaps.first.direction, 'BEARISH');
      expect(gaps.first.top, 10.0);
      expect(gaps.first.bottom, 8.0);
      expect(gaps.first.gapSize, 2.0);
      expect(gaps.first.filled, false);
    });


    test('detects fully filled bullish FVG', () {
      final candles = [
        {'high': 13.0, 'low': 9.5},
        {'high': 14.0, 'low': 12.0},
        {'high': 11.5, 'low': 9.0},
        {'high': 10.0, 'low': 8.0},
      ];

      final gaps = detectFairValueGaps(candles);

      expect(gaps, hasLength(1));
      expect(gaps.first.direction, 'BULLISH');
      expect(gaps.first.filled, true);
    });


    test('returns empty when no FVG exists', () {
      final candles = [
        {'high': 12.0, 'low': 10.0},
        {'high': 11.0, 'low': 9.0},
        {'high': 10.5, 'low': 8.0},
      ];

      final gaps = detectFairValueGaps(candles);

      expect(gaps, isEmpty);
    });
    test('ignores invalid candle data safely', () {
      final candles = [
        {'high': 8.0, 'low': 12.0},
        {'high': 11.0, 'low': 7.0},
        {'high': 12.0, 'low': 10.0},
      ];

      final gaps = detectFairValueGaps(candles);

      expect(gaps, isEmpty);
    });

  });
}
