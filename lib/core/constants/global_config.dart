class GlobalConfig {
  // In-memory storage for keys fetched from Edge Function
  // Never persisted to disk
  static String? googleKey;
  static String? vtKey;

  static bool get hasKeys => googleKey != null && vtKey != null;
}
