import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bakery_status.dart';

/// Service class responsible for all API communication with the Smart Bakery backend
class BakeryService {
  final String ipAddress;

  BakeryService({required this.ipAddress});

  /// Base URL for API requests
  String get baseUrl => 'http://$ipAddress:5000';

  /// Fetches the current status of all sensors and devices
  /// 
  /// Returns a [BakeryStatus] object with the current data
  /// Throws an exception if the request fails or times out
  Future<BakeryStatus> fetchStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/status'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        return BakeryStatus.fromJson(jsonData);
      } else {
        throw Exception('Failed to fetch status: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  /// Sends a control command to a specific device
  /// 
  /// [device] - The device to control (e.g., 'fan', 'buzzer', 'silent_mode')
  /// [mode] - The mode to set (e.g., 'AUTO', 'ON', 'OFF')
  /// 
  /// Throws an exception if the command fails to send
  Future<void> sendCommand(String device, String mode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/control'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"device": device, "mode": mode}),
      );

      if (response.statusCode != 200) {
        throw Exception('Command failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to send command: $e');
    }
  }
}
