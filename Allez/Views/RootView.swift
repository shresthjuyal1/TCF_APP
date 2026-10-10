import SwiftUI

/// The tab bar at the bottom of the app.
struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Path", systemImage: "map.fill") }
            SkillPracticeView(skill: .reading)
                .tabItem { Label("Reading", systemImage: "book.fill") }
            SkillPracticeView(skill: .grammar)
                .tabItem { Label("Grammar", systemImage: "textformat.abc") }
            SpeakingView()
                .tabItem { Label("Speaking", systemImage: "mic.fill") }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .fontDesign(.rounded)
}
