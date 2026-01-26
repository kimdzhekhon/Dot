import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dot/core/network/dio_client.dart';
import 'package:dot/core/network/network_exception.dart';
import 'package:dot/core/constants/global_config.dart';
import 'package:dot/features/scan/data/onnx_embedding_service.dart';

class ScanRemoteDataSource {
  final DioClient _dioClient;
  final SupabaseClient _supabaseClient;
  final OnnxEmbeddingService _onnxService = OnnxEmbeddingService();

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

  /// 7. Analyze Spam Message (Hybrid: Text + AI)
  Future<Map<String, dynamic>> analyzeSpamMessage(String text) async {
    debugPrint('🔍 [ScanRemoteDataSource] analyzeSpamMessage (Hybrid) started. text: "$text"');
    try {
      // 1. Stage 1: Text-based Search (High accuracy for literal matches)
      if (text.length >= 5) {
        debugPrint('⏳ [ScanRemoteDataSource] Stage 1: Text Search...');
        try {
          final textResults = await _supabaseClient.rpc('search_spam_text', params: {
            'p_query_text': text,
          });
          
          if (textResults is List && textResults.isNotEmpty) {
            final bestText = textResults[0];
            final textSim = (bestText['similarity'] as num).toDouble();
            debugPrint('🔍 [ScanRemoteDataSource] Text Similarity: $textSim');
            
            // If text is 80% similar, flag immediately
            if (textSim > 0.8) {
              debugPrint('🚨 [ScanRemoteDataSource] Spam Match (Stage 1 - Text)!');
              return {
                'is_spam': true, 
                'similarity': textSim, 
                'matched_content': bestText['content']
              };
            }
          }
        } catch (e) {
          debugPrint('⚠️ [ScanRemoteDataSource] Text search failed: $e');
        }
      }

      // 2. Stage 2: AI Embedding Search (Semantic matching)
      debugPrint('⏳ [ScanRemoteDataSource] Stage 2: AI Embedding Search...');
      final embedding = await _onnxService.getEmbedding('query: $text');
      
      final response = await _supabaseClient.rpc('match_messages', params: {
        'query_embedding': embedding,
        'match_threshold': 0.1, // Raw score for heuristic
        'match_count': 1,
      });

      final List<dynamic> data = response as List<dynamic>;
      if (data.isNotEmpty) {
        final bestMatch = data[0];
        final aiSim = (bestMatch['similarity'] as num).toDouble();
        debugPrint('🔍 [ScanRemoteDataSource] Best match similarity (AI): $aiSim');
        
        // Logical Heuristics to prevent false positives for short text:
        // 1. Definitely Spam: Score is exceptionally high (>= 0.93)
        // 2. Likely Spam: Score is high (>= 0.88) AND text is long (> 10)
        // 3. Short False Positive (like '123123'): Length <= 10 and Score < 0.93 -> Ignored
        
        if (aiSim >= 0.93 || (aiSim >= 0.88 && text.length > 10)) {
            debugPrint('🚨 [ScanRemoteDataSource] Spam Match (Stage 2 - AI)!');
            return {
              'is_spam': true, 
              'similarity': aiSim, 
              'matched_content': bestMatch['content']
            };
        }
      }

      debugPrint('✅ [ScanRemoteDataSource] No spam match found below threshold or length rule.');
      return {'is_spam': false};

    } catch (e) {
      debugPrint('❌ [ScanRemoteDataSource] analyzeSpamMessage failed: $e');
      return {'is_spam': false, 'error': e.toString()};
    }
  }
}
