# 离线密本 (OfflinePass)

一款基于 SwiftUI 开发的、极致安全的纯离线密码管理器。

![Language](https://img.shields.io/badge/Language-Swift-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS-blue.svg)
![iOS Version](https://img.shields.io/badge/iOS-16.1%2B-brightgreen.svg)
![License](https://img.shields.io/badge/License-GPLv3-red.svg)

## 🌟 特性

- **绝对隐私**：纯离线存储，数据不经过任何服务器，无云端同步风险。
- **顶级加密**：
  - 加密算法：使用 `AES-256-GCM` 进行认证加密。
  - 密钥派生：通过 `HKDF-SHA256` 从主密码派生加密密钥，并结合随机 Salt。
- **生物识别**：支持 Face ID / Touch ID 快速解锁，主密码安全存储于系统 Keychain。
- **多端适配**：支持 iOS 和 macOS，提供一致的操作体验。
- **多语言适配**：支持中文、英文、日文。
- **高度自定义**：支持深色/浅色模式切换，以及自定义字体大小。
- **导出与备份**：提供加密的 `.pwmbackup` 文件备份功能，确保数据可迁移。


## 运行环境

- **iOS**: 16.1+
- **macOS**: 13.0+
- **Xcode**: 15.0+

## 📄 许可协议

本项目采用 [GPLv3](LICENSE) 协议开源。

## 联系

- **开发者**：南京亘富软件技术有限公司
- **版权所有**：© 2026 南京亘富软件技术有限公司


