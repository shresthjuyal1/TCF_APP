import SwiftUI

/// The home screen: a winding path of units grouped by level.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var activeUnit: LessonUnit?
    @State private var comingSoonUnit: LessonUnit?
    @State private var lockedTapCount = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Level.allCases) { level in
                        LevelBanner(level: level)
                            .padding(.top, 24)
                            .padding(.bottom, 12)

                        ForEach(appState.units.filter { $0.level == level }) { unit in
                            let index = appState.units.firstIndex(of: unit) ?? 0
                            UnitNode(unit: unit, status: appState.status(of: unit)) {
                                open(unit)
                            }
                            .offset(x: pathOffset(for: index))
                            .padding(.vertical, 12)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationTitle("Allez!")
        }
        .fullScreenCover(item: $activeUnit) { unit in
            LessonView(unit: unit) {
                appState.complete(unit)
            }
        }
        .alert("Bientôt disponible", isPresented: Binding(
            get: { comingSoonUnit != nil },
            set: { if !$0 { comingSoonUnit = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text("Les questions de « \(comingSoonUnit?.title ?? "") » arrivent bientôt.")
        }
        .sensoryFeedback(.warning, trigger: lockedTapCount)
    }

    private func open(_ unit: LessonUnit) {
        switch appState.status(of: unit) {
        case .locked:
            lockedTapCount += 1
        case .current, .completed:
            if unit.questions.isEmpty {
                comingSoonUnit = unit
            } else {
                activeUnit = unit
            }
        }
    }

    /// Sways the circles left and right to make a winding path.
    private func pathOffset(for index: Int) -> CGFloat {
        sin(Double(index) * 0.9) * 70
    }
}

private struct LevelBanner: View {
    let level: Level

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Niveau \(level.rawValue)")
                    .font(.title3.weight(.heavy))
                Text(level.name)
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.85)
            }
            Spacer()
            Image(systemName: "flag.checkered")
                .font(.title2.weight(.bold))
        }
        .foregroundStyle(.white)
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.accent))
        .background(RoundedRectangle(cornerRadius: 18).fill(Theme.accentShadow).offset(y: 4))
    }
}

private struct UnitNode: View {
    let unit: LessonUnit
    let status: UnitStatus
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if status == .current {
                StartBubble()
            }
            Button(action: action) {
                Image(systemName: iconName)
                    .font(.system(size: 30, weight: .bold))
            }
            .buttonStyle(NodeButtonStyle(status: status))

            Text(unit.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(status == .locked ? .secondary : .primary)
        }
    }

    private var iconName: String {
        switch status {
        case .completed: "checkmark"
        case .current: unit.icon
        case .locked: "lock.fill"
        }
    }
}

private struct StartBubble: View {
    var body: some View {
        Text("Commencer")
            .font(.caption.weight(.heavy))
            .textCase(.uppercase)
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Theme.card))
            .overlay(Capsule().strokeBorder(Theme.cardBorder, lineWidth: 2))
            .phaseAnimator([false, true]) { content, up in
                content.offset(y: up ? -5 : 0)
            } animation: { _ in
                .easeInOut(duration: 0.8)
            }
    }
}

private struct NodeButtonStyle: ButtonStyle {
    let status: UnitStatus

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(status == .locked ? Theme.lockedIcon : .white)
            .frame(width: 76, height: 72)
            .background(Ellipse().fill(face))
            .background(Ellipse().fill(shadow).offset(y: pressed ? 0 : 7))
            .offset(y: pressed ? 7 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressed)
    }

    private var face: Color {
        switch status {
        case .completed: Theme.gold
        case .current: Theme.accent
        case .locked: Theme.locked
        }
    }

    private var shadow: Color {
        switch status {
        case .completed: Theme.goldShadow
        case .current: Theme.accentShadow
        case .locked: Theme.lockedShadow
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .fontDesign(.rounded)
}
