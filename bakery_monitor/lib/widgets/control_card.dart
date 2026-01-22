import 'package:flutter/material.dart';

/// A reusable control card widget for managing device states
class ControlCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String statusText;
  final Color statusColor;
  final String deviceKey;
  final String currentMode;
  final List<String> options;
  final List<String> displayLabels;
  final Function(String device, String mode) onCommandSend;

  const ControlCard({
    super.key,
    required this.title,
    required this.icon,
    required this.statusText,
    required this.statusColor,
    required this.deviceKey,
    required this.currentMode,
    required this.options,
    required this.displayLabels,
    required this.onCommandSend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: List.generate(options.length, (index) {
                final option = options[index];
                final label = displayLabels[index];
                final bool isActive = currentMode == option;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      onPressed: () => onCommandSend(deviceKey, option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isActive ? Colors.blueAccent : Colors.grey[100],
                        foregroundColor:
                            isActive ? Colors.white : Colors.black87,
                        elevation: isActive ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
