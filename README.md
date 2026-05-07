[中文版](README_CN.md)

# Smart Bakery

A **Flutter mobile app** for real-time monitoring and control of a smart bakery system. Connects to a Raspberry Pi backend over local WiFi to display temperature/humidity readings and control fans, buzzers, and silent mode.

---

## Tech Stack

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter (Dart) | Dart SDK ^3.10.7 |
| HTTP Client | `http` | ^1.2.0 |
| Local Storage | `shared_preferences` | ^2.2.2 |
| Permissions | `permission_handler` | ^11.3.1 |
| Icons | `cupertino_icons` | ^1.0.8 |
| Linting | `flutter_lints` | ^6.0.0 |
| Android | AGP 8.11.1, Kotlin 2.2.20, Java 17 | |

---

## Features

### Monitoring
- **Real-time Temperature** — large-format display with °C readout
- **Humidity Display** — shown alongside temperature
- **Connection Status** — green/red indicator showing online/offline state
- **800ms Auto-Polling** — refreshes sensor data every 800ms

### Control
- **Fan Control** — toggle between AUTO / ON / OFF modes
- **Buzzer Control** — toggle between AUTO / ON / OFF modes
- **Silent Mode** — MUTE / UNMUTE toggle
- **Optimistic UI** — button state updates instantly before server confirmation

### Network
- **Auto Network Scan** — brute-force scans `192.168.0.166`–`192.168.255.166` to discover the Raspberry Pi
- **Smart IP Input** — two modes: Smart Mode (auto-completes prefix) or Full Mode (raw IP entry)
- **Persistent IP** — saves last connected IP via SharedPreferences for auto-reconnect
- **Offline Recovery** — detects connection loss with retry + reconfigure options

---

## Architecture

```
┌──────────────────────────────────────────────┐
│              Flutter Mobile App               │
│                                               │
│  main.dart → DashboardPage (single screen)    │
│       │                                       │
│       ├── TemperatureCard (sensor display)    │
│       ├── ControlCard ×3 (fan/buzzer/silent) │
│       │                                       │
│       ├── NetworkScanner (LAN discovery)      │
│       ├── BakeryService (HTTP API)            │
│       └── SharedPreferences (IP persistence)  │
│                                               │
│            HTTP on port 5000 ↓                │
└──────────────────┬───────────────────────────┘
                   │
┌──────────────────▼───────────────────────────┐
│          Raspberry Pi Backend                │
│   GET  /api/status  → returns sensor data    │
│   POST /api/control → sends device command   │
└──────────────────────────────────────────────┘
```

---

## Data Model

**BakeryStatus**:

| Field | Type | Description |
|-------|------|-------------|
| `temperature` | `double` | Current temperature (°C) |
| `humidity` | `double` | Current humidity (%) |
| `fan_state` | `String` | Fan status: ON / OFF / -- |
| `buzzer_state` | `String` | Buzzer status: ON / OFF / -- |
| `fan_mode` | `String` | Control mode: AUTO / ON / OFF |
| `buzzer_mode` | `String` | Control mode: AUTO / ON / OFF |
| `silent_mode` | `String` | Mute state: ON / OFF |

---

## API Contract (Backend)

| Endpoint | Method | Body | Response |
|----------|--------|------|----------|
| `/api/status` | GET | — | `BakeryStatus` JSON |
| `/api/control` | POST | `{"device": "fan\|buzzer\|silent_mode", "mode": "AUTO\|ON\|OFF"}` | 200 OK |

> The backend is **not included** in this repository — it runs separately on a Raspberry Pi.

---

## Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (Dart ^3.10.7)
- Android Studio / Xcode (for platform builds)
- A Raspberry Pi running the Smart Bakery backend on port 5000
- A physical Android/iOS device or emulator connected to the same WiFi network

---

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/BoooSAMA/Smart-Bakery.git
cd Smart-Bakery/bakery_monitor
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

Make sure your device is in USB debugging mode and connected to the same network as the Raspberry Pi.

### 4. Connect to Your Bakery Pi

On first launch, the app will automatically scan for the Raspberry Pi. If auto-discovery fails, tap the settings icon to manually enter the IP address.

---

## Project Structure

```
Smart-Bakery/
├── READ ME FIRST.md                  # Original setup guide
│
└── bakery_monitor/                   # Flutter project root
    ├── pubspec.yaml                  # Dependencies & config
    │
    ├── lib/                          # Dart source code
    │   ├── main.dart                 # App entry point
    │   ├── api/
    │   │   ├── bakery_service.dart   # HTTP client (status + control)
    │   │   └── network_scanner.dart  # LAN IP brute-force scanner
    │   ├── config/
    │   │   └── app_config.dart       # Constants & configuration
    │   ├── models/
    │   │   └── bakery_status.dart    # BakeryStatus data model
    │   ├── screens/
    │   │   └── dashboard_page.dart   # Main dashboard (single screen)
    │   └── widgets/
    │       ├── control_card.dart     # Reusable control toggle card
    │       └── temperature_card.dart # Temperature/humidity display
    │
    ├── test/
    │   └── widget_test.dart          # Test placeholder (needs update)
    │
    ├── android/                      # Android platform config
    │   └── app/src/main/
    │       └── AndroidManifest.xml   # Permissions & settings
    │
    └── ios/                          # iOS platform config
        └── Runner/
            └── Info.plist
```

---

## Configuration

Key constants in `lib/config/app_config.dart`:

| Constant | Value | Purpose |
|----------|-------|---------|
| `apiPort` | `5000` | Backend HTTP port |
| `pollingIntervalMs` | `800` | Status refresh interval |
| `connectionTimeoutSeconds` | `2` | HTTP request timeout |
| `defaultIpPattern` | `192.168.x.166` | Auto-scan target subnet |

---

## Android Permissions

| Permission | Purpose |
|------------|---------|
| `INTERNET` | HTTP communication with Raspberry Pi |
| `ACCESS_NETWORK_STATE` | Detect WiFi connectivity |
| `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` | WiFi scanning |
| `NEARBY_WIFI_DEVICES` | Peer discovery (Android 13+) |
| `ACCESS_WIFI_STATE` / `CHANGE_WIFI_STATE` | WiFi state management |

---

## Security Notes

- 🔴 **HTTP (no HTTPS)** — all traffic is plaintext. Acceptable for local network use, but do not expose to the public internet.
- 🔴 **No authentication** — the backend has no API keys, tokens, or passwords.
- 🟡 **Location permissions** — requested for WiFi scanning. Review if actually needed.
- 🟢 **No hardcoded secrets** — no API keys or credentials in source code.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
