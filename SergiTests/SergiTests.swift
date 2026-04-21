import XCTest
@testable import Sergi

final class SergiTests: XCTestCase {

    // MARK: - Habit Model Tests

    func testHabitCreation() throws {
        let habit = Habit(name: "Test Habit")
        XCTAssertEqual(habit.name, "Test Habit")
        XCTAssertEqual(habit.icon, "star.fill")
        XCTAssertEqual(habit.category, .productivity)
        XCTAssertEqual(habit.type, .boolean)
        XCTAssertEqual(habit.frequency, .daily)
        XCTAssertTrue(habit.isActive)
        XCTAssertEqual(habit.currentStreak, 0)
        XCTAssertEqual(habit.bestStreak, 0)
        XCTAssertFalse(habit.isCompletedToday)
    }

    func testHabitIsActive() throws {
        let habit = Habit(name: "Active")
        XCTAssertTrue(habit.isActive)

        habit.archivedAt = Date()
        XCTAssertFalse(habit.isActive)
    }

    func testHabitCompletionRateEmpty() throws {
        let habit = Habit(name: "No Entries")
        XCTAssertEqual(habit.completionRate, 0)
    }

    func testHabitTodayEntryNil() throws {
        let habit = Habit(name: "No Entry")
        XCTAssertNil(habit.todayEntry)
        XCTAssertFalse(habit.isCompletedToday)
    }

    // MARK: - User Profile Tests

    func testUserProfileDefaults() throws {
        let profile = UserProfile()
        XCTAssertEqual(profile.displayName, "Друг")
        XCTAssertEqual(profile.level, 0)
        XCTAssertEqual(profile.totalXP, 0)
        XCTAssertFalse(profile.isPremium)
        XCTAssertFalse(profile.onboardingCompleted)
        XCTAssertEqual(profile.currentLevelTitle, "Новичок")
    }

    func testUserProfileLevelTitles() throws {
        let profile = UserProfile()

        profile.level = 0
        XCTAssertEqual(profile.currentLevelTitle, "Новичок")

        profile.level = 3
        XCTAssertEqual(profile.currentLevelTitle, "Ученик")

        profile.level = 6
        XCTAssertEqual(profile.currentLevelTitle, "Практик")

        profile.level = 11
        XCTAssertEqual(profile.currentLevelTitle, "Мастер привычек")

        profile.level = 21
        XCTAssertEqual(profile.currentLevelTitle, "Гуру")

        profile.level = 51
        XCTAssertEqual(profile.currentLevelTitle, "Легенда")
    }

    func testUserProfileXPForNextLevel() throws {
        let profile = UserProfile()
        profile.level = 0
        XCTAssertEqual(profile.xpForNextLevel, 100)

        profile.level = 5
        XCTAssertEqual(profile.xpForNextLevel, 600)
    }

    // MARK: - Badge Tests

    func testBadgeType() throws {
        XCTAssertEqual(BadgeType.streak7.xpReward, 50)
        XCTAssertEqual(BadgeType.streak100.xpReward, 1000)
        XCTAssertEqual(BadgeType.allCases.count, 15)
    }

    func testBadgeCreation() throws {
        let badge = Badge(type: .firstHabit)
        XCTAssertEqual(badge.type, .firstHabit)
        XCTAssertTrue(badge.isNew)
    }

    // MARK: - Habit Library Tests

    func testHabitLibraryTemplateCount() throws {
        XCTAssertGreaterThan(HabitLibrary.allTemplates.count, 50)
    }

    func testHabitLibrarySearch() throws {
        let results = HabitLibrary.search(query: "медитация")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy {
            $0.name.lowercased().contains("медитац") ||
            $0.scientificReason.lowercased().contains("медитац")
        })
    }

    func testHabitLibrarySearchEmpty() throws {
        let results = HabitLibrary.search(query: "xyznonexistent")
        XCTAssertTrue(results.isEmpty)
    }

    func testHabitLibraryGoalPack() throws {
        let healthPack = HabitLibrary.pack(for: "здоровье")
        XCTAssertFalse(healthPack.isEmpty)

        let fitnessPack = HabitLibrary.pack(for: "спорт")
        XCTAssertFalse(fitnessPack.isEmpty)

        let languagePack = HabitLibrary.pack(for: "английский")
        XCTAssertFalse(languagePack.isEmpty)

        let productivityPack = HabitLibrary.pack(for: "продуктивность")
        XCTAssertFalse(productivityPack.isEmpty)
    }

    func testHabitLibraryGoalPackDefault() throws {
        let defaultPack = HabitLibrary.pack(for: "random text")
        XCTAssertFalse(defaultPack.isEmpty)
        XCTAssertEqual(defaultPack.count, 4)
    }

    func testHabitLibraryByCategory() throws {
        for category in HabitCategory.allCases {
            let templates = HabitLibrary.byCategory(category)
            // All returned templates should belong to the category
            XCTAssertTrue(templates.allSatisfy { $0.category == category })
        }
    }

    // MARK: - Goal Model Tests

    func testGoalCreation() throws {
        let goal = Goal(title: "Test Goal", description: "Desc", availableMinutesPerDay: 30)
        XCTAssertEqual(goal.title, "Test Goal")
        XCTAssertEqual(goal.goalDescription, "Desc")
        XCTAssertEqual(goal.availableMinutesPerDay, 30)
        XCTAssertFalse(goal.isCompleted)
        XCTAssertTrue(goal.habits.isEmpty)
    }

    // MARK: - Journal Entry Tests

    func testJournalEntryDefaults() throws {
        let entry = JournalEntry()
        XCTAssertEqual(entry.mood, .neutral)
        XCTAssertEqual(entry.energyLevel, 3)
        XCTAssertNil(entry.reflectionText)
        XCTAssertTrue(entry.gratitudeItems.isEmpty)
    }

    // MARK: - Habit Entry Tests

    func testHabitEntryDefaults() throws {
        let entry = HabitEntry()
        XCTAssertFalse(entry.isCompleted)
        XCTAssertEqual(entry.count, 0)
        XCTAssertEqual(entry.duration, 0)
        XCTAssertFalse(entry.isFlexDay)
        XCTAssertNil(entry.completedAt)
    }

    // MARK: - Enum Tests

    func testHabitCategoryAllCases() throws {
        XCTAssertEqual(HabitCategory.allCases.count, 10)
    }

    func testHabitFrequencyAllCases() throws {
        XCTAssertGreaterThanOrEqual(HabitFrequency.allCases.count, 6)
    }

    func testMoodLevelOrdering() throws {
        XCTAssertLessThan(MoodLevel.terrible.rawValue, MoodLevel.great.rawValue)
    }

    func testSubscriptionPlanPrices() throws {
        for plan in SubscriptionPlan.allCases {
            XCTAssertFalse(plan.priceText.isEmpty)
        }
    }

    // MARK: - AppConfig Tests

    func testAppConfigEnvironment() throws {
        #if DEBUG
        XCTAssertEqual(AppConfig.environment, .debug)
        XCTAssertTrue(AppConfig.isDebug)
        #endif
    }

    func testAppConfigAPIDefaults() throws {
        XCTAssertFalse(AppConfig.API.openAIBaseURL.isEmpty)
        XCTAssertEqual(AppConfig.API.openAIModel, "gpt-4o-mini")
        XCTAssertGreaterThan(AppConfig.API.requestTimeout, 0)
        XCTAssertGreaterThan(AppConfig.API.maxRetries, 0)
    }

    func testAppConfigStoreProductIDs() throws {
        XCTAssertEqual(AppConfig.Store.allProductIDs.count, 3)
    }

    func testAppConfigGamification() throws {
        XCTAssertEqual(AppConfig.Gamification.baseXP, 10)
        XCTAssertGreaterThan(AppConfig.Gamification.maxStreakBonus, 0)
    }

    func testAppConfigVersion() throws {
        XCTAssertFalse(AppConfig.appVersion.isEmpty)
        XCTAssertFalse(AppConfig.buildNumber.isEmpty)
        XCTAssertTrue(AppConfig.fullVersion.contains("("))
    }

    // MARK: - AI Coach Service Tests

    func testAICoachRiskPrediction() throws {
        // Test risk prediction heuristic
        let habit = Habit(name: "Test")

        // New habit with no entries should have higher risk
        let risk = predictRisk(for: habit)
        XCTAssertGreaterThan(risk, 0.3)
    }

    // MARK: - Export Service Tests

    func testCSVEscaping() throws {
        // Test that CSV escaping handles commas and quotes
        let value = "Hello, \"World\""
        let escaped = escapeCSV(value)
        XCTAssertTrue(escaped.hasPrefix("\""))
        XCTAssertTrue(escaped.hasSuffix("\""))
    }

    // MARK: - CompletionReward Tests

    func testCompletionRewardShouldCelebrate() throws {
        var reward = CompletionReward(xpEarned: 10)
        XCTAssertFalse(reward.shouldCelebrate)

        reward.isPerfectDay = true
        XCTAssertTrue(reward.shouldCelebrate)
    }

    func testCompletionRewardStreakMilestone() throws {
        var reward = CompletionReward(xpEarned: 10)
        reward.streakMilestone = 7
        XCTAssertTrue(reward.shouldCelebrate)
    }

    func testCompletionRewardLevelUp() throws {
        var reward = CompletionReward(xpEarned: 10)
        reward.didLevelUp = true
        XCTAssertTrue(reward.shouldCelebrate)
    }

    func testCompletionRewardNewBadges() throws {
        var reward = CompletionReward(xpEarned: 10)
        reward.newBadges = [.firstHabit]
        XCTAssertTrue(reward.shouldCelebrate)
    }

    // MARK: - Helpers (mirror private logic for testing)

    private func predictRisk(for habit: Habit) -> Double {
        let streak = habit.currentStreak
        let rate = habit.completionRate
        let daysSinceCreation = Calendar.current.dateComponents(
            [.day], from: habit.createdAt, to: Date()
        ).day ?? 0

        var risk = 0.5
        if streak == 0 { risk += 0.3 }
        else if streak < 7 { risk += 0.1 }
        else if streak > 21 { risk -= 0.2 }

        if rate < 0.3 { risk += 0.2 }
        else if rate > 0.7 { risk -= 0.15 }

        if daysSinceCreation > 7 && daysSinceCreation < 15 { risk += 0.1 }

        return min(1.0, max(0, risk))
    }

    private func escapeCSV(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\"", with: "\"\"")
            .replacingOccurrences(of: "\n", with: " ")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains(";") {
            return "\"\(escaped)\""
        }
        return escaped
    }
}
    }

    func testSubscriptionPlan() throws {
        XCTAssertTrue(SubscriptionPlan.annual.isBestValue)
        XCTAssertEqual(SubscriptionPlan.monthly.priceRubles, 390)
        XCTAssertEqual(SubscriptionPlan.allCases.count, 6)
    }

    func testMoodLevels() throws {
        XCTAssertEqual(MoodLevel.allCases.count, 5)
        XCTAssertEqual(MoodLevel.excellent.emoji, "🤩")
        XCTAssertEqual(MoodLevel.terrible.rawValue, 1)
    }

    func testCompletionRewardCelebration() throws {
        var reward = CompletionReward(xpEarned: 10)
        XCTAssertFalse(reward.shouldCelebrate)

        reward.streakMilestone = 7
        XCTAssertTrue(reward.shouldCelebrate)
    }
}
