import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class NetworkScanner {
  static const int _port = 80;
  static const int _connectionTimeoutMs = 500;
  static const int _maxConcurrentScans = 50;
  static const int _preferredSuffix = 166; // Pi's preferred IP suffix

  /// Scan the local network for devices running the bakery service
  /// Uses subnet-based scanning with priority check for .166
  /// Returns the IP address of the first device found, or null if none found
  static Future<String?> scanNetwork({
    required Function(String progress) onProgress,
  }) async {
    try {
      // Request permissions first (Android only)
      final hasPermission = await _requestPermissions();
      if (!hasPermission) {
        throw Exception("Network scanning permissions denied");
      }

      onProgress("检测本地网络...");
      
      // Get device's local IP using native NetworkInterface
      final deviceIp = await _getDeviceIp();
      if (deviceIp == null) {
        throw Exception("无法获取设备 IP 地址，请检查网络连接");
      }

      onProgress("设备 IP: $deviceIp");
      debugPrint("Device IP: $deviceIp");

      // Extract subnet from device IP (e.g., "192.168.43" from "192.168.43.5")
      final parts = deviceIp.split('.');
      if (parts.length != 4) {
        throw Exception("Invalid IP format: $deviceIp");
      }
      final subnet = "${parts[0]}.${parts[1]}.${parts[2]}";

      onProgress("扫描网段: $subnet.0/24");
      debugPrint("Scanning subnet: $subnet.0/24");

      // CRUCIAL: Check .166 FIRST before scanning the rest
      final preferredIp = "$subnet.$_preferredSuffix";
      onProgress("优先检查: $preferredIp");
      debugPrint("Priority check: $preferredIp");
      
      final preferredExists = await _scanSingleHost(preferredIp);
      if (preferredExists) {
        onProgress("✓ 找到设备: $preferredIp");
        debugPrint("Device found at preferred IP: $preferredIp");
        return preferredIp;
      }

      // If .166 not found, scan the rest of the subnet
      onProgress("扫描其他主机...");
      debugPrint("Scanning remaining hosts in subnet");

      final completer = Completer<String?>();
      int completedScans = 0;
      int activeScans = 0;
      int totalScans = 255;
      bool foundDevice = false;

      // Scan hosts 1-255 (excluding .166 as already checked)
      for (int hostNum = 1; hostNum <= 255; hostNum++) {
        if (foundDevice) break;

        final targetIp = "$subnet.$hostNum";
        
        // Skip the device's own IP and the already-checked .166
        if (targetIp == deviceIp || hostNum == _preferredSuffix) {
          completedScans++;
          continue;
        }

        // Control concurrency - wait if too many active scans
        while (activeScans >= _maxConcurrentScans && !foundDevice) {
          await Future.delayed(const Duration(milliseconds: 10));
        }

        if (foundDevice) break;

        // Launch concurrent scan
        activeScans++;
        _scanSingleHost(targetIp).then((isReachable) {
          activeScans--;
          completedScans++;
          
          if (isReachable && !foundDevice) {
            foundDevice = true;
            onProgress("✓ 找到设备: $targetIp");
            debugPrint("Device found at: $targetIp");
            if (!completer.isCompleted) {
              completer.complete(targetIp);
            }
          }

          // Update progress every 20 scans
          if (completedScans % 20 == 0) {
            onProgress("扫描进度: $completedScans/$totalScans");
          }

          // If all scans complete without finding device
          if (completedScans >= totalScans && !foundDevice && !completer.isCompleted) {
            completer.complete(null);
          }
        }).catchError((e) {
          activeScans--;
          completedScans++;
          if (completedScans >= totalScans && !foundDevice && !completer.isCompleted) {
            completer.complete(null);
          }
        });
      }

      // Wait for scan to complete or timeout
      return await completer.future.timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          onProgress("扫描超时");
          debugPrint("Scan timeout");
          return null;
        },
      );

    } catch (e) {
      debugPrint("Network scan error: $e");
      rethrow;
    }
  }

  /// Get the device's local IP address using native NetworkInterface
  /// Looks for IPv4 addresses in private network ranges (192.x, 172.x, 10.x)
  static Future<String?> _getDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          final ip = addr.address;
          
          // Check if IP is in private network ranges
          if (_isPrivateIpv4(ip)) {
            debugPrint("Found private IP on ${interface.name}: $ip");
            return ip;
          }
        }
      }

      debugPrint("No private IPv4 address found");
      return null;
    } catch (e) {
      debugPrint("Error getting device IP: $e");
      return null;
    }
  }

  /// Check if an IPv4 address is in a private network range
  /// Returns true for IPs starting with 192, 172 (16-31), or 10
  static bool _isPrivateIpv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    try {
      final first = int.parse(parts[0]);
      final second = int.parse(parts[1]);

      // 192.168.x.x
      if (first == 192 && second == 168) return true;

      // 172.16.x.x - 172.31.x.x
      if (first == 172 && second >= 16 && second <= 31) return true;

      // 10.x.x.x
      if (first == 10) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Scan a single host to check if bakery service is running
  static Future<bool> _scanSingleHost(String ip) async {
    try {
      final response = await http
          .get(
            Uri.parse("http://$ip:$_port/status"),
          )
          .timeout(
            Duration(milliseconds: _connectionTimeoutMs),
          );

      // Check if response is successful and contains expected data
      return response.statusCode == 200 && response.body.contains("temperature");
    } catch (e) {
      return false;
    }
  }

  /// Request necessary permissions for network scanning (Android)
  static Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;

    Map<Permission, PermissionStatus> statuses = {};

    List<Permission> permissionsToRequest = [];

    // Android 13+ needs this permission to scan WiFi
    permissionsToRequest.add(Permission.nearbyWifiDevices);
    
    // All Android versions need location permission for WiFi scanning
    permissionsToRequest.add(Permission.locationWhenInUse); 

    statuses = await permissionsToRequest.request();

    // Check results: if any key permission is granted, we can try scanning
    bool isNearbyGranted = statuses[Permission.nearbyWifiDevices]?.isGranted ?? false;
    bool isLocationGranted = statuses[Permission.locationWhenInUse]?.isGranted ?? false;

    if (isNearbyGranted || isLocationGranted) {
      return true;
    }

    debugPrint("Permissions denied, trying to open settings...");
    return false;
  }
}