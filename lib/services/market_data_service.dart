import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_key_service.dart';

class MarketDataService {
  static const String baseUrl = 'https://api.twelvedata.com';

  final ApiKeyService _apiKeyService = ApiKeyService();

  Future<Map<String, dynamic>> getQuote(String symbol) async {
    final apiKey = await _apiKeyService.getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Twelve Data API key is not saved');
    }

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


  Future<Map<String, dynamic>> getTimeSeries(
    String symbol, {
    String interval = '15min',
    int outputsize = 100,
  }) async {
    final apiKey = await _apiKeyService.getApiKey();

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Twelve Data API key is not saved');
    }

    final uri = Uri.parse(
      '$baseUrl/time_series?symbol=${Uri.encodeComponent(symbol)}'
      '&interval=$interval'
      '&outputsize=$outputsize'
      '&apikey=$apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Candlestick request failed: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid candlestick response');
    }

    if (decoded['status'] == 'error') {
      throw Exception(
        decoded['message']?.toString() ?? 'Candlestick API error',
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
