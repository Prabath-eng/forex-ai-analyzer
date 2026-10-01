import 'package:flutter/material.dart';

void main() {
  runApp(const ForexAIAnalyzer());
}

class ForexAIAnalyzer extends StatelessWidget {
  const ForexAIAnalyzer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Forex AI Analyzer',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Forex AI Analyzer'),
        ),
        body: const Center(
          child: Text(
            'Forex & Gold AI Analyzer',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}