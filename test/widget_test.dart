import 'package:flutter_test/flutter_test.dart';
import 'package:forex_ai_analyzer/main.dart';

void main() {
  testWidgets('Forex AI Analyzer app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const ForexAIAnalyzerApp());
    await tester.pump();

    expect(find.byType(AnalyzerHome), findsOneWidget);
  });
}
