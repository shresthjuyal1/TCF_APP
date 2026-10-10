import SwiftUI

/// Monday to Sunday with a flame for each day you practised, a snowflake for frozen days.
struct WeekCalendar: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        let summary = appState.streak
        HStack(spacing: 6) {
            ForEach(Day.week(containing: .now), id: \.self) { date in
                let status = appState.status(of: date, in: summary)
                VStack(spacing: 6) {
                    Text(date.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(status == .pending ? Theme.orange : .secondary)
                    ZStack {
                        Circle()
                            .fill(background(for: status))
                            .frame(width: 38, height: 38)
                        Image(systemName: icon(for: status))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(foreground(for: status))
                    }
                    .overlay {
                        if status == .pending {
                            Circle().strokeBorder(Theme.orange, style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func icon(for status: DayStatus) -> String {
        switch status {
        case .practiced, .pending: "flame.fill"
        case .frozen: "snowflake"
        case .missed: "xmark"
        case .future: "circle.fill"
        }
    }

    private func background(for status: DayStatus) -> Color {
        switch status {
        case .practiced: Theme.orange
        case .frozen: Theme.freeze
        case .pending: Theme.orange.opacity(0.12)
        case .missed, .future: Theme.softFill
        }
    }

    private func foreground(for status: DayStatus) -> Color {
        switch status {
        case .practiced, .frozen: .white
        case .pending: Theme.orange.opacity(0.5)
        case .missed: Theme.lockedIcon
        case .future: Theme.locked
        }
    }
}

/// A flame drawn with a warm gradient. Grey when today's practice isn't done yet.
struct StreakFlame: View {
    let isLit: Bool
    var size: CGFloat = 22

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(isLit
                ? AnyShapeStyle(LinearGradient(colors: [Theme.gold, Theme.orange, Theme.wrong], startPoint: .top, endPoint: .bottom))
                : AnyShapeStyle(Theme.lockedIcon))
    }
}

/// Today's minutes as a small ring, e.g. 6 of 10.
struct MinutesRing: View {
    let seconds: TimeInterval
    var size: CGFloat = 26

    private var progress: Double { min(seconds / AppState.dailyGoalSeconds, 1) }

    var body: some View {
        ZStack {
            Circle().stroke(Theme.locked, lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progress >= 1 ? Theme.correct : Theme.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if progress >= 1 {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.4, weight: .heavy))
                    .foregroundStyle(Theme.correct)
            }
        }
        .frame(width: size, height: size)
        .animation(.spring, value: progress)
    }
}

/// The sheet that opens from the flame: streak count, today's minutes, the week and the freeze.
struct StreakSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let summary = appState.streak
        let minutes = Int(appState.todaySeconds / 60)
        let doneToday = appState.goalMet(on: .now)
        ScrollView {
            VStack(spacing: 22) {
                StreakFlame(isLit: doneToday, size: 80)
                    .symbolEffect(.bounce, value: summary.count)
                    .padding(.top, 28)
                VStack(spacing: 4) {
                    Text("\(summary.count)-day streak")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(doneToday ? Theme.orange : .primary)
                    Text(doneToday
                         ? "Today's 10 minutes are done. See you tomorrow!"
                         : "\(max(10 - minutes, 1)) more minute\(10 - minutes == 1 ? "" : "s") today to keep it going.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 14) {
                    MinutesRing(seconds: appState.todaySeconds, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today")
                            .font(.caption.weight(.heavy))
                            .textCase(.uppercase)
                            .foregroundStyle(.secondary)
                        Text("\(min(minutes, 999)) / 10 minutes")
                            .font(.headline)
                    }
                    Spacer()
                }
                .padding()
                .card()

                VStack(alignment: .leading, spacing: 12) {
                    Text("This week")
                        .font(.headline)
                    WeekCalendar()
                }
                .padding()
                .card()

                HStack(spacing: 14) {
                    IconTile(systemName: "snowflake", color: Theme.freeze)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.freezeUsedThisWeek ? "Streak freeze used this week" : "1 streak freeze ready")
                            .font(.headline)
                        Text("If you miss a day, it's used automatically to save your streak. You get one per week.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()

                Button("Done") { dismiss() }
                    .buttonStyle(ChunkyButtonStyle(face: Theme.orange, shadow: Theme.orangeShadow))
            }
            .padding()
        }
        .background(Theme.background)
    }
}

/// Shown the first time each day that practice reaches 10 minutes.
struct StreakCelebration: View {
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    var body: some View {
        let count = appState.streak.count
        ZStack {
            LinearGradient(colors: [Theme.gold, Theme.orange], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "flame.fill")
                    .font(.system(size: 130, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: Theme.wrong.opacity(0.4), radius: 20)
                    .scaleEffect(appeared ? 1 : 0.2)
                    .rotationEffect(.degrees(appeared ? 0 : -25))
                    .symbolEffect(.bounce, value: appeared)
                Text("\(count)")
                    .font(.system(size: 80, weight: .heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(count == 1 ? "Your streak has started!" : "day streak! Bravo, \(appState.settings.name) !")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                WeekCalendar()
                    .padding()
                    .card()
                    .padding(.horizontal)
                Spacer()
                Button("Continue") {
                    withAnimation { appState.showStreakCelebration = false }
                }
                .buttonStyle(ChunkyButtonStyle(face: .white, shadow: Theme.orangeShadow, text: Theme.orange))
                .padding()
            }
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            SoundFX.shared.play(.streak)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) { appeared = true }
        }
        .sensoryFeedback(.success, trigger: appeared)
    }
}
