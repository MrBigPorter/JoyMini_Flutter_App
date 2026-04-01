## ⚠️ Xcode 26 兼容性说明
当前 Contents.json 使用 **Single Size 格式**（仅 1024×1024）以兼容 Xcode 26。
**不要运行** `dart run flutter_launcher_icons`，否则会覆盖还原为旧式多尺寸格式，
导致 `IBSimDeviceTypeiPad3x` 编译错误。
如需更换图标，直接替换 `Icon-App-1024x1024@1x.png` 文件即可。
根源：Xcode 26 在 IBTool 插件注册了 iPad@3x 设备类型，但 iOS 26.4 Simulator
Runtime 尚未发布对应模拟器，导致所有含 iPad 资产目标的项目构建失败。
临时规避方案：TARGETED_DEVICE_FAMILY = "1"（project.pbxproj）
恢复时机：Apple 正式发布 iOS 26 + iPad@3x Simulator 后，可改回 "1,2"。
