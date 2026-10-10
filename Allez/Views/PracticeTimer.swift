import SwiftUI

/// Counts the time a practice screen is open (and the app is in front) toward today's 10 minutes.
private struct PracticeTimeTracker: ViewModifier {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @State private var startedAt: Date?

    func body(content: Content) -> some View {
        content
            .onAppear { startedAt = .now }
            .onDisappear { flush() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    startedAt = startedAt ?? .now
                } else {
                    flush()
                }
            }
    }

    private func flush() {
        guard let startedAt else { return }
        appState.addPractice(seconds: Date.now.timeIntervalSince(startedAt))
        self.startedAt = nil
    }
}

extension View {
    /// Adds the time this screen is open to today's practice time.
    func tracksPracticeTime() -> some View {
        modifier(PracticeTimeTracker())
    }
}
