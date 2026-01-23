/// Application configuration constants
class AppConfig {
  // Network Configuration
  static const int apiPort = 5000;
  static const int pollingIntervalMs = 800; // 0.8 seconds
  static const int connectionTimeoutSeconds = 2;
  
  // Default IP Configuration (for Smart Mode)
  static const String defaultIpPrefix = '192.168';
  static const String defaultIpSuffix = '166';
  
  // SharedPreferences Keys
  static const String savedIpKey = 'saved_ip';
  
  // UI Configuration
  static const String appTitle = 'Smart Bakery Monitor';
  static const String appBarTitle = '🍓 Smart Bakery';
  
  /// Build base URL from IP address
  static String buildBaseUrl(String ip) => 'http://$ip:$apiPort';
  
  /// Check if IP matches smart format (192.168.XXX.166)
  static bool isSmartFormat(String ip) {
    final parts = ip.split('.');
    return parts.length == 4 &&
        parts[0] == '192' &&
        parts[1] == '168' &&
        parts[3] == defaultIpSuffix;
  }
  
  /// Extract middle part from smart format IP
  static String? extractSmartPart(String ip) {
    if (!isSmartFormat(ip)) return null;
    return ip.split('.')[2];
  }
  
  /// Build IP from smart format
  static String buildSmartIp(String middlePart) {
    return '$defaultIpPrefix.$middlePart.$defaultIpSuffix';
  }
}
