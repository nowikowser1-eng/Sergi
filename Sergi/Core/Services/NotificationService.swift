import Foundation
import UserNotifications
import SwiftData

// MARK: - Notification Service

@Observable
final class NotificationService {
    static let shared = NotificationService()

    private(set) var isAuthorized = false

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Quiet Days Logic

    /// Determines if today should be a "quiet day" — reduced or no notifications.
    /// Uses heuristics based on recent completion patterns, mood, and streak health.
    func isQuietDay(habits: [Habit], journalEntries: [JournalEntry]) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Factor 1: Completion rate last 3 days — if consistently high, allow a rest day
        let recentDays = 3
        var recentCompletionRates: [Double] = []
        for dayOffset in 1...recentDays {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let activeHabits = habits.filter { $0.isActive }
            guard !activeHabits.isEmpty else { continue }
            let completed = activeHabits.filter { habit in
                habit.entries.contains { calendar.startOfDay(for: $0.date) == dayStart && $0.isCompleted }
            }.count
            recentCompletionRates.append(Double(completed) / Double(activeHabits.count))
        }

        let avgRecentRate = recentCompletionRates.isEmpty ? 0 : recentCompletionRates.reduce(0, +) / Double(recentCompletionRates.count)

        // Factor 2: Recent mood — if mood is terrible/bad, be gentle
        let recentMoods = journalEntries
            .filter { $0.date >= calendar.date(byAdding: .day, value: -2, to: today) ?? today }
            .map(\.mood.rawValue)
        let avgMood = recentMoods.isEmpty ? 3.0 : Double(recentMoods.reduce(0, +)) / Double(recentMoods.count)

        // Factor 3: Day of week — weekends can be quieter
        let weekday = calendar.component(.weekday, from: today)
        let isWeekend = weekday == 1 || weekday == 7

        // Decision logic:
        // Quiet day if user has been performing well (>90%) for 3 days — earned a lighter day
        // OR if mood is low (<2.5) — they need a break
        // Weekends get a lower threshold
        let performanceThreshold = isWeekend ? 0.80 : 0.90
        let moodThreshold = 2.5

        if avgRecentRate > performanceThreshold {
            return true // Earned rest
        }

        if avgMood < moodThreshold && !recentMoods.isEmpty {
            return true // Need gentleness
        }

        return false
    }

    /// Adjusts notification scheduling based on quiet day status.
    func scheduleHabitReminderIfAppropriate(for habit: Habit, quietDaysEnabled: Bool, habits: [Habit], journalEntries: [JournalEntry]) {
        if quietDaysEnabled && isQuietDay(habits: habits, journalEntries: journalEntries) {
            // On quiet days, cancel existing reminders — let the user rest
            cancelReminder(for: habit)
            return
        }
        scheduleHabitReminder(for: habit)
    }

    // MARK: - Schedule Habit Reminders

    func scheduleHabitReminder(for habit: Habit) {
        guard let reminderTime = habit.reminderTime else { return }

        let content = UNMutableNotificationContent()
        content.title = "Время для привычки"
        content.body = motivationalBody(for: habit)
        content.sound = .default
        content.categoryIdentifier = "HABIT_REMINDER"
        content.userInfo = ["habitID": habit.id.uuidString]

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "habit-\(habit.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for habit: Habit) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: ["habit-\(habit.id.uuidString)"]
            )
    }

    // MARK: - Schedule Reflection Reminder

    func scheduleEveningReflection(at hour: Int = 21, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Как прошёл день?"
        content.body = "Удели минутку рефлексии — это помогает формировать привычки 📝"
        content.sound = .default
        content.categoryIdentifier = "JOURNAL_REMINDER"

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "evening-reflection",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Schedule Weekly Review

    func scheduleWeeklyReview() {
        let content = UNMutableNotificationContent()
        content.title = "Еженедельный обзор 📊"
        content.body = "Посмотри свой прогресс за неделю и скорректируй план!"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_REVIEW"

        var components = DateComponents()
        components.weekday = 1  // Sunday
        components.hour = 10
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weekly-review",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Clear All

    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Setup Actions

    func setupNotificationCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_HABIT",
            title: "✅ Выполнено",
            options: .foreground
        )

        let skipAction = UNNotificationAction(
            identifier: "SKIP_HABIT",
            title: "⏭️ Пропустить",
            options: []
        )

        let habitCategory = UNNotificationCategory(
            identifier: "HABIT_REMINDER",
            actions: [completeAction, skipAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let openJournalAction = UNNotificationAction(
            identifier: "OPEN_JOURNAL",
            title: "📝 Открыть журнал",
            options: .foreground
        )

        let journalCategory = UNNotificationCategory(
            identifier: "JOURNAL_REMINDER",
            actions: [openJournalAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current()
            .setNotificationCategories([habitCategory, journalCategory])
    }

    // MARK: - Private

    private func motivationalBody(for habit: Habit) -> String {
        let streak = habit.currentStreak
        if streak > 7 {
            return "🔥 \(streak) дней подряд! Не останавливайся — \(habit.name)"
        } else if streak > 0 {
            return "Продолжай серию! \(habit.name) — \(streak) дн. 💪"
        } else {
            return "Пора! \(habit.name) ждёт тебя ✨"
        }
    }
}
