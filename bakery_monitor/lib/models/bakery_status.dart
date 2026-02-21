/// Model class representing the current status of the bakery sensors and devices
class BakeryStatus {
  final double temperature;
  final double humidity;
  final String fanState;
  final String buzzerState;
  final String fanMode;
  final String buzzerMode;
  final String silentMode;

  BakeryStatus({
    required this.temperature,
    required this.humidity,
    required this.fanState,
    required this.buzzerState,
    required this.fanMode,
    required this.buzzerMode,
    required this.silentMode,
  });

  /// Factory constructor to create a BakeryStatus instance from JSON
  factory BakeryStatus.fromJson(Map<String, dynamic> json) {
    return BakeryStatus(
      temperature: (json['temperature'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      fanState: json['fan_state'] ?? '--',
      buzzerState: json['buzzer_state'] ?? '--',
      fanMode: json['fan_mode'] ?? 'AUTO',
      buzzerMode: json['buzzer_mode'] ?? 'AUTO',
      silentMode: json['silent_mode'] ?? 'ON',
    );
  }

  /// Factory constructor for creating a default/empty status
  factory BakeryStatus.empty() {
    return BakeryStatus(
      temperature: 0.0,
      humidity: 0.0,
      fanState: '--',
      buzzerState: '--',
      fanMode: 'AUTO',
      buzzerMode: 'AUTO',
      silentMode: 'ON',
    );
  }

  /// Create a copy of this status with some fields updated
  BakeryStatus copyWith({
    double? temperature,
    double? humidity,
    String? fanState,
    String? buzzerState,
    String? fanMode,
    String? buzzerMode,
    String? silentMode,
  }) {
    return BakeryStatus(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      fanState: fanState ?? this.fanState,
      buzzerState: buzzerState ?? this.buzzerState,
      fanMode: fanMode ?? this.fanMode,
      buzzerMode: buzzerMode ?? this.buzzerMode,
      silentMode: silentMode ?? this.silentMode,
    );
  }
}
