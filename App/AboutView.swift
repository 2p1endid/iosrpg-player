import SwiftUI

struct AboutView: View {
    private let author = "2p1endid"
    private let repositoryURL = URL(string: "https://github.com/2p1endid/rrppgo")!

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "14"
    }

    var body: some View {
        List {
            Section("关于软件") {
                aboutHeader
                infoRow("版本", value: "\(version)（构建 \(build)）")
                infoRow("作者", value: author)
                Link(destination: repositoryURL) {
                    Label("GitHub 项目主页", systemImage: "link")
                }
                infoRow("许可证", value: "MIT License")
                Text("RRPPGo 是一个面向 iPhone 和 iPad 的开源 RPG Maker MV/MZ 本地游戏播放器。游戏文件由用户自行导入，项目不包含或分发任何商业游戏资源。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("About") {
                infoRow("Version", value: "\(version) (Build \(build))")
                infoRow("Author", value: author)
                Link(destination: repositoryURL) {
                    Label("GitHub Repository", systemImage: "link")
                }
                infoRow("License", value: "MIT License")
                Text("RRPPGo is an open-source local player for RPG Maker MV/MZ games on iPhone and iPad. Game files are imported by the user; this project does not include or distribute commercial game assets.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section("第三方开源项目 / Third-Party Open Source") {
                projectRow("ZIPFoundation", license: "MIT", usage: "ZIP 解压 / ZIP extraction")
                projectRow("XcodeGen", license: "MIT", usage: "工程生成 / Project generation")
                projectRow("actions/checkout", license: "MIT", usage: "CI 源码检出 / CI source checkout")
                projectRow("actions/upload-artifact", license: "MIT", usage: "CI 构建产物上传 / CI artifact upload")
                Text("第三方项目保留各自的许可证与版权。\nThird-party projects remain subject to their respective licenses and copyrights.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("关于 / About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var aboutHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: "gamecontroller.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .padding(15)
                .background(.blue.gradient)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 4) {
                Text("RRPPGo").font(.title3.bold())
                Text("RPG Maker MV/MZ 本地播放器")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("RPG Maker MV/MZ local player")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func infoRow(_ title: String, value: String) -> some View {
        LabeledContent(title, value: value)
    }

    private func projectRow(_ name: String, license: String, usage: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name).font(.headline)
            Text("\(usage) · \(license)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
