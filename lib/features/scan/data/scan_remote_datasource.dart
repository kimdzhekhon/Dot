import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dot/core/network/dio_client.dart';
import 'package:dot/core/network/network_exception.dart';
import 'package:dot/core/constants/global_config.dart';

class ScanRemoteDataSource {
  final DioClient _dioClient;
  final SupabaseClient _supabaseClient;

  ScanRemoteDataSource(this._dioClient, this._supabaseClient);

  /// 1. Fetch Keys from Edge Function
  Future<void> fetchSecureKeys() async {
    try {
      final response = await _supabaseClient.functions.invoke('get-secure-keys');
      final data = response.data;
      if (data != null) {
        GlobalConfig.googleKey = data['google'];
        GlobalConfig.vtKey = data['virustotal'];
      }
    } catch (e) {
      throw NetworkException(message: "Failed to fetch secure keys: $e");
    }
  }

  /// 2. Google Safe Browsing API (v4)
  Future<Map<String, dynamic>> checkGoogleSafeBrowsing(String url) async {
    if (GlobalConfig.googleKey == null) await fetchSecureKeys();

    try {
      final response = await _dioClient.post(
        'https://safebrowsing.googleapis.com/v4/threatMatches:find',
        queryParameters: {'key': GlobalConfig.googleKey},
        data: {
          "client": {
            "clientId": "dot-app", 
            "clientVersion": "1.0.0"
          },
          "threatInfo": {
            "threatTypes": ["MALWARE", "SOCIAL_ENGINEERING", "UNWANTED_SOFTWARE"],
            "platformTypes": ["ANY_PLATFORM"],
            "threatEntryTypes": ["URL"],
            "threatEntries": [
              {"url": url}
            ]
          }
        },
      );
      // If empty object returned, it means safe.
      return response.data ?? {}; 
    } catch (e) {
      // Fail silently for Vibe (or log)
      return {};
    }
  }

  /// 3. VirusTotal API
  Future<Map<String, dynamic>> scanUrlVt(String url) async {
    if (GlobalConfig.vtKey == null) await fetchSecureKeys();
    
    try {
      // Helper to base64 encode URL for VT
      // ...
      // For now returning mock
      return {'positives': 0, 'total': 90};
    } catch (e) {
      return {};
    }
  }

  /// 4. Calculate Score (RPC)
  Future<int> calculateDotScore({
    required String message,
    required Map<String, dynamic> googleResult,
    required Map<String, dynamic> vtResult,
    String? url,
  }) async {
    try {
      final score = await _supabaseClient.rpc('calculate_dot_score', params: {
        'msg_body': message,
        'google_raw': googleResult,
        'vt_raw': vtResult,
        'target_url': url,
      });
      return score as int;
    } catch (e) {
      throw NetworkException(message: "Score calculation failed: $e");
    }
  }
}
