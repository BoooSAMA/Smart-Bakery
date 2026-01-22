import 'package:flutter/material.dart';

/// A card widget displaying temperature and humidity readings
class TemperatureCard extends StatelessWidget {
  final double temperature;
  final double humidity;

  const TemperatureCard({
    super.key,
    required this.temperature,
    required this.humidity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'TEMPERATURE',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$temperature',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    '°C',
                    style: TextStyle(fontSize: 24, color: Colors.grey),
                  ),
                ),
              ],
            ),
            Text(
              'Humidity: $humidity%',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
