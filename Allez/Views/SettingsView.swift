import SwiftUI

/// Your name, exam date, goal and reminder time.
struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var appState = appState
        NavigationStack {
            Form {
                Section {
                    Label {
                        TextField("Your name", text: $appState.settings.name)
                    } icon: {
                        IconTile(systemName: "person.fill", color: Theme.pink, size: 30)
                    }
                } header: {
                    Text("You")
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { appState.settings.examDate != nil },
                        set: { appState.settings.examDate = $0 ? Day.adding(60, to: .now) : nil }
                    )) {
                        Label {
                            Text("I've booked my TCF")
                        } icon: {
                            IconTile(systemName: "calendar", color: Theme.purple, size: 30)
                        }
                    }
                    if let examDate = appState.settings.examDate {
                        DatePicker("Exam date", selection: Binding(
                            get: { examDate },
                            set: { appState.settings.examDate = $0 }
                        ), in: Date.now..., displayedComponents: .date)
                    }
                    Picker(selection: $appState.settings.goalLevel) {
                        ForEach(Level.allCases) { level in
                            Text("\(level.rawValue) · \(level.name)").tag(level)
                        }
                    } label: {
                        Label {
                            Text("My goal")
                        } icon: {
                            IconTile(systemName: "target", color: Theme.correct, size: 30)
                        }
                    }
                } header: {
                    Text("Exam")
                }

                Section {
                    Toggle(isOn: $appState.settings.remindersOn) {
                        Label {
                            Text("Daily reminder")
                        } icon: {
                            IconTile(systemName: "bell.fill", color: Theme.orange, size: 30)
                        }
                    }
                    .onChange(of: appState.settings.remindersOn) { _, isOn in
                        if isOn { Task { await Reminders.requestPermissionIfNeeded() } }
                    }
                    if appState.settings.remindersOn {
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Streak")
                } footer: {
                    Text("Only sent on days you haven't practised your 10 minutes yet.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Day.calendar.date(bySettingHour: appState.settings.reminderHour,
                                  minute: appState.settings.reminderMinute, second: 0, of: .now) ?? .now
            },
            set: { date in
                let parts = Day.calendar.dateComponents([.hour, .minute], from: date)
                appState.settings.reminderHour = parts.hour ?? 19
                appState.settings.reminderMinute = parts.minute ?? 0
            }
        )
    }
}
