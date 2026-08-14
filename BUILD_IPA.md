# 构建与导出 IPA / Build and Export IPA

## 中文

### 环境要求

iOS构建需要macOS、Xcode、iOS SDK和XcodeGen。Windows本机可以运行Node测试，但不能真实编译iOS设备应用。

安装XcodeGen：

```bash
brew install xcodegen
```

### 模拟器构建与测试

```bash
./scripts/build-ios.sh simulator
```

该命令会生成Xcode工程、编译模拟器App并运行iOS单元测试。

### 无签名设备归档

```bash
./scripts/build-ios.sh archive-unsigned
```

输出：

```text
build/RRPPGo.xcarchive
```

GitHub Actions会将归档中的设备App封装为：

```text
RRPPGo-unsigned.ipa
```

这是一个真正的未签名IPA：没有Apple开发者证书、provisioning profile或可安装签名，不能直接安装到普通iPhone/iPad。它用于设备架构构建验证，或交给用户自己的合法Apple签名流程。

CI不生成Sideloadly/ad-hoc变体。

### 正式签名导出

复制并填写导出配置：

```bash
cp ExportOptions.example.plist ExportOptions.plist
DEVELOPMENT_TEAM=你的团队ID ./scripts/build-ios.sh ipa
```

不要将证书、私钥、密码、API Key或provisioning profile提交到仓库。默认Bundle ID `com.example.rrppgo`只是占位值。

---

## English

### Requirements

iOS builds require macOS, Xcode, the iOS SDK, and XcodeGen. Windows can run the Node tests but cannot compile the actual iOS device app.

Install XcodeGen:

```bash
brew install xcodegen
```

### Simulator Build and Tests

```bash
./scripts/build-ios.sh simulator
```

This generates the Xcode project, builds the Simulator app, and runs the iOS unit tests.

### Unsigned Device Archive

```bash
./scripts/build-ios.sh archive-unsigned
```

Output:

```text
build/RRPPGo.xcarchive
```

GitHub Actions packages the device app from the archive as:

```text
RRPPGo-unsigned.ipa
```

This is a genuinely unsigned IPA. It contains no Apple developer certificate, provisioning profile, or installable signature and cannot be installed directly on a normal iPhone or iPad. It is intended as device-build evidence or as input to the user's own legitimate Apple signing process.

CI does not produce a Sideloadly/ad-hoc variant.

### Signed Export

Copy and configure the export options, then run:

```bash
cp ExportOptions.example.plist ExportOptions.plist
DEVELOPMENT_TEAM=YOUR_TEAM_ID ./scripts/build-ios.sh ipa
```

Never commit certificates, private keys, passwords, API keys, or provisioning profiles. The default bundle identifier `com.example.rrppgo` is only a placeholder.
