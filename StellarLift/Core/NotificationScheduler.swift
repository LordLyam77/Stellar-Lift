import Foundation
import UserNotifications
import SwiftData

public enum NotificationScheduler {
    public static let shared = NotificationCenterDelegateCoordinator()

    public static func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            return granted
        } catch {
            return false
        }
    }

    public static func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Schedule local rest timer completion alert
    public static func scheduleRestTimerCompleted(seconds: Int) {
        guard seconds > 0 else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["active_rest_timer"])

        let content = UNMutableNotificationContent()
        content.title = "Rest Time Over ⏱️"
        content.body = "Time to crush the next set. Let's go!"
        content.sound = .default
        content.interruptionLevel = .active

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: "active_rest_timer", content: content, trigger: trigger)
        center.add(request)
    }

    public static func cancelRestTimerNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["active_rest_timer"])
    }

    /// Rebuild all rolling weekly schedule reminders based on WeeklySchedule
    @MainActor
    public static func rebuildSplitReminders(schedules: [WeeklySchedule], sessions: [WorkoutSession]) {
        let center = UNUserNotificationCenter.current()

        // Remove existing weekday notifications
        let weekdayIds = (1...7).map { "weekday_reminder_\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: weekdayIds)

        for sched in schedules where sched.isReminderEnabled {
            let content = UNMutableNotificationContent()
            content.sound = .default

            if let split = sched.splitDay {
                if split.isCardioDay {
                    content.title = "Cardio Today 🏃"
                    content.body = "Cardio session today — 30 min steady zone 2 conditioning."
                } else {
                    content.title = "Today is \(split.name) 💪"
                    let exNames = split.sortedPlannedExercises.compactMap { $0.exercise?.name }
                    let exCount = exNames.count
                    let exList = exNames.prefix(4).joined(separator: ", ")

                    // Calculate days since last session of this split
                    var daysSinceText = ""
                    if let lastSession = sessions.first(where: { $0.isFinished && $0.splitDay?.id == split.id }) {
                        let days = Calendar.current.dateComponents([.day], from: lastSession.date, to: Date()).day ?? 0
                        daysSinceText = " Last \(split.name) was \(days) days ago."
                    }

                    if exCount > 0 {
                        content.body = "\(exList) — \(exCount) exercises.\(daysSinceText)"
                    } else {
                        content.body = "Scheduled for today.\(daysSinceText)"
                    }
                }
            } else {
                content.title = "Rest Day 🧘"
                content.body = "Rest day. Prioritize recovery and nutrition — do not touch a barbell."
            }

            var dateComponents = DateComponents()
            dateComponents.weekday = sched.dayOfWeek
            dateComponents.hour = sched.reminderTimeHour
            dateComponents.minute = sched.reminderTimeMinute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "weekday_reminder_\(sched.dayOfWeek)",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    /// Schedule Sunday evening summary notification
    public static func scheduleSundaySummary(sessionsCount: Int, tonnageKg: Double, prsCount: Int) {
        let center = UNUserNotificationCenter.current()
        let id = "weekly_sunday_summary"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Weekly Training Debrief 🌌"
        let tonnageStr = tonnageKg >= 1000 ? String(format: "%.1ft", tonnageKg / 1000.0) : "\(Int(tonnageKg))kg"
        content.body = "This week: \(sessionsCount) sessions, \(tonnageStr) tonnage, \(prsCount) PRs conquered."
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 20   // 8:00 PM
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    /// Schedule optional post-workout feeling check (2 hours after workout)
    public static func schedulePostWorkoutPrompt() {
        let center = UNUserNotificationCenter.current()
        let id = "post_workout_prompt"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Session Reflection 💭"
        content.body = "How did that workout feel? Rate your energy & RPE."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: false) // 2 hours
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    /// Inactivity nudge if no workouts logged in N days (default 3 days)
    public static func scheduleInactivityNudge(days: Int) {
        guard days > 0 else { return }
        let center = UNUserNotificationCenter.current()
        let id = "inactivity_nudge"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "Stellar Lift Calling 🚀"
        content.body = "It's been \(days) days since your last logged workout. Time to hit the iron!"
        content.sound = .default

        let seconds = Double(days) * 86400.0
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }
}

public final class NotificationCenterDelegateCoordinator: NSObject, UNUserNotificationCenterDelegate {
    public override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
