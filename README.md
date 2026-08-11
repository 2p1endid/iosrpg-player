# iOS RPG Player

一个面向 iPhone/iPad 的 RPG Maker 本地游戏播放器实验项目。当前只验证 MV/MZ Web 游戏运行路径。

## 当前能力

- SwiftUI + WKWebView 播放器外壳。
- `rpg-game://` 受限本地资源协议。
- MV/MZ 项目标志识别。
- 路径穿越防护和 MIME 类型映射。
- Swift 虚拟按键到 JavaScript `KeyboardEvent`。
- JavaScript 到 Swift 消息桥。
- 内置自制测试游戏和 `localStorage` 持久化。
- Node 自动化测试。
- XcodeGen 工程描述与 macOS 构建脚本。

## 目录

```text
App/                     SwiftUI / WebKit App
shared/                  可测试的游戏文件规则
tests/                   XCTest 与 Node 测试
Resources/TestGame/      自制 MZ 风格测试游戏
scripts/                 测试服务器与 iOS 构建脚本
spikes/                  可行性验证记录
PROJECT_GOAL.md           项目总目标
BUILD_IPA.md              IPA 构建说明
project.yml               XcodeGen 工程描述
```

## Windows 上验证

```bash
npm test
npm run serve:test-game
```

打开 `http://127.0.0.1:4173`，方向键移动，Enter 计数，Escape 重置。

## macOS/iOS 构建

参见 [BUILD_IPA.md](BUILD_IPA.md)。

> 当前内置测试页不是 RPG Maker 官方运行时，也不证明所有真实 MV/MZ 游戏已经兼容。下一步必须用自制、合法的真实 MV/MZ 导出项目在 Xcode 模拟器和真机验证。
