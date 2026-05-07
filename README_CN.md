[English](Smart-Bakery-README.md)

# Smart Bakery（智能面包房监控）

一款 **Flutter 移动端应用**，用于实时监控和控制智能面包房系统。通过本地 WiFi 连接 Raspberry Pi 后端，显示温湿度读数，并控制风扇、蜂鸣器和静音模式。

---

## 技术栈

| 类别 | 技术 | 版本 |
|------|------|------|
| 框架 | Flutter (Dart) | Dart SDK ^3.10.7 |
| HTTP 客户端 | `http` | ^1.2.0 |
| 本地存储 | `shared_preferences` | ^2.2.2 |
| 权限管理 | `permission_handler` | ^11.3.1 |
| 图标 | `cupertino_icons` | ^1.0.8 |
| 代码检查 | `flutter_lints` | ^6.0.0 |
| Android | AGP 8.11.1、Kotlin 2.2.20、Java 17 | |

---

## 功能特性

### 监测
- **实时温度显示** — 大字体温读数（°C）
- **湿度显示** — 与温度并列展示
- **连接状态指示** — 绿色/红色圆点显示在线/离线状态
- **800ms 自动轮询** — 每 800 毫秒刷新一次传感器数据

### 控制
- **风扇控制** — AUTO / ON / OFF 三种模式切换
- **蜂鸣器控制** — AUTO / ON / OFF 三种模式切换
- **静音模式** — MUTE / UNMUTE 开关
- **乐观 UI 更新** — 按钮状态立即更新，无需等待服务器确认

### 网络
- **自动网络扫描** — 暴力扫描 `192.168.0.166`–`192.168.255.166`，自动发现 Raspberry Pi
- **智能 IP 输入** — 两种模式：Smart Mode（自动补全前缀）/ Full Mode（手动输入完整 IP）
- **IP 持久存储** — 通过 SharedPreferences 保存上次连接的 IP，实现自动重连
- **离线恢复** — 检测连接断开，提供重试和重新配置选项

---

## 系统架构

```
┌──────────────────────────────────────────────┐
│              Flutter 移动端应用               │
│                                               │
│  main.dart → DashboardPage（单页应用）        │
│       │                                       │
│       ├── TemperatureCard（传感器数据显示）    │
│       ├── ControlCard ×3（风扇/蜂鸣器/静音）  │
│       │                                       │
│       ├── NetworkScanner（局域网扫描发现）    │
│       ├── BakeryService（HTTP API 通信）      │
│       └── SharedPreferences（IP 持久存储）    │
│                                               │
│            HTTP 端口 5000 ↓                  │
└──────────────────┬───────────────────────────┘
                   │
┌──────────────────▼───────────────────────────┐
│          Raspberry Pi 后端                    │
│   GET  /api/status  → 返回传感器数据          │
│   POST /api/control → 发送设备控制指令         │
└──────────────────────────────────────────────┘
```

---

## 数据模型

**BakeryStatus**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `temperature` | `double` | 当前温度（°C） |
| `humidity` | `double` | 当前湿度（%） |
| `fan_state` | `String` | 风扇状态：ON / OFF / -- |
| `buzzer_state` | `String` | 蜂鸣器状态：ON / OFF / -- |
| `fan_mode` | `String` | 控制模式：AUTO / ON / OFF |
| `buzzer_mode` | `String` | 控制模式：AUTO / ON / OFF |
| `silent_mode` | `String` | 静音状态：ON / OFF |

---

## API 接口约定（后端）

| 接口 | 方法 | 请求体 | 响应 |
|------|------|--------|------|
| `/api/status` | GET | — | `BakeryStatus` JSON |
| `/api/control` | POST | `{"device": "fan\|buzzer\|silent_mode", "mode": "AUTO\|ON\|OFF"}` | 200 OK |

> 后端代码**不在本仓库中**——它独立运行在 Raspberry Pi 上。

---

## 环境要求

- [Flutter SDK](https://flutter.dev/docs/get-started/install)（Dart ^3.10.7）
- Android Studio / Xcode（用于平台构建）
- 一台运行 Smart Bakery 后端的 Raspberry Pi（端口 5000）
- 连接到同一 WiFi 网络的 Android/iOS 设备或模拟器

---

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/BoooSAMA/Smart-Bakery.git
cd Smart-Bakery/bakery_monitor
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行应用

```bash
flutter run
```

确保设备已开启 USB 调试模式，并与 Raspberry Pi 连接到同一网络。

### 4. 连接到你的面包房 Pi

首次启动时，应用会自动扫描 Raspberry Pi。如果自动发现失败，点击设置图标手动输入 IP 地址。

---

## 项目结构

```
Smart-Bakery/
├── READ ME FIRST.md                  # 原始设置指南
│
└── bakery_monitor/                   # Flutter 项目根目录
    ├── pubspec.yaml                  # 依赖与配置
    │
    ├── lib/                          # Dart 源码
    │   ├── main.dart                 # 应用入口
    │   ├── api/
    │   │   ├── bakery_service.dart   # HTTP 客户端（状态 + 控制）
    │   │   └── network_scanner.dart  # 局域网 IP 暴力扫描器
    │   ├── config/
    │   │   └── app_config.dart       # 常量与配置
    │   ├── models/
    │   │   └── bakery_status.dart    # BakeryStatus 数据模型
    │   ├── screens/
    │   │   └── dashboard_page.dart   # 主仪表盘（单页应用）
    │   └── widgets/
    │       ├── control_card.dart     # 可复用控制切换卡片
    │       └── temperature_card.dart # 温湿度显示卡片
    │
    ├── test/
    │   └── widget_test.dart          # 测试占位（待更新）
    │
    ├── android/                      # Android 平台配置
    │   └── app/src/main/
    │       └── AndroidManifest.xml   # 权限与设置
    │
    └── ios/                          # iOS 平台配置
        └── Runner/
            └── Info.plist
```

---

## 配置项

`lib/config/app_config.dart` 中的关键常量：

| 常量 | 值 | 用途 |
|------|-----|------|
| `apiPort` | `5000` | 后端 HTTP 端口 |
| `pollingIntervalMs` | `800` | 状态刷新间隔 |
| `connectionTimeoutSeconds` | `2` | HTTP 请求超时 |
| `defaultIpPattern` | `192.168.x.166` | 自动扫描目标子网 |

---

## Android 权限

| 权限 | 用途 |
|------|------|
| `INTERNET` | 与 Raspberry Pi 进行 HTTP 通信 |
| `ACCESS_NETWORK_STATE` | 检测 WiFi 连接状态 |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | WiFi 扫描 |
| `NEARBY_WIFI_DEVICES` | 对等设备发现（Android 13+） |
| `ACCESS_WIFI_STATE` / `CHANGE_WIFI_STATE` | WiFi 状态管理 |

---

## 安全注意事项

- 🔴 **HTTP 明文传输** — 所有流量均未加密。仅在局域网环境下可接受，切勿暴露到公网。
- 🔴 **无身份认证** — 后端无 API 密钥、令牌或密码保护。
- 🟡 **位置权限** — 为 WiFi 扫描而请求，请评估是否实际需要。
- 🟢 **无硬编码凭据** — 源码中不包含任何 API 密钥或凭据。

---

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE)。
