import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case chinese = "zh-Hans"
    case english = "en"

    static let storageKey = "rrppgo.interface-language"

    var id: String { rawValue }
    var locale: Locale { Locale(identifier: rawValue) }
    var nativeName: String { self == .chinese ? "中文" : "English" }
    var colon: String { self == .chinese ? "：" : ":" }
    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "") ?? .chinese
    }

    func text(_ key: AppTextKey) -> String {
        switch self {
        case .chinese: return key.chinese
        case .english: return key.english
        }
    }
}

enum AppTextKey {
    case myGames, testEnvironment, importZIP, importFolder, about, more, language
    case importFailed, ok, unknownError, noGames, noGamesDescription, openTestEnvironment, delete
    case keepAppForeground, gameLibrary, runtimeDiagnostics, hideController, showController, reload
    case hideToolbar, showGameToolbar, noDiagnostics, diagnosticsDescription, actions, copyCurrentError
    case copyFullDiagnostics, shareFullDiagnostics, clearDiagnostics, currentStatus, game, status, done
    case copied, currentErrorCopied, fullDiagnosticsCopied
    case aboutSoftware, version, author, githubRepository, license, localPlayerSubtitle, aboutDescription
    case thirdPartyProjects, zipExtraction, projectGeneration, ciCheckout, ciUpload, thirdPartyNotice
    case preparingImport, extracting, scanning, copying, saving, imported, deleted
    case unsupportedProject, inaccessibleFolder, copyFailed, invalidArchive, unsafeArchive, archiveTooLarge, importInProgress
    case invalidPath, absolutePath, pathTraversal, missingResource, loadFailed, resourceLoadFailed
    case noGameMessage, preparingGame, builtinTestGame, preparingBuiltinGame, missingGameDirectory, unableToStart
    case startingServer, loadingGame, serverStartFailed, reloadingGame, keySendFailed, virtualKeyInjectionFailed
    case virtualKeySent, testGameLoaded, gameLoaded, webKitTerminated, runtimeFailed
    case controllerSettings, controllerButton, buttonLabel, buttonMapping, buttonSize, buttonColor
    case deleteCustomButton, addButton, resetDefaults
    case saveManagement, currentSave, capturedAt, saveEntries, captureNow, backupName, createBackup
    case noSaveSnapshot, backups, noBackups, restore, cancel, selectButton, restoreOnNextLaunch

    var chinese: String {
        switch self {
        case .myGames: "我的游戏"
        case .testEnvironment: "测试环境"
        case .importZIP: "导入 ZIP"
        case .importFolder: "导入文件夹"
        case .about: "关于"
        case .more: "更多"
        case .language: "语言"
        case .importFailed: "导入失败"
        case .ok: "好"
        case .unknownError: "未知错误"
        case .noGames: "还没有游戏"
        case .noGamesDescription: "导入 RPG Maker MV/MZ ZIP，或选择已经解压的项目文件夹。"
        case .openTestEnvironment: "打开内置测试环境"
        case .delete: "删除"
        case .keepAppForeground: "请保持 App 在前台，导入完成后会自动打开游戏。"
        case .gameLibrary: "游戏库"
        case .runtimeDiagnostics: "运行诊断"
        case .hideController: "隐藏虚拟手柄"
        case .showController: "显示虚拟手柄"
        case .reload: "重新加载"
        case .hideToolbar: "隐藏工具栏"
        case .showGameToolbar: "显示游戏工具栏"
        case .noDiagnostics: "暂无诊断"
        case .diagnosticsDescription: "运行错误、HTTP 错误和控制台信息会显示在这里。"
        case .actions: "操作"
        case .copyCurrentError: "复制当前错误"
        case .copyFullDiagnostics: "复制完整诊断"
        case .shareFullDiagnostics: "分享完整诊断"
        case .clearDiagnostics: "清除诊断"
        case .currentStatus: "当前状态"
        case .game: "游戏"
        case .status: "状态"
        case .done: "完成"
        case .copied: "已复制"
        case .currentErrorCopied: "当前错误已复制到剪贴板。"
        case .fullDiagnosticsCopied: "完整诊断已复制到剪贴板。"
        case .aboutSoftware: "关于软件"
        case .version: "版本"
        case .author: "作者"
        case .githubRepository: "GitHub 项目主页"
        case .license: "许可证"
        case .localPlayerSubtitle: "RPG Maker MV/MZ 本地播放器"
        case .aboutDescription: "RRPPGo 是一个面向 iPhone 和 iPad 的开源 RPG Maker MV/MZ 本地游戏播放器。游戏文件由用户自行导入，项目不包含或分发任何商业游戏资源。"
        case .thirdPartyProjects: "第三方开源项目"
        case .zipExtraction: "ZIP 解压"
        case .projectGeneration: "工程生成"
        case .ciCheckout: "CI 源码检出"
        case .ciUpload: "CI 构建产物上传"
        case .thirdPartyNotice: "第三方项目保留各自的许可证与版权。"
        case .preparingImport: "准备导入"
        case .extracting: "正在解压"
        case .scanning: "正在识别游戏"
        case .copying: "正在复制游戏"
        case .saving: "正在保存游戏库"
        case .imported: "已导入"
        case .deleted: "已删除"
        case .unsupportedProject: "所选文件夹中没有找到受支持的 RPG Maker MV/MZ 游戏。"
        case .inaccessibleFolder: "无法读取所选文件夹。"
        case .copyFailed: "复制游戏文件失败。"
        case .invalidArchive: "ZIP 文件损坏或格式不受支持。"
        case .unsafeArchive: "ZIP 包含不安全的路径或符号链接。"
        case .archiveTooLarge: "ZIP 内容过大，已停止导入。"
        case .importInProgress: "已有游戏正在导入，请稍候。"
        case .invalidPath: "资源路径无效。"
        case .absolutePath: "不允许访问绝对路径。"
        case .pathTraversal: "资源路径超出了游戏目录。"
        case .missingResource: "找不到游戏资源"
        case .loadFailed: "加载失败"
        case .resourceLoadFailed: "资源加载失败"
        case .noGameMessage: "尚未收到游戏消息"
        case .preparingGame: "正在准备"
        case .builtinTestGame: "内置测试游戏"
        case .preparingBuiltinGame: "正在准备内置 MZ 兼容测试游戏…"
        case .missingGameDirectory: "找不到游戏目录。"
        case .unableToStart: "无法启动"
        case .startingServer: "正在启动本地游戏服务器…"
        case .loadingGame: "正在加载"
        case .serverStartFailed: "本地游戏服务器启动失败"
        case .reloadingGame: "正在重新加载"
        case .keySendFailed: "发送按键失败"
        case .virtualKeyInjectionFailed: "虚拟按键注入失败"
        case .virtualKeySent: "虚拟按键已发送"
        case .testGameLoaded: "测试游戏已加载。请使用屏幕按键移动方块。"
        case .gameLoaded: "已加载。"
        case .webKitTerminated: "WebKit 游戏进程意外终止。"
        case .runtimeFailed: "运行失败"
        case .controllerSettings: "按键设置"
        case .controllerButton: "按键"
        case .buttonLabel: "显示名称"
        case .buttonMapping: "按键映射"
        case .buttonSize: "大小"
        case .buttonColor: "颜色"
        case .deleteCustomButton: "删除自定义按键"
        case .addButton: "添加按键"
        case .resetDefaults: "恢复默认"
        case .saveManagement: "存档管理"
        case .currentSave: "当前存档"
        case .capturedAt: "捕获时间"
        case .saveEntries: "存档条目"
        case .captureNow: "立即捕获"
        case .backupName: "备份名称"
        case .createBackup: "创建备份"
        case .noSaveSnapshot: "尚无原生存档快照。"
        case .backups: "备份"
        case .noBackups: "暂无备份"
        case .restore: "恢复"
        case .cancel: "取消"
        case .selectButton: "请选择一个按键"
        case .restoreOnNextLaunch: "恢复后的存档会在下次启动该游戏时生效。"
        }
    }

    var english: String {
        switch self {
        case .myGames: "My Games"
        case .testEnvironment: "Test Environment"
        case .importZIP: "Import ZIP"
        case .importFolder: "Import Folder"
        case .about: "About"
        case .more: "More"
        case .language: "Language"
        case .importFailed: "Import Failed"
        case .ok: "OK"
        case .unknownError: "Unknown error"
        case .noGames: "No Games Yet"
        case .noGamesDescription: "Import an RPG Maker MV/MZ ZIP or select an extracted project folder."
        case .openTestEnvironment: "Open Built-in Test Environment"
        case .delete: "Delete"
        case .keepAppForeground: "Keep the app in the foreground. The game opens automatically after import."
        case .gameLibrary: "Game Library"
        case .runtimeDiagnostics: "Runtime Diagnostics"
        case .hideController: "Hide Virtual Controller"
        case .showController: "Show Virtual Controller"
        case .reload: "Reload"
        case .hideToolbar: "Hide Toolbar"
        case .showGameToolbar: "Show Game Toolbar"
        case .noDiagnostics: "No Diagnostics"
        case .diagnosticsDescription: "Runtime, HTTP, and console errors appear here."
        case .actions: "Actions"
        case .copyCurrentError: "Copy Current Error"
        case .copyFullDiagnostics: "Copy Full Diagnostics"
        case .shareFullDiagnostics: "Share Full Diagnostics"
        case .clearDiagnostics: "Clear Diagnostics"
        case .currentStatus: "Current Status"
        case .game: "Game"
        case .status: "Status"
        case .done: "Done"
        case .copied: "Copied"
        case .currentErrorCopied: "The current error was copied to the clipboard."
        case .fullDiagnosticsCopied: "The full diagnostic report was copied to the clipboard."
        case .aboutSoftware: "About"
        case .version: "Version"
        case .author: "Author"
        case .githubRepository: "GitHub Repository"
        case .license: "License"
        case .localPlayerSubtitle: "RPG Maker MV/MZ Local Player"
        case .aboutDescription: "RRPPGo is an open-source local player for RPG Maker MV/MZ games on iPhone and iPad. Game files are imported by the user; the project does not include or distribute commercial game assets."
        case .thirdPartyProjects: "Third-Party Open Source"
        case .zipExtraction: "ZIP extraction"
        case .projectGeneration: "Project generation"
        case .ciCheckout: "CI source checkout"
        case .ciUpload: "CI artifact upload"
        case .thirdPartyNotice: "Third-party projects retain their respective licenses and copyrights."
        case .preparingImport: "Preparing Import"
        case .extracting: "Extracting"
        case .scanning: "Identifying Game"
        case .copying: "Copying Game"
        case .saving: "Saving Game Library"
        case .imported: "Imported"
        case .deleted: "Deleted"
        case .unsupportedProject: "No supported RPG Maker MV/MZ game was found in the selected folder."
        case .inaccessibleFolder: "The selected folder could not be read."
        case .copyFailed: "Copying the game files failed."
        case .invalidArchive: "The ZIP is damaged or uses an unsupported format."
        case .unsafeArchive: "The ZIP contains an unsafe path or symbolic link."
        case .archiveTooLarge: "The ZIP is too large, so import was stopped."
        case .importInProgress: "Another game is being imported. Please wait."
        case .invalidPath: "The resource path is invalid."
        case .absolutePath: "Absolute paths are not allowed."
        case .pathTraversal: "The resource path escapes the game directory."
        case .missingResource: "Game resource not found"
        case .loadFailed: "Load Failed"
        case .resourceLoadFailed: "Resource load failed"
        case .noGameMessage: "No game message received yet"
        case .preparingGame: "Preparing"
        case .builtinTestGame: "Built-in Test Game"
        case .preparingBuiltinGame: "Preparing the built-in MZ compatibility test game…"
        case .missingGameDirectory: "The game directory could not be found."
        case .unableToStart: "Unable to Start"
        case .startingServer: "Starting the local game server…"
        case .loadingGame: "Loading"
        case .serverStartFailed: "The local game server failed to start"
        case .reloadingGame: "Reloading"
        case .keySendFailed: "Sending the key failed"
        case .virtualKeyInjectionFailed: "Virtual key injection failed"
        case .virtualKeySent: "Virtual key sent"
        case .testGameLoaded: "The test game is loaded. Use the on-screen controls to move the square."
        case .gameLoaded: "loaded."
        case .webKitTerminated: "The WebKit game process terminated unexpectedly."
        case .runtimeFailed: "Runtime Failed"
        case .controllerSettings: "Controller Settings"
        case .controllerButton: "Button"
        case .buttonLabel: "Label"
        case .buttonMapping: "Mapping"
        case .buttonSize: "Size"
        case .buttonColor: "Color"
        case .deleteCustomButton: "Delete Custom Button"
        case .addButton: "Add Button"
        case .resetDefaults: "Reset Defaults"
        case .saveManagement: "Save Management"
        case .currentSave: "Current Save"
        case .capturedAt: "Captured"
        case .saveEntries: "Entries"
        case .captureNow: "Capture Now"
        case .backupName: "Backup Name"
        case .createBackup: "Create Backup"
        case .noSaveSnapshot: "No native save snapshot is available yet."
        case .backups: "Backups"
        case .noBackups: "No Backups"
        case .restore: "Restore"
        case .cancel: "Cancel"
        case .selectButton: "Select a button"
        case .restoreOnNextLaunch: "The restored save takes effect the next time this game starts."
        }
    }
}

@propertyWrapper
struct AppLanguageStorage: DynamicProperty {
    @AppStorage(AppLanguage.storageKey) private var rawValue = AppLanguage.chinese.rawValue

    var wrappedValue: AppLanguage {
        get { AppLanguage(rawValue: rawValue) ?? .chinese }
        nonmutating set { rawValue = newValue.rawValue }
    }

    var projectedValue: Binding<AppLanguage> {
        Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
    }
}
