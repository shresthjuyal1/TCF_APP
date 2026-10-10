import SwiftUI

/// The tab bar at the bottom of the app, plus the streak celebration on top.
struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            TabView {
                HomeView()
                    .tabItem { Label("Path", systemImage: "map.fill") }
                SkillPracticeView(skill: .reading)
                    .tabItem { Label("Reading", systemImage: "book.fill") }
                VocabView()
                    .tabItem { Label("Vocab", systemImage: "character.book.closed.fill") }
                SpeakingView()
                    .tabItem { Label("Speaking", systemImage: "mic.fill") }
            }

            if appState.showStreakCelebration {
                StreakCelebration()
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appState.showStreakCelebration)
        .task {
            if appState.settings.remindersOn {
                await Reminders.requestPermissionIfNeeded()
            }
            Reminders.reschedule(for: appState)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Reminders.reschedule(for: appState) }
        }
    }
}

#Preview {
    RootView()
        .environment(AppState())
        .fontDesign(.rounded)
}
