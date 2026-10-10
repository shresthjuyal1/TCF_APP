import SwiftUI

/// The Path tab: a winding path of grammar lessons grouped by level.
struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var activeUnit: LessonUnit?
    @State private var lockedUnit: LessonUnit?
    @State private var lockedTapCount = 0
    @State private var showStreak = false
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            StatsBar(showStreak: $showStreak, showSettings: $showSettings)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        if !appState.library.problems.isEmpty {
                            ContentProblemsCard(problems: appState.library.problems)
                                .padding(.top, 8)
                        }
                        GreetingCard()
                            .padding(.top, 12)
                        OverallProgress(completed: appState.units.filter(appState.isCompleted).count, total: appState.units.count)
                            .padding(.top, 12)

                        ForEach(levelsOnPath) { level in
                            levelSection(level)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
                .onAppear {
                    if let next = appState.nextUnit {
                        proxy.scrollTo(next.id, anchor: .center)
                    }
                }
            }
        }
        .background(Theme.background)
        .sheet(isPresented: $showStreak) {
            StreakSheet()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $activeUnit) { unit in
            GrammarLessonFlow(unit: unit) {
                appState.complete(unit)
            }
        }
        .alert("Lesson locked", isPresented: Binding(
            get: { lockedUnit != nil },
            set: { if !$0 { lockedUnit = nil } }
        )) {
            Button("OK") {}
        } message: {
            if let unit = lockedUnit, let previous = appState.previousUnit(of: unit) {
                Text("Finish \"\(previous.title)\" first. You can also jump ahead by starting the first lesson of any level.")
            }
        }
        .sensoryFeedback(.warning, trigger: lockedTapCount)
    }

    @ViewBuilder
    private func levelSection(_ level: Level) -> some View {
        let units = appState.units(in: level)
        LevelBanner(level: level, completed: units.filter(appState.isCompleted).count, total: units.count)
            .padding(.top, 28)
            .padding(.bottom, 16)

        ForEach(Array(units.enumerated()), id: \.element.id) { position, unit in
            let index = appState.units.firstIndex { $0.id == unit.id } ?? 0
            if position > 0 {
                PathTrail(from: pathOffset(for: index - 1), to: pathOffset(for: index), isLit: appState.isCompleted(units[position - 1]))
            }
            UnitNode(unit: unit, status: appState.status(of: unit), isNext: appState.nextUnit?.id == unit.id, colors: Theme.levelColor(level)) {
                open(unit)
            }
            .offset(x: pathOffset(for: index))
            .id(unit.id)
        }
    }

    private var levelsOnPath: [Level] {
        Level.allCases.filter { level in appState.units.contains { $0.level == level } }
    }

    private func open(_ unit: LessonUnit) {
        if appState.status(of: unit) == .locked {
            lockedTapCount += 1
            lockedUnit = unit
        } else {
            activeUnit = unit
        }
    }

    /// Sways the circles left and right to make a winding path.
    private func pathOffset(for index: Int) -> CGFloat {
        sin(Double(index) * 0.9) * 70
    }
}

/// Lists content files that couldn't be read, so typos in the JSON are easy to find.
private struct ContentProblemsCard: View {
    let problems: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Some content couldn't be loaded", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(Theme.wrong)
            ForEach(problems, id: \.self) { problem in
                Text("• " + problem)
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.wrongBackground))
    }
}

private struct OverallProgress: View {
    let completed: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(completed) of \(total) lessons complete")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundStyle(Theme.gold)
            }
            ProgressView(value: Double(completed), total: Double(max(total, 1)))
                .tint(Theme.gold)
        }
        .padding()
        .card(cornerRadius: 16)
    }
}

private struct LevelBanner: View {
    let level: Level
    let completed: Int
    let total: Int

    private var isDone: Bool { total > 0 && completed == total }

    private var levelIcon: String {
        switch level {
        case .a1: "leaf.fill"
        case .a2: "sun.max.fill"
        case .b1: "paperplane.fill"
        case .b2: "mountain.2.fill"
        case .c1: "crown.fill"
        case .c2: "trophy.fill"
        }
    }

    var body: some View {
        let colors = Theme.levelColor(level)
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Level \(level.rawValue) · \(level.name)")
                    .font(.title3.weight(.heavy))
                Text(isDone ? "Level complete!" : "\(completed) / \(total) lessons")
                    .font(.subheadline.weight(.semibold))
                    .opacity(0.9)
            }
            Spacer()
            Image(systemName: isDone ? "checkmark.seal.fill" : levelIcon)
                .font(.title.weight(.bold))
                .symbolEffect(.bounce, value: isDone)
        }
        .foregroundStyle(.white)
        .padding()
        .background(RoundedRectangle(cornerRadius: 18).fill(isDone ? Theme.gold : colors.face))
        .background(RoundedRectangle(cornerRadius: 18).fill(isDone ? Theme.goldShadow : colors.shadow).offset(y: 4))
        .shadow(color: isDone ? Theme.gold.opacity(0.5) : .clear, radius: 12)
    }
}

/// Three dots between two circles. They turn gold once the earlier lesson is finished.
private struct PathTrail: View {
    let from: CGFloat
    let to: CGFloat
    let isLit: Bool

    var body: some View {
        VStack(spacing: 7) {
            ForEach(1..<4) { step in
                Circle()
                    .fill(isLit ? Theme.gold : Theme.locked)
                    .frame(width: 9, height: 9)
                    .shadow(color: isLit ? Theme.gold.opacity(0.7) : .clear, radius: 4)
                    .offset(x: from + (to - from) * CGFloat(step) / 4)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct UnitNode: View {
    let unit: LessonUnit
    let status: UnitStatus
    let isNext: Bool
    let colors: (face: Color, shadow: Color)
    let action: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if isNext {
                StartBubble()
            }
            Button(action: action) {
                Image(systemName: iconName)
                    .font(.system(size: 30, weight: .bold))
            }
            .buttonStyle(NodeButtonStyle(status: status, isNext: isNext, colors: colors))
            .background {
                if status == .completed {
                    GoldGlow()
                }
            }

            Text(unit.title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(titleColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 170)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(unit.title), \(accessibilityStatus)")
    }

    private var iconName: String {
        switch status {
        case .completed: "checkmark"
        case .available: unit.icon
        case .locked: "lock.fill"
        }
    }

    private var titleColor: Color {
        switch status {
        case .completed: Theme.goldShadow
        case .available: .primary
        case .locked: .secondary
        }
    }

    private var accessibilityStatus: String {
        switch status {
        case .completed: "completed"
        case .available: "open"
        case .locked: "locked"
        }
    }
}

/// A soft, slowly pulsing golden glow behind finished lessons.
private struct GoldGlow: View {
    var body: some View {
        Circle()
            .fill(Theme.gold)
            .frame(width: 100, height: 100)
            .blur(radius: 18)
            .phaseAnimator([0.35, 0.6]) { glow, opacity in
                glow.opacity(opacity)
            } animation: { _ in
                .easeInOut(duration: 1.6)
            }
    }
}

private struct StartBubble: View {
    var body: some View {
        Text("Start")
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
    let isNext: Bool
    let colors: (face: Color, shadow: Color)

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        configuration.label
            .foregroundStyle(status == .locked ? Theme.lockedIcon : .white)
            .frame(width: 76, height: 72)
            .background(Ellipse().fill(face))
            .overlay(alignment: .topLeading) {
                // Glossy shine, like a sweet.
                if status != .locked {
                    Capsule()
                        .fill(.white.opacity(0.35))
                        .frame(width: 24, height: 9)
                        .rotationEffect(.degrees(-30))
                        .offset(x: 14, y: 14)
                }
            }
            .background(Ellipse().fill(shadow).offset(y: pressed ? 0 : 7))
            .overlay {
                if isNext {
                    Ellipse()
                        .strokeBorder(colors.face.opacity(0.35), lineWidth: 6)
                        .padding(-10)
                }
            }
            .offset(y: pressed ? 7 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: pressed)
    }

    private var face: Color {
        switch status {
        case .completed: Theme.gold
        case .available: colors.face
        case .locked: Theme.locked
        }
    }

    private var shadow: Color {
        switch status {
        case .completed: Theme.goldShadow
        case .available: colors.shadow
        case .locked: Theme.lockedShadow
        }
    }
}

#Preview {
    HomeView()
        .environment(AppState())
        .fontDesign(.rounded)
}

/// The bar at the top of the Path: goal, streak, today's minutes, exam countdown and settings.
private struct StatsBar: View {
    @Environment(AppState.self) private var appState
    @Binding var showStreak: Bool
    @Binding var showSettings: Bool

    var body: some View {
        let streak = appState.streak.count
        HStack(spacing: 18) {
            Button { showSettings = true } label: {
                HStack(spacing: 6) {
                    Text("🇫🇷").font(.title3)
                    Text(appState.settings.goalLevel.rawValue)
                        .foregroundStyle(Theme.levelColor(appState.settings.goalLevel).face)
                }
            }
            .accessibilityLabel("Goal \(appState.settings.goalLevel.rawValue)")

            Button { showStreak = true } label: {
                HStack(spacing: 4) {
                    StreakFlame(isLit: appState.goalMet(on: .now))
                    Text("\(streak)")
                        .foregroundStyle(appState.goalMet(on: .now) ? Theme.orange : Theme.lockedIcon)
                        .contentTransition(.numericText())
                }
            }
            .accessibilityLabel("\(streak)-day streak")

            Button { showStreak = true } label: {
                HStack(spacing: 6) {
                    MinutesRing(seconds: appState.todaySeconds, size: 22)
                    Text("\(min(Int(appState.todaySeconds / 60), 99))/10")
                        .foregroundStyle(Theme.accent)
                }
            }
            .accessibilityLabel("\(Int(appState.todaySeconds / 60)) of 10 minutes today")

            if let days = appState.daysUntilExam {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundStyle(Theme.purple)
                    Text(days > 0 ? "\(days)d" : "Today!")
                        .foregroundStyle(Theme.purple)
                }
                .accessibilityLabel("\(days) days until your TCF")
            }

            Spacer(minLength: 0)

            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .foregroundStyle(Theme.lockedIcon)
            }
            .accessibilityLabel("Settings")
        }
        .font(.headline.weight(.heavy))
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Theme.background)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.cardBorder).frame(height: 2)
        }
    }
}

/// "Bonjour Shresth !" with your level, goal and exam countdown.
private struct GreetingCard: View {
    @Environment(AppState.self) private var appState

    private var greeting: String {
        Calendar.current.component(.hour, from: .now) >= 18 ? "Bonsoir" : "Bonjour"
    }

    var body: some View {
        let settings = appState.settings
        VStack(alignment: .leading, spacing: 12) {
            Text("\(greeting) \(settings.name) ! 👋")
                .font(.title.weight(.heavy))
            HStack(spacing: 10) {
                LevelPill(title: "Now", level: appState.currentLevel)
                Image(systemName: "arrow.right")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Theme.lockedIcon)
                LevelPill(title: "Goal", level: settings.goalLevel)
                Spacer(minLength: 0)
            }
            if let days = appState.daysUntilExam {
                Label(days > 0 ? "\(days) day\(days == 1 ? "" : "s") until your TCF" : "Your TCF is today. Bonne chance !",
                      systemImage: "calendar.badge.clock")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.purple)
            }
            if appState.currentLevel == nil {
                Text("Take a full Reading test to see your current level.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

private struct LevelPill: View {
    let title: String
    let level: Level?

    var body: some View {
        let color = level.map { Theme.levelColor($0).face } ?? Theme.lockedIcon
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.heavy))
                .textCase(.uppercase)
            Text(level?.rawValue ?? "?")
                .font(.headline.weight(.heavy))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.gradient))
    }
}
