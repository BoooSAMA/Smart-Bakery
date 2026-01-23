# 动态 IP 配置系统说明

## 🎯 系统概述

你的 Smart Bakery 应用已经实现了完整的动态 IP 配置系统，完美适配手机热点环境。

## 📱 用户使用流程

### 首次使用
1. 打开 App → 自动弹出 IP 配置对话框
2. 选择输入模式：
   - **快捷模式**：只输入 `192.168.XXX.166` 中间的 `XXX`
   - **完整模式**：输入完整 IP 地址
3. 点击"保存并连接" → IP 永久保存

### 热点 IP 变化时
1. 点击顶部蓝色 IP 卡片
2. 修改 IP 地址
3. 自动重新连接

### 后续使用
- App 自动加载上次保存的 IP
- 无需重复输入

## 🔧 技术架构

### 核心组件

```dart
// 1. 持久化存储
SharedPreferences → 保存 IP 到本地
Key: 'saved_ip'

// 2. 服务层
BakeryService(ipAddress) → 动态构建 API URL
baseUrl = 'http://$ipAddress:5000'

// 3. UI 组件
- Smart IP Dialog: 智能输入界面
- IP Card: 醒目的修改入口
```

### 数据流

```
用户输入 IP
    ↓
SharedPreferences.setString('saved_ip', ip)
    ↓
BakeryService(ipAddress: ip)
    ↓
开始轮询 API
```

## 📂 相关文件

- `lib/screens/dashboard_page.dart` - 主界面和 IP 管理逻辑
- `lib/api/bakery_service.dart` - 动态 API 服务
- `lib/config/app_config.dart` - 配置常量（可选）

## 🌟 特色功能

### 1. 智能输入模式
- **快捷模式**：适合固定格式热点 (192.168.XXX.166)
- **完整模式**：适合任意 IP 地址

### 2. 持久化存储
- 使用 SharedPreferences
- App 重启后自动恢复
- 无需每次输入

### 3. 实时切换
- 点击即改
- 立即生效
- 无需重启 App

## 💡 最佳实践

### 记住你的热点 IP 段
1. 打开手机热点
2. 查看 Raspberry Pi 分配的 IP
3. 记住中间的数字（如 `192.168.43.166` → 记住 `43`）
4. 下次只需输入 `43` 即可

### 处理 IP 变化
- 热点重启后，只需修改中间的数字
- 快速输入，立即连接

## 🔮 进阶选项（可选）

### mDNS/Bonjour 自动发现

如果你希望自动发现设备而不输入 IP，可以：

1. **在树莓派上配置 mDNS**：
   ```bash
   sudo apt-get install avahi-daemon
   sudo systemctl enable avahi-daemon
   ```

2. **给设备设置固定域名**：
   ```
   bakery.local → 自动解析到实际 IP
   ```

3. **Flutter 端使用 multicast_dns 包**：
   ```yaml
   dependencies:
     multicast_dns: ^0.3.2
   ```

   ```dart
   // 自动发现设备
   final String ip = await discoverDevice('bakery.local');
   ```

### 优缺点对比

| 方案 | 优点 | 缺点 |
|------|------|------|
| 手动输入 IP | 简单可靠，立即生效 | 需要手动查看和输入 |
| mDNS 自动发现 | 完全自动，无需输入 | 需要树莓派配置，网络延迟 |

**推荐**：当前手动输入方案已经足够优秀，除非有多设备管理需求。

## ✅ 总结

你的 App 已经完美实现了动态 IP 配置：
- ✅ 无硬编码 IP
- ✅ 持久化存储
- ✅ 友好的修改界面
- ✅ 适配热点环境

**完全满足你的需求！** 🎉
