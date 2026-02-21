import 'package:http/http.dart' as http;

/// Simplified NetworkScanner using pure brute-force strategy
/// Scans 192.168.0.166 through 192.168.255.166 (256 IPs)
/// No permissions, no NetworkInterface detection - just raw scanning
class NetworkScanner {
  static const int _timeout = 1; // seconds
  static const int _batchSize = 64; // High concurrency for fast scanning
  static const String _targetSuffix = '.166';
  static const int _port = 5000;

  /// Brute force scan all possible 192.168.X.166 addresses
  /// Returns the first responsive IP or null if all fail
  /// Completes in ~4-5 seconds with 64 concurrent requests
  static Future<String?> scanNetwork() async {
    final List<String> targets = _generateTargets();

    // Process in batches for high concurrency
    for (int i = 0; i < targets.length; i += _batchSize) {
      final batch = targets.sublist(
        i,
        i + _batchSize > targets.length ? targets.length : i + _batchSize,
      );

      // Scan batch concurrently
      final result = await _scanBatch(batch);
      if (result != null) {
        return result; // Return immediately when found
      }
    }

    return null; // No device found after all 256 attempts
  }

  /// Generate 256 target IPs: 192.168.0.166 to 192.168.255.166
  static List<String> _generateTargets() {
    final List<String> targets = [];
    for (int subnet = 0; subnet <= 255; subnet++) {
      targets.add('192.168.$subnet$_targetSuffix');
    }
    return targets;
  }

  /// Scan a batch of IPs concurrently
  /// Returns first successful IP or null
  static Future<String?> _scanBatch(List<String> ips) async {
    final futures = ips.map((ip) => _checkIp(ip));
    final results = await Future.wait(futures);

    // Return first successful IP
    for (int i = 0; i < results.length; i++) {
      if (results[i]) {
        return ips[i];
      }
    }

    return null;
  }

  /// Check if a single IP is responsive
  /// Tests HTTP endpoint with 1 second timeout
  static Future<bool> _checkIp(String ip) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ip:$_port/api/status'))
          .timeout(Duration(seconds: _timeout));

      return response.statusCode == 200;
    } catch (e) {
      return false; // Timeout or connection error
    }
  }
}
