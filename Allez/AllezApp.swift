import SwiftUI

@main
struct AllezApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(appState)
                .fontDesign(.rounded)
                .tint(Theme.accent)
        }
    }
}
