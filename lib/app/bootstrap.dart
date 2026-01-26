import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dot/core/security/secure_storage_service.dart';
import 'package:dot/core/constants/global_config.dart';

final bootstrapProvider = FutureProvider<void>((ref) async {
  final supabase = Supabase.instance.client;
  final secureStorage = ref.read(secureStorageProvider);

  try {
    // 1. Invoke auth-init Edge Function
    final response = await supabase.functions.invoke('auth-init');
    final data = response.data;

    if (data != null) {
      // 2. Extract Data
      final keys = data['keys'] as Map<String, dynamic>?;
      final counts = data['counts'] as Map<String, dynamic>?;

      if (keys != null) {
        // 3. Save Keys to SecureStorage
        await secureStorage.saveSecureKeys(
          googleAndroid: keys['google_android'],
          googleIos: keys['google_ios'],
          whoisKey: keys['whois_key'],
        );

        // 4. Update Memory Config (GlobalConfig)
        GlobalConfig.googleKeyAndroid = keys['google_android'];
        GlobalConfig.googleKeyIos = keys['google_ios'];
        GlobalConfig.whoisKey = keys['whois_key'];
      }

      if (counts != null) {
        // 5. Save Table Counts to SecureStorage
        await secureStorage.saveTableCounts(counts);
      }
    }
  } catch (e) {
    // Log error, but allow app to proceed if possible
    print('Bootstrap Error: $e');
    
    // Attempt to load existing keys from storage if function fails
    GlobalConfig.googleKeyAndroid = await secureStorage.getGoogleAndroidKey();
    GlobalConfig.googleKeyIos = await secureStorage.getGoogleIosKey();
    GlobalConfig.whoisKey = await secureStorage.getWhoisKey();
  }
});
