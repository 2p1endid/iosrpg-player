# iOS RPG Player

[中文](#中文) · [English](#english)

## 中文

iOS RPG Player 是一个面向 iPhone 和 iPad 的开源 RPG Maker MV/MZ 本地游戏播放器。它允许用户从“文件”App导入自己合法持有的、已经部署为Web项目的RPG Maker MV/MZ游戏，并通过应用内的本地服务器和WKWebView运行。

> 本项目不包含、提供或分发RPG Maker运行时、商业游戏、DLC、Mod或任何第三方游戏资源。用户应确保自己有权使用所导入的内容。

- 当前版本：`0.1.0`
- 最低系统：iOS/iPadOS 17.0
- 许可证：[MIT License](LICENSE)


### 支持范围与限制

当前重点支持RPG Maker MV/MZ的Web部署项目。兼容性取决于游戏自身使用的插件、媒体格式和桌面专用能力。



### 安装说明

Release中的`IOSRPGPlayer-unsigned.ipa`是未签名设备构建：

- 没有Apple开发者证书；
- 没有provisioning profile；
- 不能直接安装到普通iPhone/iPad；
- 需要用户使用自己合法的Apple开发者身份和匹配的provisioning profile重新签名。

### 构建

项目使用XcodeGen生成Xcode工程。需要macOS、Xcode和XcodeGen：

```bash
brew install xcodegen
./scripts/build-ios.sh simulator
./scripts/build-ios.sh archive-unsigned
```

Windows可运行便携测试：

```bash
npm test
```

更多说明见[BUILD_IPA.md](BUILD_IPA.md)。

### 使用的其他开源项目

#### 运行时依赖

| 项目 | 用途 | 许可证 |
|---|---|---|
| [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) | ZIP读取与安全解压 | MIT |

#### 构建与持续集成工具

| 项目 | 用途 | 许可证 |
|---|---|---|
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | 根据`project.yml`生成Xcode工程 | MIT |
| [actions/checkout](https://github.com/actions/checkout) | GitHub Actions源码检出 | MIT |
| [actions/upload-artifact](https://github.com/actions/upload-artifact) | GitHub Actions构建产物上传 | MIT |
| [Node.js](https://github.com/nodejs/node) | 运行便携自动化测试 | Node.js License（MIT类许可及组件许可） |

Apple的SwiftUI、UIKit、WebKit、Network、Foundation、CoreGraphics、UniformTypeIdentifiers和XCTest属于系统SDK框架，不作为项目内第三方依赖分发。

第三方项目保留其各自的版权与许可证。本项目的MIT许可证只适用于本仓库原创代码，不替代第三方许可证。

### 许可证

本项目以[MIT License](LICENSE)发布。

---

## English

iOS RPG Player is an open-source prototype local player for RPG Maker MV/MZ games on iPhone and iPad. It lets users import legally obtained RPG Maker MV/MZ games that have been deployed as web projects from the Files app, then runs them through an embedded local server and WKWebView.

> This project does not include, provide, or distribute RPG Maker runtimes, commercial games, DLC, mods, or third-party game assets. Users are responsible for ensuring that they have the right to use all imported content.

### Current Version

- Public version: `0.1.0`
- Internal build number: `14`
- Minimum OS: iOS/iPadOS 17.0
- Author: [2p1endid](https://github.com/2p1endid)
- Repository: <https://github.com/2p1endid/iosrpg-player>
- License: [MIT License](LICENSE)

### Features

- Imports RPG Maker MV/MZ ZIP archives or extracted folders from the iOS Files app;
- Finds game roots nested up to four directory levels deep;
- Safely extracts ZIP archives while rejecting traversal, absolute paths, symbolic links, and oversized archives;
- Stores games in the app sandbox and maintains a persistent local library;
- Runs each game through an embedded HTTP server bound only to `127.0.0.1` on a random port;
- Supports common MV/MZ XHR, relative URL, encrypted-resource, and browser loading semantics;
- Provides a fullscreen WKWebView with aspect-preserving logical-resolution scaling;
- Includes a hideable touch controller with a D-pad and A/B/X/Y buttons;
- Sends input through both RPG Maker logical state and DOM keyboard events;
- Captures structured JavaScript, Promise, console, HTTP, and bridge diagnostics;
- Applies narrowly scoped browser fallbacks for selected NW.js-only plugins;
- Shows version, build, author, GitHub, license, and third-party projects in a bilingual About screen.

### Scope and Limitations

The current focus is RPG Maker MV/MZ web deployment projects. Compatibility depends on each game's plugins, media formats, and desktop-only assumptions.

The project does not currently promise support for:

- RPG Maker XP, VX, or VX Ace;
- Non-web projects that require RTP;
- RAR, 7z, or APK imports;
- Features that require full Node.js, NW.js filesystem access, Steam APIs, or desktop native modules;
- Distribution of unauthorized game assets, cracked content, or commercial DLC.

### Installation

`IOSRPGPlayer-unsigned.ipa` in the Release is a genuinely unsigned device build:

- It has no Apple developer certificate;
- It has no provisioning profile;
- It cannot be installed directly on a normal iPhone or iPad;
- Users must re-sign it with their own legitimate Apple developer identity and a matching provisioning profile.

### Building

The project uses XcodeGen to generate the Xcode project. macOS, Xcode, and XcodeGen are required:

```bash
brew install xcodegen
./scripts/build-ios.sh simulator
./scripts/build-ios.sh archive-unsigned
```

Portable tests can be run on Windows:

```bash
npm test
```

See [BUILD_IPA.md](BUILD_IPA.md) for additional details.

### Other Open-Source Projects Used

#### Runtime Dependency

| Project | Purpose | License |
|---|---|---|
| [ZIPFoundation](https://github.com/weichsel/ZIPFoundation) | ZIP reading and safe extraction | MIT |

#### Build and Continuous Integration Tools

| Project | Purpose | License |
|---|---|---|
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | Generates the Xcode project from `project.yml` | MIT |
| [actions/checkout](https://github.com/actions/checkout) | Checks out source in GitHub Actions | MIT |
| [actions/upload-artifact](https://github.com/actions/upload-artifact) | Uploads build artifacts in GitHub Actions | MIT |
| [Node.js](https://github.com/nodejs/node) | Runs portable automated tests | Node.js License (MIT-style and component licenses) |

Apple's SwiftUI, UIKit, WebKit, Network, Foundation, CoreGraphics, UniformTypeIdentifiers, and XCTest are system SDK frameworks and are not distributed as third-party project dependencies.

Third-party projects retain their respective copyrights and licenses. This repository's MIT License applies only to original code in this repository and does not replace third-party licenses.

### License

This project is released under the [MIT License](LICENSE).
