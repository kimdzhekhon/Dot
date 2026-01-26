import 'dart:convert';
import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dot/core/network/dio_client.dart';
import 'package:dot/core/network/network_exception.dart';
import 'package:dot/core/constants/global_config.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ScanRemoteDataSource {
  final DioClient _dioClient;
  final SupabaseClient _supabaseClient;

  ScanRemoteDataSource(this._dioClient, this._supabaseClient);

  /// 1. Fetch Keys from Edge Function
  Future<void> fetchSecureKeys() async {
    try {
      final response = await _supabaseClient.functions.invoke('auth-init');
      final data = response.data;
      if (data != null && data['keys'] != null) {
        final keys = data['keys'] as Map<String, dynamic>;
        GlobalConfig.googleKey = keys['google_key'];
        GlobalConfig.whoisKey = keys['whois_key'];
        GlobalConfig.geminiKey = keys['gemini_key'];
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

  /// 7. Analyze Spam Message (Local w/ Gemini API)
  Future<Map<String, dynamic>> analyzeSpamMessage(String text) async {
    print('🔍 [ScanRemoteDataSource] analyzeSpamMessage started. text length: ${text.length}');
    try {
      // 1. Get Key
      if (GlobalConfig.geminiKey == null) {
         print('⚠️ [ScanRemoteDataSource] geminiKey is null. Attempting fallback or check.');
      }
      final apiKey = GlobalConfig.geminiKey ?? GlobalConfig.googleKey; 
      
      if (apiKey == null) {
         print('❌ [ScanRemoteDataSource] API Key Missing! Cannot proceed with Gemini analysis.');
         return {'is_spam': false, 'error': 'Missing API Key'};
      }
      print('✅ [ScanRemoteDataSource] API Key found. Initializing GenerativeModel...');

      // 2. Generate Embedding Locally
      final model = GenerativeModel(model: 'text-embedding-004', apiKey: apiKey);
      final content = Content.text(text);
      
      print('⏳ [ScanRemoteDataSource] Calling Gemini API (embedContent)...');
      final embeddingResult = await model.embedContent(content);
      final embedding = embeddingResult.embedding.values;
      print('✅ [ScanRemoteDataSource] Embedding generated. Vector dimension: ${embedding.length}');

      // 3. Search via RPC (match_messages)
      print('⏳ [ScanRemoteDataSource] Calling Supabase RPC: match_messages...');
      final response = await _supabaseClient.rpc('match_messages', params: {
        'query_embedding': embedding,
        'match_threshold': 0.0, // Debugging: Lower threshold to see what matches
        'match_count': 5, // Get top 5
      });
      print('✅ [ScanRemoteDataSource] RPC Response received: $response');

      final List<dynamic> data = response as List<dynamic>;

      if (data.isNotEmpty) {
        final bestMatch = data[0];
        print('🚨 [ScanRemoteDataSource] Spam Match Found! Similarity: ${bestMatch['similarity']}');
        return {
          'is_spam': true,
          'similarity': bestMatch['similarity'],
          'matched_content': bestMatch['content'],
        };
      }

      print('✅ [ScanRemoteDataSource] No spam match found above threshold.');
      return {'is_spam': false};

    } catch (e) {
      print('❌ [ScanRemoteDataSource] Error in analyzeSpamMessage: $e');
      return {'is_spam': false, 'error': e.toString()};
    }
  }
}
