class GlobalConfig {
  // In-memory storage for keys fetched from Edge Function
  // Never persisted to disk
  static String? googleKey;
  static String? whoisKey;
  static String? geminiKey;

  static bool get hasKeys => googleKey != null && whoisKey != null;
}
