import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String _keyTableCounts = 'table_counts';
  static const String _keyGoogleAndroid = 'google_android_key';
  static const String _keyGoogleIos = 'google_ios_key';
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
    required String? googleAndroid,
    required String? googleIos,
    required String? whoisKey,
  }) async {
    if (googleAndroid != null) await _storage.write(key: _keyGoogleAndroid, value: googleAndroid);
    if (googleIos != null) await _storage.write(key: _keyGoogleIos, value: googleIos);
    if (whoisKey != null) await _storage.write(key: _keyWhoisKey, value: whoisKey);
  }

  Future<String?> getGoogleAndroidKey() => _storage.read(key: _keyGoogleAndroid);
  Future<String?> getGoogleIosKey() => _storage.read(key: _keyGoogleIos);
  Future<String?> getWhoisKey() => _storage.read(key: _keyWhoisKey);
}

final secureStorageProvider = Provider((ref) => SecureStorageService());
