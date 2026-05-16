# 🐱 Cut - 肩颈放松寻猫 App

## 快速开始

1. 在 Xcode 中打开 `Cut.xcodeproj`
2. 确保 Deployment Target ≥ iOS 16.0
3. 连上 iPhone 真机（AR 需要真机）
4. 选择你的 Development Team 并签名
5. ⌘R 运行

## 项目文件说明

| 文件 | 说明 |
|------|------|
| `CutApp.swift` | App 入口 |
| `ContentView.swift` | 主界面（AR 相机 + UI 叠加层） |
| `ARViewContainer.swift` | AR 包装器（RealityKit + ARKit） |

## 当前功能

- 全屏相机 AR 视图
- 正前方 1 米处红色测试方块（代表猫咪）
- 缓慢旋转动画
- 权限配置已包含在 Info.plist

## 权限

Info.plist 已配置：
- NSCameraUsageDescription
- NSCameraCaptureMode
- NSMicrophoneUsageDescription
