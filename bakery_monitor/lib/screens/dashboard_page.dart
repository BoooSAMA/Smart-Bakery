import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bakery_status.dart';
import '../api/bakery_service.dart';
import '../api/network_scanner.dart';
import '../widgets/temperature_card.dart';
import '../widgets/control_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
// Core data
String _currentIp = "";
bool _isIpSet = false;
BakeryStatus _status = BakeryStatus.empty();
BakeryService? _bakeryService;

Timer? _timer;
bool _isOffline = true;
  
// Network scanning state
bool _isScanning = false;
String _scanProgress = "";
  
// First load auto-scan state
bool _isFirstLoadScanning = false;

@override
void initState() {
  super.initState();
  _loadSavedIp();
}

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}

// --- 💾 Local Storage Logic ---
Future<void> _loadSavedIp() async {
  final prefs = await SharedPreferences.getInstance();
  final savedIp = prefs.getString('saved_ip') ?? "";

  if (savedIp.isNotEmpty) {
    // IP exists, use it
    setState(() {
      _currentIp = savedIp;
      _isIpSet = true;
      _bakeryService = BakeryService(ipAddress: savedIp);
    });
    _startPolling();
  } else {
    // No saved IP - auto-scan on first load
    setState(() {
      _isFirstLoadScanning = true;
    });
    await _startAutoScan();
  }
}
  
  // --- 🔍 Auto-scan on first load ---
  Future<void> _startAutoScan() async {
    try {
      final discoveredIp = await NetworkScanner.scanNetwork(
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _scanProgress = progress;
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _isFirstLoadScanning = false;
      });

      if (discoveredIp != null) {
        // Success - save and use the IP
        await _saveIp(discoveredIp);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ 自动发现设备: $discoveredIp'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Scan failed - show error and manual dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ 自动扫描未找到设备'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        // Show manual input dialog after scan fails
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showSmartIpDialog();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isFirstLoadScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('扫描失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      // Show manual input dialog after error
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showSmartIpDialog();
        }
      });
    }
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_ip', ip);
    setState(() {
      _currentIp = ip;
      _isIpSet = true;
      _isOffline = true;
      _bakeryService = BakeryService(ipAddress: ip);
    });
    _timer?.cancel();
    _startPolling();
  }

  // --- 📡 Network Logic ---
  void _startPolling() {
    _timer?.cancel();
    _fetchStatus();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      _fetchStatus();
    });
  }

  Future<void> _fetchStatus() async {
    if (!_isIpSet || _currentIp.isEmpty || _bakeryService == null) return;

    try {
      final status = await _bakeryService!.fetchStatus();
      if (mounted) {
        setState(() {
          _status = status;
          _isOffline = false;
        });
      }
    } catch (e) {
      if (!_isOffline && mounted) {
        setState(() {
          _isOffline = true;
        });
      }
    }
  }

  Future<void> _sendCommand(String device, String mode) async {
    if (!_isIpSet || _bakeryService == null) return;

    // Optimistically update UI
    setState(() {
      if (device == 'fan') {
        _status = _status.copyWith(fanMode: mode);
      } else if (device == 'buzzer') {
        _status = _status.copyWith(buzzerMode: mode);
      } else if (device == 'silent_mode') {
        _status = _status.copyWith(silentMode: mode);
      }
    });

    try {
      await _bakeryService!.sendCommand(device, mode);
    } catch (e) {
      debugPrint("Command failed: $e");
    }
  }

  // --- 🔍 Network Scanning Logic ---
  Future<void> _startNetworkScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _scanProgress = "准备扫描...";
    });

    try {
      final discoveredIp = await NetworkScanner.scanNetwork(
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _scanProgress = progress;
            });
          }
        },
      );

      if (discoveredIp != null) {
        // Found device - save and connect
        await _saveIp(discoveredIp);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ 自动发现设备: $discoveredIp'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // No device found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ 未找到设备，请检查网络连接或手动输入 IP'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Error during scan
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('扫描失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _scanProgress = "";
        });
      }
    }
  }

  // --- 📱 Smart IP Dialog Logic ---
  void _showSmartIpDialog() {
    // Analyze if current IP follows smart format (192.168.XXX.XXX)
    bool isSmartMode = false;
    String smartPart3 = "";
    String smartPart4 = "";

    final parts = _currentIp.split('.');
    if (parts.length == 4 &&
        parts[0] == '192' &&
        parts[1] == '168') {
      isSmartMode = true;
      smartPart3 = parts[2]; // Extract third number
      smartPart4 = parts[3]; // Extract fourth number
    } else if (_currentIp.isEmpty) {
      isSmartMode = true; // Default to smart mode if empty
    }

    // Controllers
    final TextEditingController smartController3 =
        TextEditingController(text: smartPart3);
    final TextEditingController smartController4 =
        TextEditingController(text: smartPart4);
    final TextEditingController fullController =
        TextEditingController(text: _currentIp);

    showDialog(
      context: context,
      barrierDismissible: _isIpSet,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('配置连接地址'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSmartMode) ...[
                    // === Mode A: Quick Fill ===
                    const Text(
                      '请输入 IP 后两段数字:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          "192.168.",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: smartController3,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            autofocus: true,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              isDense: true,
                              hintText: "XXX",
                            ),
                          ),
                        ),
                        const Text(
                          ".",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: smartController4,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              isDense: true,
                              hintText: "XXX",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // === Mode B: Full Input ===
                    const Text(
                      '请输入完整 IP 地址:',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: fullController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'IP Address',
                        hintText: '192.168.x.x',
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Toggle mode button
                  TextButton(
                    onPressed: () {
                      setStateDialog(() {
                        isSmartMode = !isSmartMode;
                        // Sync data when switching modes
                        if (isSmartMode) {
                          // Switch to smart mode: extract
                          final p = fullController.text.split('.');
                          if (p.length == 4) {
                            smartController3.text = p[2];
                            smartController4.text = p[3];
                          }
                        } else {
                          // Switch to full mode: auto-construct
                          if (smartController3.text.isNotEmpty && smartController4.text.isNotEmpty) {
                            fullController.text =
                                "192.168.${smartController3.text}.${smartController4.text}";
                          }
                        }
                      });
                    },
                    child: Text(
                      isSmartMode ? "切换到完整模式 (其他热点)" : "切换到快捷模式 (默认)",
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                ],
              ),
              actions: [
                if (_isIpSet)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ElevatedButton(
                  onPressed: () {
                    String finalIp = "";
                    if (isSmartMode) {
                      // Auto-construct
                      final part3 = smartController3.text.trim();
                      final part4 = smartController4.text.trim();
                      if (part3.isNotEmpty && part4.isNotEmpty) {
                        finalIp = "192.168.$part3.$part4";
                      }
                    } else {
                      // Use full input
                      finalIp = fullController.text.trim();
                    }

                    if (finalIp.isNotEmpty) {
                      _saveIp(finalIp);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('保存并连接'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen during first load auto-scan
    if (_isFirstLoadScanning) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('🍓 Smart Bakery'),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 2,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                'Auto-scanning local network...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              if (_scanProgress.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _scanProgress,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍓 Smart Bakery'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSmartIpDialog,
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 8),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _isOffline ? Colors.red : Colors.green,
              shape: BoxShape.circle,
            ),
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isIpSet) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link_off, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text('请先配置连接地址', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            // Auto Scan Button
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _startNetworkScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.radar),
              label: Text(_isScanning ? '扫描中...' : '🔍 自动扫描'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            if (_isScanning && _scanProgress.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _scanProgress,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            const Text('或', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            // Manual IP Button
            ElevatedButton(
              onPressed: _showSmartIpDialog,
              child: const Text('手动输入 IP'),
            ),
          ],
        ),
      );
    }

    if (_isOffline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              '无法连接到:',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            Text(
              _bakeryService?.baseUrl ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // Auto Scan Button
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _startNetworkScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.radar),
              label: Text(_isScanning ? '扫描中...' : '🔍 自动扫描'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            if (_isScanning && _scanProgress.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _scanProgress,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('修改配置'),
              onPressed: _showSmartIpDialog,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // IP 地址卡片 - 醒目且可点击修改
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.blue.shade50,
          child: InkWell(
            onTap: _showSmartIpDialog,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.wifi,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '当前连接地址',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentIp,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          '修改',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Auto Scan Icon Button
                  InkWell(
                    onTap: _isScanning ? null : _startNetworkScan,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isScanning ? Colors.grey.shade200 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _isScanning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.blue,
                              ),
                            )
                          : const Icon(
                              Icons.radar,
                              color: Colors.blue,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TemperatureCard(
          temperature: _status.temperature,
          humidity: _status.humidity,
        ),
        const SizedBox(height: 16),
        ControlCard(
          title: 'Silent Mode',
          icon: Icons.notifications_off,
          statusText: _status.silentMode == 'ON' ? 'MUTED' : 'SOUND',
          statusColor: _status.silentMode == 'ON' ? Colors.orange : Colors.green,
          deviceKey: 'silent_mode',
          currentMode: _status.silentMode,
          options: const ['ON', 'OFF'],
          displayLabels: const ['MUTE', 'UNMUTE'],
          onCommandSend: _sendCommand,
        ),
        const SizedBox(height: 16),
        ControlCard(
          title: 'Fan Control',
          icon: Icons.wind_power,
          statusText: _status.fanState,
          statusColor: _status.fanState == 'ON' ? Colors.red : Colors.green,
          deviceKey: 'fan',
          currentMode: _status.fanMode,
          options: const ['AUTO', 'ON', 'OFF'],
          displayLabels: const ['AUTO', 'ON', 'OFF'],
          onCommandSend: _sendCommand,
        ),
        const SizedBox(height: 16),
        ControlCard(
          title: 'Buzzer Control',
          icon: Icons.volume_up,
          statusText: _status.buzzerState,
          statusColor: _status.buzzerState == 'ON' ? Colors.red : Colors.green,
          deviceKey: 'buzzer',
          currentMode: _status.buzzerMode,
          options: const ['AUTO', 'ON', 'OFF'],
          displayLabels: const ['AUTO', 'ON', 'OFF'],
          onCommandSend: _sendCommand,
        ),
      ],
    );
  }
}
