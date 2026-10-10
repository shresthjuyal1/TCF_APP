import SwiftUI

@main
struct AllezApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .fontDesign(.rounded)
                .tint(Theme.accent)
        }
    }
}
