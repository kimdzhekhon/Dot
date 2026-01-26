class GlobalConfig {
  // In-memory storage for keys fetched from Edge Function
  // Never persisted to disk
  static String? googleKeyAndroid;
  static String? googleKeyIos;
  static String? whoisKey;

  static bool get hasKeys => (googleKeyAndroid != null || googleKeyIos != null) && whoisKey != null;
}
