import Foundation
import SwiftUI

// MARK: - Habit Category

enum HabitCategory: String, Codable, CaseIterable, Identifiable {
    case health = "health"
    case fitness = "fitness"
    case learning = "learning"
    case productivity = "productivity"
    case relationships = "relationships"
    case finance = "finance"
    case mindfulness = "mindfulness"
    case creativity = "creativity"
    case nutrition = "nutrition"
    case sleep = "sleep"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .health: return "Здоровье"
        case .fitness: return "Фитнес"
        case .learning: return "Обучение"
        case .productivity: return "Продуктивность"
        case .relationships: return "Отношения"
        case .finance: return "Финансы"
        case .mindfulness: return "Осознанность"
        case .creativity: return "Творчество"
        case .nutrition: return "Питание"
        case .sleep: return "Сон"
        }
    }

    var icon: String {
        switch self {
        case .health: return "heart.fill"
        case .fitness: return "figure.run"
        case .learning: return "book.fill"
        case .productivity: return "bolt.fill"
        case .relationships: return "person.2.fill"
        case .finance: return "banknote.fill"
        case .mindfulness: return "brain.fill"
        case .creativity: return "paintbrush.fill"
        case .nutrition: return "leaf.fill"
        case .sleep: return "moon.fill"
        }
    }

    var color: Color {
        switch self {
        case .health: return SergiTheme.Colors.categoryHealth
        case .fitness: return SergiTheme.Colors.categoryHealth
        case .learning: return SergiTheme.Colors.categoryLearning
        case .productivity: return SergiTheme.Colors.categoryProductivity
        case .relationships: return SergiTheme.Colors.categoryRelationships
        case .finance: return SergiTheme.Colors.categoryProductivity
        case .mindfulness: return SergiTheme.Colors.categoryLearning
        case .creativity: return SergiTheme.Colors.categoryRelationships
        case .nutrition: return SergiTheme.Colors.categoryHealth
        case .sleep: return SergiTheme.Colors.primary
        }
    }
}

// MARK: - Habit Type

enum HabitType: String, Codable, CaseIterable, Identifiable {
    case boolean = "boolean"       // Да/Нет
    case counter = "counter"       // Счётчик (стаканы воды, отжимания)
    case timer = "timer"           // Таймер (медитация на 10 мин)
    case checklist = "checklist"   // Чек-лист (утренняя рутина)

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .boolean: return "Да / Нет"
        case .counter: return "Счётчик"
        case .timer: return "Таймер"
        case .checklist: return "Чек-лист"
        }
    }

    var icon: String {
        switch self {
        case .boolean: return "checkmark.circle"
        case .counter: return "number"
        case .timer: return "timer"
        case .checklist: return "checklist"
        }
    }
}

// MARK: - Habit Frequency

enum HabitFrequency: String, Codable, CaseIterable, Identifiable {
    case daily = "daily"
    case weekdays = "weekdays"
    case weekends = "weekends"
    case threePerWeek = "3x_week"
    case fivePerWeek = "5x_week"
    case custom = "custom"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Каждый день"
        case .weekdays: return "По будням"
        case .weekends: return "По выходным"
        case .threePerWeek: return "3 раза в неделю"
        case .fivePerWeek: return "5 раз в неделю"
        case .custom: return "Свой график"
        }
    }

    var shortName: String {
        switch self {
        case .daily: return "Ежедневно"
        case .weekdays: return "Пн-Пт"
        case .weekends: return "Сб-Вс"
        case .threePerWeek: return "3×/нед"
        case .fivePerWeek: return "5×/нед"
        case .custom: return "Своё"
        }
    }
}

// MARK: - Mood Level

enum MoodLevel: Int, Codable, CaseIterable, Identifiable {
    case terrible = 1
    case bad = 2
    case neutral = 3
    case good = 4
    case excellent = 5

    var id: Int { rawValue }

    var emoji: String {
        switch self {
        case .terrible: return "😫"
        case .bad: return "😔"
        case .neutral: return "😐"
        case .good: return "😊"
        case .excellent: return "🤩"
        }
    }

    var label: String {
        switch self {
        case .terrible: return "Ужасно"
        case .bad: return "Плохо"
        case .neutral: return "Нормально"
        case .good: return "Хорошо"
        case .excellent: return "Отлично"
        }
    }
}

// MARK: - Badge Type

enum BadgeType: String, Codable, CaseIterable, Identifiable {
    case streak7 = "streak_7"
    case streak21 = "streak_21"
    case streak66 = "streak_66"
    case streak100 = "streak_100"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case ironWill = "iron_will"
    case firstHabit = "first_habit"
    case fiveHabits = "five_habits"
    case perfectWeek = "perfect_week"
    case perfectMonth = "perfect_month"
    case journalKeeper = "journal_keeper"
    case aiExplorer = "ai_explorer"
    case socialButterfly = "social_butterfly"
    case levelUp = "level_up"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .streak7: return "7 дней подряд"
        case .streak21: return "21 день — привычка!"
        case .streak66: return "66 дней — автоматизм!"
        case .streak100: return "Сотня!"
        case .earlyBird: return "Ранняя пташка"
        case .nightOwl: return "Ночная сова"
        case .ironWill: return "Железная воля"
        case .firstHabit: return "Первый шаг"
        case .fiveHabits: return "Пять привычек"
        case .perfectWeek: return "Идеальная неделя"
        case .perfectMonth: return "Идеальный месяц"
        case .journalKeeper: return "Хранитель дневника"
        case .aiExplorer: return "Исследователь AI"
        case .socialButterfly: return "Командный игрок"
        case .levelUp: return "Новый уровень"
        }
    }

    var icon: String {
        switch self {
        case .streak7: return "flame.fill"
        case .streak21: return "flame.fill"
        case .streak66: return "flame.fill"
        case .streak100: return "flame.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.stars.fill"
        case .ironWill: return "shield.fill"
        case .firstHabit: return "star.fill"
        case .fiveHabits: return "star.fill"
        case .perfectWeek: return "crown.fill"
        case .perfectMonth: return "crown.fill"
        case .journalKeeper: return "book.closed.fill"
        case .aiExplorer: return "brain.fill"
        case .socialButterfly: return "person.3.fill"
        case .levelUp: return "arrow.up.circle.fill"
        }
    }

    var xpReward: Int {
        switch self {
        case .streak7: return 50
        case .streak21: return 150
        case .streak66: return 500
        case .streak100: return 1000
        case .earlyBird: return 30
        case .nightOwl: return 30
        case .ironWill: return 200
        case .firstHabit: return 10
        case .fiveHabits: return 50
        case .perfectWeek: return 100
        case .perfectMonth: return 400
        case .journalKeeper: return 60
        case .aiExplorer: return 40
        case .socialButterfly: return 80
        case .levelUp: return 50
        }
    }

    var description: String {
        switch self {
        case .streak7: return "Выполняй привычку 7 дней подряд"
        case .streak21: return "21 день — привычка начинает формироваться!"
        case .streak66: return "66 дней — привычка стала автоматической!"
        case .streak100: return "100 дней подряд — ты легенда!"
        case .earlyBird: return "Выполни привычку до 7 утра"
        case .nightOwl: return "Выполни привычку после 23:00"
        case .ironWill: return "Не пропусти ни одного дня за месяц"
        case .firstHabit: return "Создай свою первую привычку"
        case .fiveHabits: return "Отслеживай 5 привычек одновременно"
        case .perfectWeek: return "Выполни все привычки за неделю"
        case .perfectMonth: return "Выполни все привычки за месяц"
        case .journalKeeper: return "Веди журнал 7 дней подряд"
        case .aiExplorer: return "Используй AI-коуча 10 раз"
        case .socialButterfly: return "Пригласи друга в приложение"
        case .levelUp: return "Достигни нового уровня"
        }
    }
}

// MARK: - Chat Role

enum ChatRole: String, Codable {
    case user
    case assistant
    case system
}

// MARK: - Notification Style

enum NotificationStyle: String, Codable, CaseIterable {
    case minimal = "minimal"
    case motivational = "motivational"
    case contextual = "contextual"

    var displayName: String {
        switch self {
        case .minimal: return "Минимальные"
        case .motivational: return "Мотивирующие"
        case .contextual: return "Контекстные"
        }
    }
}

// MARK: - Appearance Mode

enum AppearanceMode: String, Codable, CaseIterable {
    case light
    case dark
    case system

    var displayName: String {
        switch self {
        case .light: return "Светлая"
        case .dark: return "Тёмная"
        case .system: return "Системная"
        }
    }
}

// MARK: - Subscription Plan

enum SubscriptionPlan: String, CaseIterable, Identifiable {
    case monthly = "com.sergi.premium.monthly"
    case quarterly = "com.sergi.premium.quarterly"
    case semiannual = "com.sergi.premium.semiannual"
    case annual = "com.sergi.premium.annual"
    case biennial = "com.sergi.premium.biennial"
    case lifetime = "com.sergi.premium.lifetime"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monthly: return "1 месяц"
        case .quarterly: return "3 месяца"
        case .semiannual: return "6 месяцев"
        case .annual: return "12 месяцев"
        case .biennial: return "24 месяца"
        case .lifetime: return "Навсегда"
        }
    }

    var priceRubles: Int {
        switch self {
        case .monthly: return 390
        case .quarterly: return 1053
        case .semiannual: return 1989
        case .annual: return 3978
        case .biennial: return 7956
        case .lifetime: return 15000
        }
    }

    var monthlyEquivalent: Int {
        switch self {
        case .monthly: return 390
        case .quarterly: return 351
        case .semiannual: return 332
        case .annual: return 332
        case .biennial: return 332
        case .lifetime: return 0
        }
    }

    var discountPercent: Int {
        switch self {
        case .monthly: return 0
        case .quarterly: return 10
        case .semiannual: return 15
        case .annual: return 15
        case .biennial: return 15
        case .lifetime: return 0
        }
    }

    var isBestValue: Bool { self == .annual }
}

// MARK: - Habit Library Template

struct HabitTemplate: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let category: HabitCategory
    let type: HabitType
    let frequency: HabitFrequency
    let suggestedTime: String  // "morning", "afternoon", "evening"
    let defaultDuration: TimeInterval
    let defaultCount: Int
    let scientificReason: String
    let tips: [String]
    let difficulty: Int // 1-5
    let popularityScore: Double // 0-1

    init(
        name: String,
        icon: String,
        category: HabitCategory,
        type: HabitType = .boolean,
        frequency: HabitFrequency = .daily,
        suggestedTime: String = "morning",
        defaultDuration: TimeInterval = 0,
        defaultCount: Int = 1,
        scientificReason: String = "",
        tips: [String] = [],
        difficulty: Int = 1,
        popularityScore: Double = 0.5
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.category = category
        self.type = type
        self.frequency = frequency
        self.suggestedTime = suggestedTime
        self.defaultDuration = defaultDuration
        self.defaultCount = defaultCount
        self.scientificReason = scientificReason
        self.tips = tips
        self.difficulty = difficulty
        self.popularityScore = popularityScore
    }
}
