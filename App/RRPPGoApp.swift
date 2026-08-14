import SwiftUI

@main
struct RRPPGoApp: App {
    @AppLanguageStorage private var language

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, language.locale)
        }
    }
}
