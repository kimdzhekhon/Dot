import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dot/core/constants/global_config.dart';
import 'package:dot/features/scan/presentation/scan_providers.dart';

final bootstrapProvider = FutureProvider<void>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    print('Bootstrap: Starting initialization (Memory-only flow)...');
    // 1. Invoke auth-init Edge Function
    final response = await supabase.functions.invoke('auth-init');
    print('Bootstrap: Function response status: ${response.status}');
    
    final data = response.data;
    print('Bootstrap: Raw response data: $data');

    if (data != null && data['status'] == 'success') {
      // 2. Extract Data
      final keys = data['keys'] as Map<String, dynamic>?;
      final counts = data['counts'] as Map<String, dynamic>?;

      if (keys != null) {
        print('Bootstrap: Keys received. Updating GlobalConfig...');
        final googleKey = keys['google_key'];
        // Update Memory Config (GlobalConfig)
        GlobalConfig.googleKey = googleKey;
        GlobalConfig.whoisKey = keys['whois_key'];
        GlobalConfig.geminiKey = keys['gemini_key'];
      }

      if (counts != null) {
        print('Bootstrap: Counts received: $counts. Updating tableCountsProvider...');
        final parsedCounts = <String, int>{};
        counts.forEach((key, value) {
          if (value is num) {
            parsedCounts[key] = value.toInt();
          } else if (value is String) {
            parsedCounts[key] = int.tryParse(value) ?? 0;
          } else {
            parsedCounts[key] = 0;
          }
        });

        // Update Table Counts Provider
        ref.read(tableCountsProvider.notifier).state = parsedCounts;
      }
    } else {
      print('Bootstrap: Function returned error or invalid data: ${data?['error']}');
    }
  } catch (e) {
    print('Bootstrap Error: $e');
    // On error, the app will continue with null keys/empty counts
  }
});
