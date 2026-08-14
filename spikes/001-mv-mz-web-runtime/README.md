# 001：MV/MZ Web 游戏运行环境

## 验证问题

**Given** 一个具有 RPG Maker MZ 典型目录标志的本地 Web 游戏，**when** iOS App 通过 `WKWebView` 和受限资源协议加载它，并从 Swift 发送虚拟按键，**then** 游戏应能渲染、接收方向/确认/取消输入，并保留本地状态。

## 当前方案

- SwiftUI 负责 App 外壳和触屏按钮。
- `WKWebView` 负责 HTML/JavaScript 游戏运行。
- `WKURLSchemeHandler` 提供 `rpg-game://` 本地资源协议。
- 所有资源路径经过相对路径和沙盒边界验证。
- Swift 通过 `KeyboardEvent` 向 JavaScript 发送按键。
- JavaScript 通过 `WKScriptMessageHandler` 把状态发回 Swift。
- 内置测试游戏具有 MZ 目录标志，但它是项目自制的兼容性测试页，不包含 RPG Maker 商业运行时代码，也不等同于对真实 MZ 游戏兼容性的最终证明。

## 可观察行为

- 屏幕上显示可移动的蓝色方块。
- 方向键移动方块。
- A/Enter 增加计数并将消息发送回 Swift。
- B/Escape 重置位置。
- 位置和计数写入 `localStorage`，重新加载后保留。

## Windows 验证

```bash
npm test
npm run serve:test-game
```

然后打开 `http://127.0.0.1:4173`。

## iOS 构建

本目录使用 `project.yml` 描述 Xcode 工程。macOS 上安装 XcodeGen 后执行：

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project RRPPGo.xcodeproj \
  -scheme RRPPGo \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

真机 IPA 需要 Apple 开发团队和签名资产。参见根目录 `BUILD_IPA.md`。

## Verdict: PARTIAL

### 已验证

- MV/MZ 文件标志识别规则。
- 路径穿越和绝对路径拒绝逻辑。
- 常见资源 MIME 类型映射。
- 自制 HTML/JavaScript 游戏已在桌面浏览器中真实运行：816×624 Canvas 正常渲染，运行时对象与 manager 标志存在。
- 浏览器中派发 Enter 和 ArrowRight 后，确认计数变为 1、方块坐标发生变化；重新加载页面后 `localStorage` 中的计数和坐标仍然存在。
- 本地测试服务器对 `data/System.json` 返回正确 JSON MIME；对编码后的目录穿越路径和不存在资源均返回 404。
- iOS 工程已实现 WKWebView、自定义资源协议、双向消息和虚拟按键的代码路径。

### 尚未验证

- 当前主机为 Windows，没有 Xcode、iOS SDK 或 Apple 签名工具，不能在本机编译或运行 Swift/iOS 目标。
- 已真实执行 `./scripts/build-ios.sh simulator`，脚本以退出码 127 明确报告缺少 `xcodegen`；因此本轮没有生成或伪造 IPA。
- 尚未用真实、合法的 RPG Maker MV/MZ 导出项目测试插件、音频、视频、字体、加密资源和存档兼容性。
- 尚未在 iPhone/iPad 真机验证 WebKit 行为、性能和生命周期。

### 下一步建议

1. 在 macOS/Xcode 环境生成工程并运行单元测试。
2. 在模拟器和真机运行内置测试游戏。
3. 准备自制的最小 MV 和 MZ 项目，逐一替换内置测试游戏。
4. 验证真实引擎的输入、音频、视频和存档，再进入文件导入阶段。
