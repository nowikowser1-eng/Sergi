import SwiftUI
import SwiftData
import Charts

// MARK: - Progress View (Analytics)

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { $0.archivedAt == nil })
    private var habits: [Habit]
    @Query private var profiles: [UserProfile]
    @Query private var journalEntries: [JournalEntry]

    @State private var selectedPeriod: StatPeriod = .week
    @State private var aiInsight = ""
    @State private var healthSteps: Int = 0
    @State private var healthActiveMinutes: Int = 0
    @State private var healthSleepHours: Double = 0
    @State private var showPaywall = false

    private var profile: UserProfile? { profiles.first }
    private var canViewAdvanced: Bool { PremiumManager.shared.canViewAdvancedAnalytics }

    var body: some View {
        NavigationStack {
            ZStack {
                SergiTheme.Colors.backgroundLight
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SergiTheme.Spacing.lg) {
                        // Period picker
                        Picker("", selection: $selectedPeriod) {
                            ForEach(StatPeriod.allCases, id: \.self) { period in
                                Text(period.displayName).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, SergiTheme.Spacing.md)

                        // Overview cards
                        overviewCards

                        // AI Insight
                        if !aiInsight.isEmpty {
                            aiInsightCard
                        }

                        // Completion chart
                        completionChart

                        // Per-habit stats
                        habitStats

                        // Gamification section
                        gamificationSection

                        // Mood trend (if journal entries exist)
                        if !journalEntries.isEmpty {
                            moodTrend
                        }

                        // Advanced analytics: correlations
                        if habits.count >= 2 {
                            if canViewAdvanced {
                                correlationsSection
                            } else {
                                premiumLockedSection(title: "Корреляции привычек", icon: "chart.xyaxis.line")
                            }
                        }

                        // Patterns
                        if canViewAdvanced {
                            patternsSection
                        } else {
                            premiumLockedSection(title: "Паттерны поведения", icon: "waveform.path.ecg")
                        }

                        // HealthKit stats
                        if HealthKitService.shared.isAuthorized {
                            if canViewAdvanced {
                                healthStatsSection
                            } else {
                                premiumLockedSection(title: "Данные здоровья", icon: "heart.fill")
                            }
                        }
                    }
                    .padding(.horizontal, SergiTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Прогресс")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .task {
                await loadInsight()
                if HealthKitService.shared.isAuthorized {
                    healthSteps = await HealthKitService.shared.fetchTodaySteps()
                    healthActiveMinutes = await HealthKitService.shared.fetchTodayActiveMinutes()
                    healthSleepHours = await HealthKitService.shared.fetchTodaySleepHours()
                }
            }
        }
    }

    // MARK: - Premium Locked Section

    private func premiumLockedSection(title: String, icon: String) -> some View {
        VStack(spacing: SergiTheme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(SergiTheme.Colors.primary.opacity(0.5))
                Text(title)
                    .font(SergiTheme.Typography.h3)
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
            }
            Text("Доступно с Premium-подпиской")
                .font(SergiTheme.Typography.caption)
                .foregroundStyle(SergiTheme.Colors.textSecondary)

            Button("Открыть Premium") { showPaywall = true }
                .font(SergiTheme.Typography.caption)
                .foregroundStyle(SergiTheme.Colors.primary)
        }
        .padding(SergiTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sergiCard()
    }

    // MARK: - Overview Cards

    private var overviewCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SergiTheme.Spacing.sm) {
            StatCard(
                title: "Активные привычки",
                value: "\(habits.count)",
                icon: "list.bullet",
                color: SergiTheme.Colors.primary
            )
            StatCard(
                title: "Лучший streak",
                value: "\(habits.map(\.bestStreak).max() ?? 0)",
                icon: "flame.fill",
                color: SergiTheme.Colors.streakHot
            )
            StatCard(
                title: "Уровень",
                value: "\(profile?.level ?? 0)",
                icon: "arrow.up.circle.fill",
                color: SergiTheme.Colors.accent
            )
            StatCard(
                title: "Общий XP",
                value: "\(profile?.totalXP ?? 0)",
                icon: "star.fill",
                color: SergiTheme.Colors.categoryProductivity
            )
        }
    }

    // MARK: - AI Insight

    private var aiInsightCard: some View {
        HStack(spacing: SergiTheme.Spacing.sm) {
            Image(systemName: "brain.fill")
                .font(.system(size: 20))
                .foregroundStyle(SergiTheme.Colors.primary)

            Text(aiInsight)
                .font(SergiTheme.Typography.body)
                .foregroundStyle(SergiTheme.Colors.textSecondary)
        }
        .padding(SergiTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                .fill(SergiTheme.Colors.primary.opacity(0.08))
        )
    }

    // MARK: - Completion Chart

    private var completionChart: some View {
        VStack(alignment: .leading, spacing: SergiTheme.Spacing.md) {
            Text("Выполнение за период")
                .font(SergiTheme.Typography.h3)

            let data = generateChartData()

            Chart(data, id: \.date) { item in
                BarMark(
                    x: .value("День", item.date, unit: .day),
                    y: .value("Выполнено", item.completionRate)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [SergiTheme.Colors.primary, SergiTheme.Colors.primaryLight],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...1)
            .chartYAxis {
                AxisMarks(values: [0, 0.5, 1]) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v * 100))%")
                                .font(SergiTheme.Typography.caption)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    // MARK: - Per-Habit Stats

    private var habitStats: some View {
        VStack(alignment: .leading, spacing: SergiTheme.Spacing.md) {
            Text("По привычкам")
                .font(SergiTheme.Typography.h3)

            ForEach(habits) { habit in
                HStack(spacing: SergiTheme.Spacing.md) {
                    Image(systemName: habit.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(habit.category.color)
                        .frame(width: 32)

                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                        Text(habit.name)
                            .font(SergiTheme.Typography.body)
                            .fontWeight(.medium)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(habit.category.color.opacity(0.15))

                                RoundedRectangle(cornerRadius: 3)
                                    .fill(habit.category.color)
                                    .frame(width: geo.size.width * habit.completionRate)
                            }
                        }
                        .frame(height: 6)
                    }

                    VStack(alignment: .trailing) {
                        Text("\(Int(habit.completionRate * 100))%")
                            .font(SergiTheme.Typography.caption)
                            .fontWeight(.semibold)
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 10))
                            Text("\(habit.currentStreak)")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(SergiTheme.Colors.streakColor(for: habit.currentStreak))
                    }
                }
            }
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    // MARK: - Gamification

    private var gamificationSection: some View {
        VStack(alignment: .leading, spacing: SergiTheme.Spacing.md) {
            Text("Достижения")
                .font(SergiTheme.Typography.h3)

            if let profile, !profile.badges.isEmpty {
                // XP bar
                XPProgressBar(
                    currentXP: profile.totalXP % profile.xpForNextLevel,
                    requiredXP: profile.xpForNextLevel,
                    level: profile.level
                )

                // Badges grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: SergiTheme.Spacing.md) {
                    ForEach(profile.badges) { badge in
                        VStack(spacing: SergiTheme.Spacing.xs) {
                            ZStack {
                                Circle()
                                    .fill(SergiTheme.Colors.accent.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                Image(systemName: badge.type.icon)
                                    .font(.system(size: 22))
                                    .foregroundStyle(SergiTheme.Colors.accent)
                            }
                            Text(badge.type.displayName)
                                .font(.system(size: 10))
                                .foregroundStyle(SergiTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                    }
                }
            } else {
                EmptyStateView(
                    icon: "trophy",
                    title: "Пока нет значков",
                    subtitle: "Выполняй привычки, чтобы получать награды!"
                )
            }
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    // MARK: - Mood Trend

    private var moodTrend: some View {
        VStack(alignment: .leading, spacing: SergiTheme.Spacing.md) {
            Text("Настроение")
                .font(SergiTheme.Typography.h3)

            let recentMoods = journalEntries
                .sorted { $0.date > $1.date }
                .prefix(7)
                .reversed()

            Chart(Array(recentMoods), id: \.id) { entry in
                LineMark(
                    x: .value("День", entry.date, unit: .day),
                    y: .value("Настроение", entry.mood.rawValue)
                )
                .foregroundStyle(SergiTheme.Colors.primary)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("День", entry.date, unit: .day),
                    y: .value("Настроение", entry.mood.rawValue)
                )
                .foregroundStyle(SergiTheme.Colors.primary)
                .annotation {
                    Text(entry.mood.emoji)
                        .font(.system(size: 16))
                }
            }
            .chartYScale(domain: 1...5)
            .frame(height: 150)
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    // MARK: - Correlations

    private var correlationsSection: some View {
        VStack(alignment: .leading, spacing: SergiTheme.Spacing.md) {
            Text("Корреляции")
                .font(SergiTheme.Typography.h3)

            let correlations = computeCorrelations()
            if correlations.isEmpty {
                Text("Недостаточно данных для анализа. Продолжай отслеживать привычки!")
                    .font(SergiTheme.Typography.caption)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
            } else {
                ForEach(correlations, id: \.description) { item in
                    HStack(spacing: SergiTheme.Spacing.sm) {
                        Image(systemName: item.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(item.isPositive ? SergiTheme.Colors.success : SergiTheme.Colors.warning)
                            .frame(width: 24)

                        Text(item.description)
                            .font(SergiTheme.Typography.body)
                            .foregroundStyle(SergiTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    // MARK: - Patterns

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: SergiTheme.Spacing.md) {
            Text("Паттерны")
                .font(SergiTheme.Typography.h3)

            let patterns = detectPatterns()
            if patterns.isEmpty {
                Text("Паттерны появятся, когда соберётся больше данных")
                    .font(SergiTheme.Typography.caption)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
            } else {
                ForEach(patterns, id: \.self) { pattern in
                    HStack(spacing: SergiTheme.Spacing.sm) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(SergiTheme.Colors.accent)
                        Text(pattern)
                            .font(SergiTheme.Typography.body)
                            .foregroundStyle(SergiTheme.Colors.textSecondary)
                    }
                }
            }
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    // MARK: - Health Stats

    private var healthStatsSection: some View {
        VStack(alignment: .leading, spacing: SergiTheme.Spacing.md) {
            Text("Apple Health")
                .font(SergiTheme.Typography.h3)

            HStack(spacing: SergiTheme.Spacing.lg) {
                VStack(spacing: SergiTheme.Spacing.xs) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 22))
                        .foregroundStyle(SergiTheme.Colors.categoryHealth)
                    Text("\(healthSteps)")
                        .font(SergiTheme.Typography.statsNumberSmall)
                    Text("шагов")
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: SergiTheme.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(SergiTheme.Colors.accent)
                    Text("\(healthActiveMinutes)")
                        .font(SergiTheme.Typography.statsNumberSmall)
                    Text("мин")
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: SergiTheme.Spacing.xs) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(SergiTheme.Colors.primary)
                    Text(String(format: "%.1f", healthSleepHours))
                        .font(SergiTheme.Typography.statsNumberSmall)
                    Text("ч сна")
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    // MARK: - Helpers

    private func generateChartData() -> [DayCompletionData] {
        let calendar = Calendar.current
        let days: Int
        switch selectedPeriod {
        case .week: days = 7
        case .month: days = 30
        case .year: days = 365
        }

        return (0..<days).compactMap { offset -> DayCompletionData? in
            guard let date = calendar.date(byAdding: .day, value: -days + offset + 1, to: Date()) else { return nil }
            let dayStart = calendar.startOfDay(for: date)

            let totalHabits = max(1, habits.count)
            let completedCount = habits.reduce(0) { count, habit in
                let completed = habit.entries.contains {
                    calendar.startOfDay(for: $0.date) == dayStart && $0.isCompleted
                }
                return count + (completed ? 1 : 0)
            }

            return DayCompletionData(
                date: date,
                completionRate: Double(completedCount) / Double(totalHabits)
            )
        }
    }

    private func loadInsight() async {
        let aiCoach = AICoachService(modelContext: modelContext)
        var rates: [String: Double] = [:]
        for habit in habits {
            let service = HabitService(modelContext: modelContext)
            rates[habit.name] = service.completionRate(for: habit, days: 7)
        }
        aiInsight = await aiCoach.generateDailyInsight(completionRates: rates)
    }

    // MARK: - Correlation Analysis

    private struct CorrelationItem {
        let description: String
        let icon: String
        let isPositive: Bool
    }

    private func computeCorrelations() -> [CorrelationItem] {
        let calendar = Calendar.current
        var items: [CorrelationItem] = []

        // Mood ↔ Completion correlation
        if !journalEntries.isEmpty && !habits.isEmpty {
            let last14Days = (0..<14).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }
            var goodMoodCompletionRate = 0.0
            var badMoodCompletionRate = 0.0
            var goodCount = 0
            var badCount = 0

            for day in last14Days {
                let dayStart = calendar.startOfDay(for: day)
                let dayMood = journalEntries.first { calendar.startOfDay(for: $0.date) == dayStart }
                let activeHabits = habits.filter { $0.isActive }
                guard !activeHabits.isEmpty else { continue }
                let completedCount = activeHabits.filter { habit in
                    habit.entries.contains { calendar.startOfDay(for: $0.date) == dayStart && $0.isCompleted }
                }.count
                let rate = Double(completedCount) / Double(activeHabits.count)

                if let mood = dayMood {
                    if mood.mood.rawValue >= 4 {
                        goodMoodCompletionRate += rate
                        goodCount += 1
                    } else if mood.mood.rawValue <= 2 {
                        badMoodCompletionRate += rate
                        badCount += 1
                    }
                }
            }

            if goodCount > 0 && badCount > 0 {
                let avgGood = goodMoodCompletionRate / Double(goodCount)
                let avgBad = badMoodCompletionRate / Double(badCount)
                let diff = avgGood - avgBad
                if diff > 0.15 {
                    items.append(CorrelationItem(
                        description: "В хорошем настроении ты выполняешь на \(Int(diff * 100))% больше привычек",
                        icon: "face.smiling.inverse",
                        isPositive: true
                    ))
                }
            }
        }

        // Weekday ↔ Weekend comparison
        if !habits.isEmpty {
            var weekdayRate = 0.0, weekendRate = 0.0
            var wdCount = 0, weCount = 0

            for habit in habits {
                for entry in habit.entries where entry.isCompleted {
                    let wd = calendar.component(.weekday, from: entry.date)
                    if wd == 1 || wd == 7 {
                        weekendRate += 1; weCount += 1
                    } else {
                        weekdayRate += 1; wdCount += 1
                    }
                }
            }

            if wdCount > 5 && weCount > 2 {
                let avgWd = weekdayRate / Double(wdCount)
                let avgWe = weekendRate / Double(weCount)
                if avgWd > avgWe * 1.3 {
                    items.append(CorrelationItem(
                        description: "По будням ты продуктивнее, чем по выходным",
                        icon: "briefcase.fill",
                        isPositive: true
                    ))
                } else if avgWe > avgWd * 1.3 {
                    items.append(CorrelationItem(
                        description: "По выходным ты выполняешь привычки лучше",
                        icon: "sun.max.fill",
                        isPositive: true
                    ))
                }
            }
        }

        return items
    }

    private func detectPatterns() -> [String] {
        let calendar = Calendar.current
        var patterns: [String] = []

        // Best time of day
        var morningCount = 0, afternoonCount = 0, eveningCount = 0
        for habit in habits {
            for entry in habit.entries where entry.isCompleted {
                if let completedAt = entry.completedAt {
                    let hour = calendar.component(.hour, from: completedAt)
                    switch hour {
                    case 5..<12: morningCount += 1
                    case 12..<17: afternoonCount += 1
                    default: eveningCount += 1
                    }
                }
            }
        }

        let total = morningCount + afternoonCount + eveningCount
        if total > 7 {
            if morningCount > afternoonCount && morningCount > eveningCount {
                patterns.append("Ты наиболее продуктивен утром (до 12:00)")
            } else if afternoonCount > morningCount && afternoonCount > eveningCount {
                patterns.append("Твой пик продуктивности — днём (12:00–17:00)")
            } else if eveningCount > morningCount && eveningCount > afternoonCount {
                patterns.append("Ты чаще всего выполняешь привычки вечером")
            }
        }

        // Best day of week
        var dayCounts: [Int: Int] = [:]
        for habit in habits {
            for entry in habit.entries where entry.isCompleted {
                let wd = calendar.component(.weekday, from: entry.date)
                dayCounts[wd, default: 0] += 1
            }
        }

        if let bestDay = dayCounts.max(by: { $0.value < $1.value }), bestDay.value > 3 {
            let dayNames = [1: "воскресенье", 2: "понедельник", 3: "вторник", 4: "среда", 5: "четверг", 6: "пятница", 7: "суббота"]
            if let dayName = dayNames[bestDay.key] {
                patterns.append("Самый продуктивный день — \(dayName)")
            }
        }

        // Streak pattern
        let streaks = habits.map(\.currentStreak).filter { $0 > 0 }
        if let maxStreak = streaks.max(), maxStreak > 7 {
            let habitName = habits.first(where: { $0.currentStreak == maxStreak })?.name ?? ""
            patterns.append("Лучшая серия: \(maxStreak) дней (\(habitName))")
        }

        // Risk detection
        let riskyHabits = habits.filter { habit in
            habit.isActive && habit.completionRate < 0.3 && habit.entries.count > 7
        }
        if !riskyHabits.isEmpty {
            let names = riskyHabits.prefix(2).map(\.name).joined(separator: ", ")
            patterns.append("⚠️ Низкая вовлечённость: \(names)")
        }

        return patterns
    }
}

// MARK: - Models

private struct DayCompletionData {
    let date: Date
    let completionRate: Double
}

private enum StatPeriod: CaseIterable {
    case week, month, year

    var displayName: String {
        switch self {
        case .week: return "Неделя"
        case .month: return "Месяц"
        case .year: return "Год"
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: SergiTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)

            Text(value)
                .font(SergiTheme.Typography.statsNumberSmall)
                .foregroundStyle(SergiTheme.Colors.textPrimary)

            Text(title)
                .font(SergiTheme.Typography.caption)
                .foregroundStyle(SergiTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }
}
