import SwiftUI

/// The tab bar at the bottom of the app.
struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Parcours", systemImage: "map.fill") }
            SkillPracticeView(skill: .reading)
                .tabItem { Label("Lecture", systemImage: "book.fill") }
            SkillPracticeView(skill: .grammar)
                .tabItem { Label("Grammaire", systemImage: "textformat.abc") }
            SpeakingView()
                .tabItem { Label("Oral", systemImage: "mic.fill") }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .fontDesign(.rounded)
}
