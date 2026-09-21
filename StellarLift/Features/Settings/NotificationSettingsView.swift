import SwiftUI
import SwiftData
import UserNotifications

public struct NotificationSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeeklySchedule.dayOfWeek) private var schedules: [WeeklySchedule]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @AppStorage("inactivityNudgeEnabled") private var inactivityNudgeEnabled: Bool = false
    @AppStorage("inactivityNudgeDays") private var inactivityNudgeDays: Int = 3
    @AppStorage("sundaySummaryEnabled") private var sundaySummaryEnabled: Bool = true
    @AppStorage("postWorkoutPromptEnabled") private var postWorkoutPromptEnabled: Bool = false

    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined

    public var body: some View {
        ZStack {
            StarfieldBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Permission Banner if not authorized
                    if authorizationStatus != .authorized {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                    .foregroundColor(selectedTheme.secondaryAccent)
                                Text("NOTIFICATIONS PERMISSION")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)
                                    .tracking(1.0)
                            }
                            Text("Enable local notifications so Stellar Lift can alert you when rest timers finish and remind you of your daily workout split.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(selectedTheme.textPrimary)

                            Button {
                                Task {
                                    let granted = await NotificationScheduler.requestAuthorization()
                                    if granted {
                                        authorizationStatus = .authorized
                                        NotificationScheduler.rebuildSplitReminders(schedules: schedules, sessions: sessions)
                                    }
                                }
                            } label: {
                                Text("Allow Local Notifications")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedTheme.primaryAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 20, strokeColor: selectedTheme.secondaryAccent.opacity(0.4))
                        .padding(.horizontal, 20)
                    }

                    // Weekday Split Reminders
                    VStack(alignment: .leading, spacing: 12) {
                        Text("WEEKDAY SPLIT REMINDERS")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)
                            .padding(.horizontal, 4)

                        // Monday first: 2, 3, 4, 5, 6, 7, 1
                        let mondayFirstDays = [2, 3, 4, 5, 6, 7, 1]
                        ForEach(mondayFirstDays, id: \.self) { day in
                            if let sched = schedules.first(where: { $0.dayOfWeek == day }) {
                                WeekdayReminderRow(schedule: sched) {
                                    NotificationScheduler.rebuildSplitReminders(schedules: schedules, sessions: sessions)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Additional Smart Alerts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SMART NUDGES & SUMMARIES")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)
                            .padding(.horizontal, 4)

                        VStack(spacing: 12) {
                            // Sunday Summary Toggle
                            Toggle(isOn: $sundaySummaryEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Sunday Evening Training Debrief")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)
                                    Text("Total tonnage, sessions, and ready-to-progress lifts")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondary)
                                }
                            }
                            .tint(selectedTheme.primaryAccent)

                            Divider().background(selectedTheme.stroke)

                            // Inactivity Nudge Toggle + Stepper
                            VStack(alignment: .leading, spacing: 8) {
                                Toggle(isOn: $inactivityNudgeEnabled) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Inactivity Nudge")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(selectedTheme.textPrimary)
                                        Text("Gentle reminder if you haven't logged in N days")
                                            .font(.system(size: 12, weight: .regular, design: .rounded))
                                            .foregroundColor(selectedTheme.textSecondary)
                                    }
                                }
                                .tint(selectedTheme.primaryAccent)

                                if inactivityNudgeEnabled {
                                    Stepper("Remind after \(inactivityNudgeDays) days inactive", value: $inactivityNudgeDays, in: 2...7)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(selectedTheme.secondaryAccent)
                                }
                            }

                            Divider().background(selectedTheme.stroke)

                            // Post-workout prompt
                            Toggle(isOn: $postWorkoutPromptEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Post-Workout Reflection")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)
                                    Text("Prompt 2 hours later to log RPE and recovery notes")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondary)
                                }
                            }
                            .tint(selectedTheme.primaryAccent)
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 18)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Notifications")
        .task {
            authorizationStatus = await NotificationScheduler.checkAuthorizationStatus()
        }
        .onChange(of: sundaySummaryEnabled) { _, enabled in
            if enabled {
                NotificationScheduler.scheduleSundaySummary(sessionsCount: 5, tonnageKg: 12400, prsCount: 3)
            }
        }
        .onChange(of: inactivityNudgeEnabled) { _, enabled in
            if enabled {
                NotificationScheduler.scheduleInactivityNudge(days: inactivityNudgeDays)
            }
        }
    }
}

public struct WeekdayReminderRow: View {
    @Bindable var schedule: WeeklySchedule
    public let onChange: () -> Void
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(schedule.weekdayName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textPrimary)

                Text(schedule.splitDay?.name ?? "Rest Day")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(schedule.splitDay != nil ? selectedTheme.secondaryAccent : selectedTheme.textMuted)
            }

            Spacer()

            if schedule.isReminderEnabled {
                DatePicker(
                    "",
                    selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = schedule.reminderTimeHour
                            components.minute = schedule.reminderTimeMinute
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { newDate in
                            let comp = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            schedule.reminderTimeHour = comp.hour ?? 8
                            schedule.reminderTimeMinute = comp.minute ?? 0
                            onChange()
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
            }

            Toggle("", isOn: $schedule.isReminderEnabled)
                .labelsHidden()
                .tint(selectedTheme.primaryAccent)
                .onChange(of: schedule.isReminderEnabled) { _, _ in
                    onChange()
                }
        }
        .padding(14)
        .glassCard(cornerRadius: 14)
    }
}
