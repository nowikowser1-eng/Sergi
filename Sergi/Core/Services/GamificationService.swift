import Foundation
import SwiftData

// MARK: - Gamification Service

@Observable
final class GamificationService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - XP Calculation

    static let xpPerCompletion = 10
    static let xpBonusStreak7 = 25
    static let xpBonusStreak21 = 50
    static let xpBonusPerfectDay = 30

    // MARK: - Award XP

    func awardXP(to profile: UserProfile, amount: Int) {
        profile.totalXP += amount
        updateLevel(for: profile)
        try? modelContext.save()
    }

    // MARK: - Check & Award Badges

    func checkBadges(for profile: UserProfile, habits: [Habit]) -> [BadgeType] {
        var newBadges: [BadgeType] = []
        let earnedTypes = Set(profile.badges.map(\.type))

        // First habit
        if !earnedTypes.contains(.firstHabit) && !habits.isEmpty {
            newBadges.append(.firstHabit)
        }

        // Five habits
        if !earnedTypes.contains(.fiveHabits) && habits.count >= 5 {
            newBadges.append(.fiveHabits)
        }

        // Streak badges
        for habit in habits {
            let streak = habit.currentStreak

            if streak >= 7 && !earnedTypes.contains(.streak7) {
                newBadges.append(.streak7)
            }
            if streak >= 21 && !earnedTypes.contains(.streak21) {
                newBadges.append(.streak21)
            }
            if streak >= 66 && !earnedTypes.contains(.streak66) {
                newBadges.append(.streak66)
            }
            if streak >= 100 && !earnedTypes.contains(.streak100) {
                newBadges.append(.streak100)
            }
        }

        // Perfect week
        if !earnedTypes.contains(.perfectWeek) {
            let allCompletedThisWeek = checkPerfectWeek(habits: habits)
            if allCompletedThisWeek { newBadges.append(.perfectWeek) }
        }

        // Early bird
        if !earnedTypes.contains(.earlyBird) {
            for habit in habits {
                if let entry = habit.todayEntry,
                   let completedAt = entry.completedAt {
                    let hour = Calendar.current.component(.hour, from: completedAt)
                    if hour < 7 {
                        newBadges.append(.earlyBird)
                        break
                    }
                }
            }
        }

        // Night owl
        if !earnedTypes.contains(.nightOwl) {
            for habit in habits {
                if let entry = habit.todayEntry,
                   let completedAt = entry.completedAt {
                    let hour = Calendar.current.component(.hour, from: completedAt)
                    if hour >= 23 {
                        newBadges.append(.nightOwl)
                        break
                    }
                }
            }
        }

        // Award new badges
        for badgeType in newBadges {
            guard !earnedTypes.contains(badgeType) else { continue }
            let badge = Badge(type: badgeType)
            profile.badges.append(badge)
            modelContext.insert(badge)
            awardXP(to: profile, amount: badgeType.xpReward)
        }

        if !newBadges.isEmpty {
            try? modelContext.save()
        }

        return newBadges
    }

    // MARK: - Level Up Check

    func updateLevel(for profile: UserProfile) {
        var level = 0
        var xpThreshold = 100

        while profile.totalXP >= xpThreshold {
            level += 1
            xpThreshold += (level + 1) * 100
        }

        if level > profile.level {
            profile.level = level
        }
    }

    // MARK: - On Habit Completed

    func onHabitCompleted(habit: Habit, profile: UserProfile, allHabits: [Habit]) -> CompletionReward {
        // Base XP
        awardXP(to: profile, amount: Self.xpPerCompletion)
        var reward = CompletionReward(xpEarned: Self.xpPerCompletion)

        // Streak bonus
        let streak = habit.currentStreak
        if streak == 7 {
            awardXP(to: profile, amount: Self.xpBonusStreak7)
            reward.xpEarned += Self.xpBonusStreak7
            reward.streakMilestone = 7
        } else if streak == 21 {
            awardXP(to: profile, amount: Self.xpBonusStreak21)
            reward.xpEarned += Self.xpBonusStreak21
            reward.streakMilestone = 21
        }

        // Perfect day check
        let todayHabits = allHabits.filter { $0.isActive }
        if todayHabits.allSatisfy({ $0.isCompletedToday }) {
            awardXP(to: profile, amount: Self.xpBonusPerfectDay)
            reward.xpEarned += Self.xpBonusPerfectDay
            reward.isPerfectDay = true
        }

        // Badge check
        reward.newBadges = checkBadges(for: profile, habits: allHabits)

        // Level up check
        let oldLevel = profile.level
        updateLevel(for: profile)
        reward.didLevelUp = profile.level > oldLevel

        return reward
    }

    // MARK: - Private

    private func checkPerfectWeek(habits: [Habit]) -> Bool {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        ) else { return false }

        let activeHabits = habits.filter { $0.isActive }
        guard !activeHabits.isEmpty else { return false }

        for dayOffset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart),
                  day <= Date() else { continue }
            let dayStart = calendar.startOfDay(for: day)

            for habit in activeHabits {
                let hasCompletion = habit.entries.contains {
                    calendar.startOfDay(for: $0.date) == dayStart && $0.isCompleted
                }
                if !hasCompletion { return false }
            }
        }
        return true
    }
}

// MARK: - Completion Reward

struct CompletionReward {
    var xpEarned: Int
    var streakMilestone: Int? = nil
    var isPerfectDay: Bool = false
    var newBadges: [BadgeType] = []
    var didLevelUp: Bool = false

    var shouldCelebrate: Bool {
        streakMilestone != nil || isPerfectDay || !newBadges.isEmpty || didLevelUp
    }
}
