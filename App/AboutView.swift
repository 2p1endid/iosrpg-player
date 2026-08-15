import SwiftUI

struct AboutView: View {
    @AppLanguageStorage private var language
    private let author = "2p1endid"
    private let repositoryURL = URL(string: "https://github.com/2p1endid/rrppgo")!

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.1.1"
    }

    var body: some View {
        List {
            Section(language.text(.aboutSoftware)) {
                aboutHeader
                infoRow(language.text(.version), value: version)
                infoRow(language.text(.author), value: author)
                Link(destination: repositoryURL) {
                    Label(language.text(.githubRepository), systemImage: "link")
                }
                infoRow(language.text(.license), value: "MIT License")
                Text(language.text(.aboutDescription))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Section(language.text(.thirdPartyProjects)) {
                projectRow("ZIPFoundation", license: "MIT", usage: language.text(.zipExtraction))
                projectRow("XcodeGen", license: "MIT", usage: language.text(.projectGeneration))
                projectRow("actions/checkout", license: "MIT", usage: language.text(.ciCheckout))
                projectRow("actions/upload-artifact", license: "MIT", usage: language.text(.ciUpload))
                Text(language.text(.thirdPartyNotice))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(language.text(.about))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var aboutHeader: some View {
        HStack(spacing: 16) {
            AppIconImage(size: 72)
            VStack(alignment: .leading, spacing: 4) {
                Text("RRPPGo").font(.title3.bold())
                Text(language.text(.localPlayerSubtitle))
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
