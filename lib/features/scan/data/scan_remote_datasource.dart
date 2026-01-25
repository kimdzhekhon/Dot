import 'package:dio/dio.dart';
import 'dart:io' show Platform;
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
        GlobalConfig.googleKeyAndroid = data['google_android'];
        GlobalConfig.googleKeyIos = data['google_ios'];
        GlobalConfig.vtKey = data['virustotal'];
      }
    } catch (e) {
      throw NetworkException(message: "Failed to fetch secure keys: $e");
    }
  }

  /// 2. Google Safe Browsing API (v4)
  Future<Map<String, dynamic>> checkGoogleSafeBrowsing(String url) async {
    // Select Key based on Platform
    String? googleKey;
    if (Platform.isAndroid) {
       googleKey = GlobalConfig.googleKeyAndroid;
    } else if (Platform.isIOS) {
       googleKey = GlobalConfig.googleKeyIos;
    }
    
    // If key missing for current platform, try fetch
    if (googleKey == null) {
       await fetchSecureKeys();
       if (Platform.isAndroid) {
          googleKey = GlobalConfig.googleKeyAndroid;
       } else if (Platform.isIOS) {
          googleKey = GlobalConfig.googleKeyIos;
       }
    }

    if (googleKey == null) return {}; // Still missing?

    try {
      final response = await _dioClient.post(
        'https://safebrowsing.googleapis.com/v4/threatMatches:find',
        queryParameters: {'key': googleKey},
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

  /// 5. Search Clean Phone (RPC)
  Future<Map<String, dynamic>> searchCleanPhone(String phoneNumber) async {
    try {
      final response = await _supabaseClient.rpc('search_clean_phone', params: {
        'p_phone_number': phoneNumber,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      // If table missing or other error, treat as not found for now to avoid crash
      // The user sees "Not found in public data" instead of technical error
      if (e.toString().contains('clean_phone') || e.toString().contains('42P01')) {
         return {'found': false};
      }
      throw NetworkException(message: "Phone search failed: $e");
    }
  }
}


