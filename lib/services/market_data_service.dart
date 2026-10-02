import 'dart:convert';

import 'package:http/http.dart' as http;

class MarketDataService {
  static const String baseUrl = 'https://api.twelvedata.com';
  static const String apiKey = 'YOUR_API_KEY';

  Future<Map<String, dynamic>> getQuote(String symbol) async {
    final uri = Uri.parse(
      '$baseUrl/quote?symbol=${Uri.encodeComponent(symbol)}&apikey=$apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Market data request failed: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid market data response');
    }

    if (decoded['status'] == 'error') {
      throw Exception(
        decoded['message']?.toString() ?? 'Market data API error',
      );
    }

    return decoded;
  }

  Future<Map<String, dynamic>> getGoldQuote() {
    return getQuote('XAU/USD');
  }

  Future<Map<String, dynamic>> getForexQuote(String pair) {
    return getQuote(pair);
  }
}
