import Foundation
import SwiftData

// MARK: - Habit Model

@Model
final class Habit {
    var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var category: HabitCategory
    var type: HabitType
    var frequency: HabitFrequency
    var targetCount: Int
    var targetDuration: TimeInterval
    var reminderTime: Date?
    var isAIGenerated: Bool
    var linkedGoalID: UUID?
    var habitStackAnchor: String?
    var implementationIntention: String?
    var whyMotivation: String?
    var identityStatement: String?
    var difficultyLevel: Int // 1-5
    var createdAt: Date
    var archivedAt: Date?
    var sortOrder: Int

    // Relations
    @Relationship(deleteRule: .cascade) var entries: [HabitEntry]
    @Relationship(deleteRule: .nullify) var goal: Goal?

    // Computed
    var isActive: Bool { archivedAt == nil }

    var currentStreak: Int {
        guard !entries.isEmpty else { return 0 }
        let sorted = entries.filter { $0.isCompleted }.sorted { $0.date > $1.date }
        guard let latest = sorted.first else { return 0 }

        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: Date())

        // Если сегодня не выполнено, начинаем со вчера
        if Calendar.current.startOfDay(for: latest.date) != checkDate {
            checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
        }

        for entry in sorted {
            let entryDay = Calendar.current.startOfDay(for: entry.date)
            if entryDay == checkDate {
                streak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else if entryDay < checkDate {
                break
            }
        }
        return streak
    }

    var bestStreak: Int {
        guard !entries.isEmpty else { return 0 }
        let dates = Set(entries.filter { $0.isCompleted }.map { Calendar.current.startOfDay(for: $0.date) }).sorted()
        guard !dates.isEmpty else { return 0 }

        var best = 1
        var current = 1
        for i in 1..<dates.count {
            let diff = Calendar.current.dateComponents([.day], from: dates[i - 1], to: dates[i]).day ?? 0
            if diff == 1 {
                current += 1
                best = max(best, current)
            } else {
                current = 1
            }
        }
        return best
    }

    var completionRate: Double {
        let calendar = Calendar.current
        guard let firstEntry = entries.min(by: { $0.date < $1.date }) else { return 0 }
        let totalDays = max(1, calendar.dateComponents([.day], from: firstEntry.date, to: Date()).day ?? 1)
        let completedDays = entries.filter { $0.isCompleted }.count
        return Double(completedDays) / Double(totalDays)
    }

    var todayEntry: HabitEntry? {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.first { Calendar.current.startOfDay(for: $0.date) == today }
    }

    var isCompletedToday: Bool {
        todayEntry?.isCompleted ?? false
    }

    init(
        name: String,
        icon: String = "star.fill",
        colorHex: String = "#6253C7",
        category: HabitCategory = .productivity,
        type: HabitType = .boolean,
        frequency: HabitFrequency = .daily,
        targetCount: Int = 1,
        targetDuration: TimeInterval = 0,
        reminderTime: Date? = nil,
        isAIGenerated: Bool = false,
        difficultyLevel: Int = 1,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.category = category
        self.type = type
        self.frequency = frequency
        self.targetCount = targetCount
        self.targetDuration = targetDuration
        self.reminderTime = reminderTime
        self.isAIGenerated = isAIGenerated
        self.difficultyLevel = difficultyLevel
        self.createdAt = Date()
        self.sortOrder = sortOrder
        self.entries = []
    }
}

// MARK: - Habit Entry (daily log)

@Model
final class HabitEntry {
    var id: UUID
    var date: Date
    var isCompleted: Bool
    var count: Int
    var duration: TimeInterval
    var note: String?
    var skippedReason: String?
    var isFlexDay: Bool
    var completedAt: Date?

    @Relationship var habit: Habit?

    init(
        date: Date = Date(),
        isCompleted: Bool = false,
        count: Int = 0,
        duration: TimeInterval = 0,
        note: String? = nil,
        isFlexDay: Bool = false
    ) {
        self.id = UUID()
        self.date = date
        self.isCompleted = isCompleted
        self.count = count
        self.duration = duration
        self.note = note
        self.isFlexDay = isFlexDay
    }
}

// MARK: - Goal

@Model
final class Goal {
    var id: UUID
    var title: String
    var goalDescription: String
    var deadline: Date?
    var currentLevel: String?
    var availableMinutesPerDay: Int
    var identityStatement: String?
    var isCompleted: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify) var habits: [Habit]

    init(
        title: String,
        description: String = "",
        deadline: Date? = nil,
        currentLevel: String? = nil,
        availableMinutesPerDay: Int = 30
    ) {
        self.id = UUID()
        self.title = title
        self.goalDescription = description
        self.deadline = deadline
        self.currentLevel = currentLevel
        self.availableMinutesPerDay = availableMinutesPerDay
        self.isCompleted = false
        self.createdAt = Date()
        self.habits = []
    }
}

// MARK: - Journal Entry

@Model
final class JournalEntry {
    var id: UUID
    var date: Date
    var mood: MoodLevel
    var reflectionText: String?
    var aiQuestion: String?
    var aiInsight: String?
    var gratitudeItems: [String]
    var energyLevel: Int // 1-5

    init(
        date: Date = Date(),
        mood: MoodLevel = .neutral,
        reflectionText: String? = nil,
        aiQuestion: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.mood = mood
        self.reflectionText = reflectionText
        self.aiQuestion = aiQuestion
        self.gratitudeItems = []
        self.energyLevel = 3
    }
}

// MARK: - User Profile

@Model
final class UserProfile {
    var id: UUID
    var displayName: String
    var avatarEmoji: String
    var level: Int
    var totalXP: Int
    var isPremium: Bool
    var premiumExpiresAt: Date?
    var onboardingCompleted: Bool
    var preferredNotificationStyle: NotificationStyle
    var quietDaysEnabled: Bool
    var darkModePreference: AppearanceMode
    var accentColorHex: String
    var createdAt: Date
    var lastActiveAt: Date

    @Relationship(deleteRule: .cascade) var badges: [Badge]

    var currentLevelTitle: String {
        switch level {
        case 0...2: return "Новичок"
        case 3...5: return "Ученик"
        case 6...10: return "Практик"
        case 11...20: return "Мастер привычек"
        case 21...50: return "Гуру"
        default: return "Легенда"
        }
    }

    var xpForNextLevel: Int {
        (level + 1) * 100
    }

    var xpProgress: Double {
        let xpInCurrentLevel = totalXP - (level * (level + 1) / 2 * 100)
        return Double(xpInCurrentLevel) / Double(xpForNextLevel)
    }

    init(displayName: String = "Друг") {
        self.id = UUID()
        self.displayName = displayName
        self.avatarEmoji = "🌟"
        self.level = 0
        self.totalXP = 0
        self.isPremium = false
        self.onboardingCompleted = false
        self.preferredNotificationStyle = .motivational
        self.quietDaysEnabled = true
        self.darkModePreference = .system
        self.accentColorHex = "#6253C7"
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.badges = []
    }
}

// MARK: - Badge (Achievement)

@Model
final class Badge {
    var id: UUID
    var type: BadgeType
    var earnedAt: Date
    var isNew: Bool

    init(type: BadgeType) {
        self.id = UUID()
        self.type = type
        self.earnedAt = Date()
        self.isNew = true
    }
}

// MARK: - AI Chat Message

@Model
final class AIChatMessage {
    var id: UUID
    var role: ChatRole
    var content: String
    var timestamp: Date
    var relatedHabitID: UUID?

    init(role: ChatRole, content: String, relatedHabitID: UUID? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.relatedHabitID = relatedHabitID
    }
}
