import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiKeyService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'twelve_data_api_key';

  Future<void> saveApiKey(String apiKey) async {
    await _storage.write(
      key: _keyName,
      value: apiKey.trim(),
    );
  }

  Future<String?> getApiKey() async {
    return _storage.read(key: _keyName);
  }

  Future<void> deleteApiKey() async {
    await _storage.delete(key: _keyName);
  }
}
