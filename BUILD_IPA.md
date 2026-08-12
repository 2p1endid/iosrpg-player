# 构建与导出 IPA

## 当前环境结论

项目创建时的执行主机是 Windows 10。该主机没有：

- Xcode
- `xcodebuild`
- iOS SDK
- Apple 代码签名工具链
- 可用的 macOS SSH 构建主机
- 已配置的云端 iOS 构建凭据

因此 Windows 本机不能真实编译或签名 IPA。仓库提供完整源码、XcodeGen 工程描述和构建脚本，必须在 macOS 上执行以下步骤。

## 前置条件

1. 一台支持当前 Xcode 的 Mac。
2. 完整安装 Xcode，并至少启动一次接受许可。
3. 安装 XcodeGen：

```bash
brew install xcodegen
```

4. 真机或 App Store 构建需要 Apple Developer Program 团队。
5. 在 Xcode 中登录 Apple ID，或为 CI 配置证书和 provisioning profile。

## 生成工程并验证模拟器构建

```bash
cd /path/to/iosrpg
./scripts/build-ios.sh simulator
```

脚本会：

1. 从 `project.yml` 生成 `IOSRPGPlayer.xcodeproj`。
2. 编译 iOS Simulator 目标。
3. 运行 iOS 单元测试。

如果默认模拟器不存在，可以直接运行：

```bash
xcrun simctl list devices available
```

然后修改脚本中的 destination。

## 生成无签名设备归档

无签名归档可以验证设备架构编译，但不能安装：

```bash
./scripts/build-ios.sh archive-unsigned
```

输出：

```text
build/IOSRPGPlayer.xcarchive
```

GitHub Actions 还会把该归档中的设备 App 按标准 `Payload/IOSRPGPlayer.app` 结构封装为：

```text
IOSRPGPlayer-unsigned.ipa
```

该文件扩展名和目录结构是 IPA，但由于没有 Apple 证书和 provisioning profile，它仍然不能直接安装到普通 iPhone。它用于验证设备架构构建，或者交给合法的个人开发签名/CI 签名流程继续签名。

部分 Windows 重签名工具（包括某些 Sideloadly 版本）会把“完全没有 Mach-O `LC_CODE_SIGNATURE` 的二进制”直接判定为 `Invalid file`，还没有进入 Apple Account 重签名阶段。因此工作流会额外对设备 App 做一次不含开发者身份和 provisioning profile 的 ad-hoc 签名，并输出：

```text
IOSRPGPlayer-sideloadly.ipa
```

这个文件包含可被重签名工具识别和替换的 `_CodeSignature`/`LC_CODE_SIGNATURE`，但它仍不是可直接安装的开发者签名 IPA。使用 Sideloadly 时应选择该文件，而不是 `IOSRPGPlayer-unsigned.ipa`。

## 导出已签名 IPA

首先复制配置模板：

```bash
cp ExportOptions.example.plist ExportOptions.plist
```

在 `ExportOptions.plist` 中填写自己的 `teamID`，并根据分发方式选择：

- `development`
- `ad-hoc`
- `app-store-connect`

然后执行：

```bash
DEVELOPMENT_TEAM=你的团队ID ./scripts/build-ios.sh ipa
```

预期输出：

```text
build/ipa/IOSRPGPlayer.ipa
```

## 重要说明

- 不要把个人证书、私钥、密码、API Key 或 provisioning profile 提交到仓库。
- `com.example.iosrpgplayer` 只是占位 Bundle ID，签名前应替换成自己账号下的唯一 ID。
- 如果只需要在自己的设备临时测试，也仍然需要由 Xcode 完成签名安装。
- 任何“IPA 构建成功”的结论都必须以 macOS 上 `xcodebuild -exportArchive` 的真实成功输出和实际文件为准。
