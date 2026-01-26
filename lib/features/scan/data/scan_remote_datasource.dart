import 'dart:convert';
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
        final keys = data['keys'] as Map<String, dynamic>?;
        if (keys != null) {
          GlobalConfig.googleKey = keys['google_key'];
          GlobalConfig.whoisKey = keys['whois_key'];
        }
      }
    } catch (e) {
      throw NetworkException(message: "Failed to fetch secure keys: $e");
    }
  }

  /// 2. Google Safe Browsing API (v4)
  Future<Map<String, dynamic>> checkGoogleSafeBrowsing(String url) async {
    // Use single Consolidated Key
    String? googleKey = GlobalConfig.googleKey;
    
    // If key missing, try fetch
    if (googleKey == null) {
       await fetchSecureKeys();
       googleKey = GlobalConfig.googleKey;
    }

    if (googleKey == null) return {};

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



  /// 4. Calculate Score (RPC)
  Future<int> calculateDotScore({
    required String message,
    required Map<String, dynamic> googleResult,
    String? url,
  }) async {
    try {
      final score = await _supabaseClient.rpc('calculate_dot_score', params: {
        'msg_body': message,
        'google_raw': googleResult,
        'vt_raw': {}, // Always empty as VT is removed from client
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

  /// 6. Check Web List (RPC)
  Future<Map<String, dynamic>> checkWebList(String url) async {
    try {
      final response = await _supabaseClient.rpc('check_web_list', params: {
        'p_url': url,
      });
      return response as Map<String, dynamic>;
    } catch (e) {
      // Return empty/not-found to allow fallback to other scanner APIs
      return {'found': false, 'status': 'none'};
    }
  }

  Future<Map<String, dynamic>> checkWhois(String url) async {
    // 1. Get Key
    if (GlobalConfig.whoisKey == null) await fetchSecureKeys();
    final whoisKey = GlobalConfig.whoisKey;

    if (whoisKey == null) return {};

    try {
      // 2. Extract Domain 
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      final host = uri.host;

      // KISA Public Data Portal API only supports .kr / .한국 domains
      // Skip API call for .com, .net, etc. to avoid 031 error
      if (!host.endsWith('.kr') && !host.endsWith('.한국')) {
        return {};
      }
      
      // 3. Call KISA WHOIS API (via Public Data Portal)
      // User has a Public Data Portal key, so we must use the data.go.kr endpoint
      // Endpoint: https://apis.data.go.kr/B551505/whois/domain_name
      final requestUrl = 'https://apis.data.go.kr/B551505/whois/domain_name?serviceKey=$whoisKey&query=$host&answer=json';
      
      final response = await _dioClient.get(requestUrl);
      var responseData = response.data;

      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          // Ignore
        }
      }

      if (responseData is Map<String, dynamic> && responseData['whois'] != null) {
         final whoisData = responseData['whois'];
         
         // Check for API error (e.g., 031 for .com domains)
         if (whoisData['error'] != null) {
            return {};
         }
         return whoisData;
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
