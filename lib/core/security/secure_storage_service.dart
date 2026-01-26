import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyTableCounts = 'table_counts';
  static const String _keyGoogleKey = 'google_api_key';
  static const String _keyWhoisKey = 'whois_api_key';

  Future<void> saveTableCounts(Map<String, dynamic> counts) async {
    await _storage.write(key: _keyTableCounts, value: jsonEncode(counts));
  }

  Future<Map<String, dynamic>> getTableCounts() async {
    final value = await _storage.read(key: _keyTableCounts);
    if (value == null) return {};
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<void> saveSecureKeys({
    required String? googleKey,
    required String? whoisKey,
  }) async {
    if (googleKey != null) await _storage.write(key: _keyGoogleKey, value: googleKey);
    if (whoisKey != null) await _storage.write(key: _keyWhoisKey, value: whoisKey);
  }

  Future<String?> getGoogleKey() => _storage.read(key: _keyGoogleKey);
  Future<String?> getWhoisKey() => _storage.read(key: _keyWhoisKey);
}

final secureStorageProvider = Provider((ref) => SecureStorageService());
