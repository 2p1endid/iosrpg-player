import SwiftUI

struct LanguageSettingsView: View {
    @AppLanguageStorage private var language

    var body: some View {
        List {
            ForEach(AppLanguage.allCases) { option in
                Button {
                    language = option
                } label: {
                    HStack {
                        Text(option.nativeName)
                        Spacer()
                        if option == language {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(language.text(.language))
        .navigationBarTitleDisplayMode(.inline)
    }
}
