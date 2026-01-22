import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bakery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMateri
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: const Color(0xFFF4F4F9),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // 核心数据
  String _currentIp = ""; 
  bool _isIpSet = false;

  Map<String, dynamic> _data = {
    "temperature": 0.0,
    "humidity": 0.0,
    "fan_state": "--",
    "buzzer_state": "--",
    "fan_mode": "AUTO",
    "buzzer_mode": "AUTO",
    "silent_mode": "ON"
  };

  Timer? _timer;
  bool _isOffline = true;

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

  // --- 💾 本地存储逻辑 ---
  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIp = prefs.getString('saved_ip') ?? "";
      
      if (_currentIp.isNotEmpty) {
        _isIpSet = true;
        _startPolling();
      } else {
        // 第一次打开，延迟弹出设置框
        Future.delayed(Duration.zero, () => _showSmartIpDialog());
      }
    });
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_ip', ip);
    setState(() {
      _currentIp = ip;
      _isIpSet = true;
      _isOffline = true;
    });
    _timer?.cancel();
    _startPolling();
  }

  // --- 📡 网络逻辑 ---
  void _startPolling() {
    _timer?.cancel();
    _fetchStatus();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      _fetchStatus();
    });
  }

  String get _baseUrl => 'http://$_currentIp:5000';

  Future<void> _fetchStatus() async {
    if (!_isIpSet || _currentIp.isEmpty) return;
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/status'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _data = json.decode(response.body);
            _isOffline = false;
          });
        }
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
    if (!_isIpSet) return;
    setState(() {
      if (device == 'fan') _data['fan_mode'] = mode;
      if (device == 'buzzer') _data['buzzer_mode'] = mode;
      if (device == 'silent_mode') _data['silent_mode'] = mode;
    });
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/control'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"device": device, "mode": mode}),
      );
    } catch (e) {
      print("Command failed: $e");
    }
  }

  // --- 📱 智能 IP 弹窗逻辑 (Smart Dialog) ---
  void _showSmartIpDialog() {
    // 1. 分析当前 IP 是否符合智能格式 (192.168.XXX.166)
    bool isSmartMode = false;
    String smartPart = "";
    
    final parts = _currentIp.split('.');
    if (parts.length == 4 && parts[0] == '192' && parts[1] == '168' && parts[3] == '166') {
      isSmartMode = true; // 符合格式，进入快捷模式
      smartPart = parts[2]; // 提取中间的数字
    } else if (_currentIp.isEmpty) {
      isSmartMode = true; // 如果是空的，也默认用快捷模式
    }

    // 控制器
    final TextEditingController smartController = TextEditingController(text: smartPart);
    final TextEditingController fullController = TextEditingController(text: _currentIp);

    showDialog(
      context: context,
      barrierDismissible: _isIpSet,
      builder: (context) {
        // 使用 StatefulBuilder 让弹窗内部可以局部刷新 (切换模式)
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('配置连接地址'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSmartMode) ...[
                    // === 模式 A: 快捷填空 ===
                    const Text('请输入 IP 中间的数字:', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text("192.168.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(
                          width: 60,
                          child: TextField(
                            controller: smartController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            autofocus: true, // 自动弹出键盘
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              isDense: true,
                              hintText: "XXX",
                            ),
                          ),
                        ),
                        const Text(".166", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ] else ...[
                    // === 模式 B: 完整输入 ===
                    const Text('请输入完整 IP 地址:', style: TextStyle(color: Colors.grey)),
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
                  // 切换模式的按钮
                  TextButton(
                    onPressed: () {
                      setStateDialog(() {
                        isSmartMode = !isSmartMode; // 切换布尔值
                        // 切换时同步数据，防止用户输了一半切过去没了
                        if (isSmartMode) {
                          // 切回快捷模式：尝试提取
                          final p = fullController.text.split('.');
                          if (p.length == 4) smartController.text = p[2];
                        } else {
                          // 切去完整模式：自动拼接
                          if (smartController.text.isNotEmpty) {
                            fullController.text = "192.168.${smartController.text}.166";
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
                      // 自动拼接
                      final part = smartController.text.trim();
                      if (part.isNotEmpty) {
                        finalIp = "192.168.$part.166";
                      }
                    } else {
                      // 使用完整输入
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍓 RPi Monitor'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSmartIpDialog, // 点击打开智能弹窗
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showSmartIpDialog,
              child: const Text('配置 IP'),
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
            const Text('无法连接到:', style: TextStyle(fontSize: 16, color: Colors.grey)),
            Text(_baseUrl, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
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
        Center(child: Text("Connected to: $_currentIp", style: TextStyle(color: Colors.grey[400], fontSize: 12))),
        const SizedBox(height: 10),
        _buildTempCard(),
        const SizedBox(height: 16),
        _buildControlCard(
          title: 'Silent Mode',
          icon: Icons.notifications_off,
          statusText: _data['silent_mode'] == 'ON' ? 'MUTED' : 'SOUND',
          statusColor: _data['silent_mode'] == 'ON' ? Colors.orange : Colors.green,
          deviceKey: 'silent_mode',
          currentMode: _data['silent_mode'],
          options: ['ON', 'OFF'],
          displayLabels: ['MUTE', 'UNMUTE'],
        ),
        const SizedBox(height: 16),
        _buildControlCard(
          title: 'Fan Control',
          icon: Icons.wind_power,
          statusText: _data['fan_state'],
          statusColor: _data['fan_state'] == 'ON' ? Colors.red : Colors.green,
          deviceKey: 'fan',
          currentMode: _data['fan_mode'],
          options: ['AUTO', 'ON', 'OFF'],
          displayLabels: ['AUTO', 'ON', 'OFF'],
        ),
        const SizedBox(height: 16),
        _buildControlCard(
          title: 'Buzzer Control',
          icon: Icons.volume_up,
          statusText: _data['buzzer_state'],
          statusColor: _data['buzzer_state'] == 'ON' ? Colors.red : Colors.green,
          deviceKey: 'buzzer',
          currentMode: _data['buzzer_mode'],
          options: ['AUTO', 'ON', 'OFF'],
          displayLabels: ['AUTO', 'ON', 'OFF'],
        ),
      ],
    );
  }

  Widget _buildTempCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('TEMPERATURE', 
              style: TextStyle(fontSize: 14, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_data['temperature']}',
                  style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text('°C', style: TextStyle(fontSize: 24, color: Colors.grey)),
                ),
              ],
            ),
             Text('Humidity: ${_data['humidity']}%', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCard({
    required String title,
    required IconData icon,
    required String statusText,
    required Color statusColor,
    required String deviceKey,
    required String currentMode,
    required List<String> options,
    required List<String> displayLabels,
  }) {
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
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(statusText, 
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
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
                      onPressed: () => _sendCommand(deviceKey, option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? Colors.blueAccent : Colors.grey[100],
                        foregroundColor: isActive ? Colors.white : Colors.black87,
                        elevation: isActive ? 2 : 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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