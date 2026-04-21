import Foundation
import SwiftData

// MARK: - Habit Service

@Observable
final class HabitService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD

    func createHabit(
        name: String,
        icon: String = "star.fill",
        category: HabitCategory = .productivity,
        type: HabitType = .boolean,
        frequency: HabitFrequency = .daily,
        targetCount: Int = 1,
        targetDuration: TimeInterval = 0,
        reminderTime: Date? = nil,
        isAIGenerated: Bool = false,
        goal: Goal? = nil
    ) -> Habit {
        let habit = Habit(
            name: name,
            icon: icon,
            colorHex: category.color.description,
            category: category,
            type: type,
            frequency: frequency,
            targetCount: targetCount,
            targetDuration: targetDuration,
            reminderTime: reminderTime,
            isAIGenerated: isAIGenerated
        )
        habit.goal = goal
        modelContext.insert(habit)
        try? modelContext.save()
        return habit
    }

    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
        try? modelContext.save()
    }

    func archiveHabit(_ habit: Habit) {
        habit.archivedAt = Date()
        try? modelContext.save()
    }

    // MARK: - Entries

    func toggleToday(for habit: Habit) {
        let today = Calendar.current.startOfDay(for: Date())

        if let existing = habit.entries.first(where: {
            Calendar.current.startOfDay(for: $0.date) == today
        }) {
            existing.isCompleted.toggle()
            existing.completedAt = existing.isCompleted ? Date() : nil
        } else {
            let entry = HabitEntry(date: Date(), isCompleted: true)
            entry.completedAt = Date()
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    func incrementCounter(for habit: Habit) {
        let today = Calendar.current.startOfDay(for: Date())

        if let existing = habit.entries.first(where: {
            Calendar.current.startOfDay(for: $0.date) == today
        }) {
            existing.count += 1
            existing.isCompleted = existing.count >= habit.targetCount
            if existing.isCompleted { existing.completedAt = Date() }
        } else {
            let entry = HabitEntry(date: Date(), isCompleted: false, count: 1)
            entry.isCompleted = 1 >= habit.targetCount
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    func requestFlexDay(for habit: Habit, reason: String) {
        let today = Calendar.current.startOfDay(for: Date())

        if let existing = habit.entries.first(where: {
            Calendar.current.startOfDay(for: $0.date) == today
        }) {
            existing.isFlexDay = true
            existing.skippedReason = reason
        } else {
            let entry = HabitEntry(date: Date())
            entry.isFlexDay = true
            entry.skippedReason = reason
            entry.habit = habit
            habit.entries.append(entry)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }

    // MARK: - Queries

    func todayHabits() -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate { $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let habits = (try? modelContext.fetch(descriptor)) ?? []

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let isWeekend = weekday == 1 || weekday == 7

        return habits.filter { habit in
            switch habit.frequency {
            case .daily: return true
            case .weekdays: return !isWeekend
            case .weekends: return isWeekend
            default: return true
            }
        }
    }

    func completionRate(for habit: Habit, days: Int = 30) -> Double {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return 0 }
        let recentEntries = habit.entries.filter { $0.date >= startDate }
        let completed = recentEntries.filter { $0.isCompleted }.count
        return days > 0 ? Double(completed) / Double(days) : 0
    }

    func weeklyStats() -> (completed: Int, total: Int) {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return (0, 0)
        }
        let habits = todayHabits()
        var completed = 0
        var total = 0

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart),
                  day <= Date() else { continue }
            total += habits.count
            for habit in habits {
                let dayStart = calendar.startOfDay(for: day)
                if habit.entries.contains(where: {
                    calendar.startOfDay(for: $0.date) == dayStart && $0.isCompleted
                }) {
                    completed += 1
                }
            }
        }
        return (completed, total)
    }
}
