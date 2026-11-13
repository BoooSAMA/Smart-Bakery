import 'package:flutter_test/flutter_test.dart';

import 'package:bakery_monitor/config/app_config.dart';
import 'package:bakery_monitor/models/bakery_status.dart';

void main() {
  group('BakeryStatus', () {
    test('fromJson parses a full backend payload', () {
      final status = BakeryStatus.fromJson({
        'temperature': 32.5,
        'humidity': 61,
        'fan_state': 'ON',
        'buzzer_state': 'OFF',
        'fan_mode': 'MANUAL',
        'buzzer_mode': 'AUTO',
        'silent_mode': 'OFF',
      });

      expect(status.temperature, 32.5);
      expect(status.humidity, 61.0);
      expect(status.fanState, 'ON');
      expect(status.buzzerState, 'OFF');
      expect(status.fanMode, 'MANUAL');
      expect(status.buzzerMode, 'AUTO');
      expect(status.silentMode, 'OFF');
    });

    test('fromJson falls back to defaults on missing keys', () {
      final status = BakeryStatus.fromJson({});

      expect(status.temperature, 0.0);
      expect(status.humidity, 0.0);
      expect(status.fanState, '--');
      expect(status.buzzerState, '--');
      expect(status.fanMode, 'AUTO');
      expect(status.buzzerMode, 'AUTO');
      expect(status.silentMode, 'ON');
    });

    test('copyWith only overrides provided fields', () {
      final base = BakeryStatus.empty();
      final updated = base.copyWith(temperature: 40.0, fanState: 'ON');

      expect(updated.temperature, 40.0);
      expect(updated.fanState, 'ON');
      expect(updated.humidity, base.humidity);
      expect(updated.silentMode, base.silentMode);
    });
  });

  group('AppConfig', () {
    test('buildBaseUrl targets the backend port', () {
      expect(AppConfig.buildBaseUrl('192.168.1.166'), 'http://192.168.1.166:5000');
    });

    test('isSmartFormat accepts 192.168.X.166 only', () {
      expect(AppConfig.isSmartFormat('192.168.1.166'), isTrue);
      expect(AppConfig.isSmartFormat('192.168.255.166'), isTrue);
      expect(AppConfig.isSmartFormat('192.168.1.1'), isFalse);
      expect(AppConfig.isSmartFormat('10.0.0.166'), isFalse);
      expect(AppConfig.isSmartFormat('192.168.1'), isFalse);
    });

    test('smart IP round-trip preserves the subnet part', () {
      final part = AppConfig.extractSmartPart('192.168.42.166');
      expect(part, '42');
      expect(AppConfig.buildSmartIp(part!), '192.168.42.166');
    });
  });
}
