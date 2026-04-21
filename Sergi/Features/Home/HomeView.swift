import SwiftUI
import SwiftData

// MARK: - Home View (Main Screen)

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Habit> { $0.archivedAt == nil },
           sort: \Habit.sortOrder)
    private var habits: [Habit]

    @Query private var profiles: [UserProfile]

    @State private var showCreateSheet = false
    @State private var selectedHabit: Habit?
    @State private var dailyMotivation = ""
    @State private var showCelebration = false
    @State private var celebrationReward: CompletionReward?
    @State private var healthSteps: Int = 0
    @State private var healthActiveMinutes: Int = 0
    @State private var showPaywall = false

    private var profile: UserProfile? { profiles.first }

    private var todayHabits: [Habit] {
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

    private var completedCount: Int {
        todayHabits.filter(\.isCompletedToday).count
    }

    private var dailyProgress: Double {
        guard !todayHabits.isEmpty else { return 0 }
        return Double(completedCount) / Double(todayHabits.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SergiTheme.Colors.backgroundLight
                    .ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: SergiTheme.Spacing.md) {
                        // Header with motivation
                        headerSection

                        // Daily progress ring
                        dailyProgressSection

                        // HealthKit data
                        if HealthKitService.shared.isAuthorized {
                            healthSection
                        }

                        // Habit list
                        if todayHabits.isEmpty {
                            EmptyStateView(
                                icon: "plus.circle.fill",
                                title: "Начни с первой привычки",
                                subtitle: "Нажми +, чтобы создать привычку или выбрать из библиотеки",
                                actionTitle: "Добавить привычку"
                            ) {
                                showCreateSheet = true
                            }
                            .padding(.top, SergiTheme.Spacing.xxl)
                        } else {
                            habitListSection
                        }

                        // All done celebration
                        if dailyProgress >= 1.0 && !todayHabits.isEmpty {
                            allDoneSection
                        }
                    }
                    .padding(.horizontal, SergiTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading) {
                        Text(greeting)
                            .font(SergiTheme.Typography.caption)
                            .foregroundStyle(SergiTheme.Colors.textSecondary)
                        Text(profile?.displayName ?? "Друг")
                            .font(SergiTheme.Typography.h3)
                            .foregroundStyle(SergiTheme.Colors.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: SergiTheme.Spacing.sm) {
                        if let profile {
                            StreakBadge(days: maxStreak)
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateHabitView()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(item: $selectedHabit) { habit in
                HabitDetailSheet(habit: habit)
            }
            .overlay {
                if showCelebration, let reward = celebrationReward {
                    CelebrationOverlay(reward: reward) {
                        showCelebration = false
                    }
                }
            }
            .task {
                await loadMotivation()
                if HealthKitService.shared.isAuthorized {
                    healthSteps = await HealthKitService.shared.fetchTodaySteps()
                    healthActiveMinutes = await HealthKitService.shared.fetchTodayActiveMinutes()
                }
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Group {
            if !dailyMotivation.isEmpty {
                HStack(spacing: SergiTheme.Spacing.sm) {
                    Image(systemName: "brain.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(SergiTheme.Colors.primary)

                    Text(dailyMotivation)
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
        }
    }

    private var dailyProgressSection: some View {
        HStack(spacing: SergiTheme.Spacing.lg) {
            ProgressRingView(
                progress: dailyProgress,
                lineWidth: 10,
                size: 80,
                color: SergiTheme.Colors.primary
            )

            VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                Text("Сегодня")
                    .font(SergiTheme.Typography.h3)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)

                Text("\(completedCount) из \(todayHabits.count) привычек")
                    .font(SergiTheme.Typography.body)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)

                Text(dateString)
                    .font(SergiTheme.Typography.caption)
                    .foregroundStyle(SergiTheme.Colors.textTertiary)
            }

            Spacer()
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    private var habitListSection: some View {
        VStack(spacing: SergiTheme.Spacing.sm) {
            // Pending habits first
            let pending = todayHabits.filter { !$0.isCompletedToday }
            let completed = todayHabits.filter { $0.isCompletedToday }

            ForEach(pending) { habit in
                HabitCardView(
                    habit: habit,
                    onToggle: { toggleHabit(habit) },
                    onTap: { selectedHabit = habit }
                )
                .transition(.asymmetric(
                    insertion: .slide.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }

            if !completed.isEmpty && !pending.isEmpty {
                HStack {
                    Text("Выполнено")
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textTertiary)
                    Rectangle()
                        .fill(SergiTheme.Colors.textTertiary.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.top, SergiTheme.Spacing.sm)
            }

            ForEach(completed) { habit in
                HabitCardView(
                    habit: habit,
                    onToggle: { toggleHabit(habit) },
                    onTap: { selectedHabit = habit }
                )
                .opacity(0.7)
            }
        }
    }

    private var allDoneSection: some View {
        VStack(spacing: SergiTheme.Spacing.md) {
            Text("🎉")
                .font(.system(size: 48))

            Text("Отличный день!")
                .font(SergiTheme.Typography.h2)
                .foregroundStyle(SergiTheme.Colors.textPrimary)

            Text("Все привычки выполнены. Так держать!")
                .font(SergiTheme.Typography.body)
                .foregroundStyle(SergiTheme.Colors.textSecondary)
        }
        .padding(SergiTheme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: SergiTheme.Radius.large)
                .fill(
                    LinearGradient(
                        colors: [SergiTheme.Colors.success.opacity(0.1), SergiTheme.Colors.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
    }

    // MARK: - Health Section

    private var healthSection: some View {
        HStack(spacing: SergiTheme.Spacing.md) {
            HStack(spacing: SergiTheme.Spacing.sm) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 16))
                    .foregroundStyle(SergiTheme.Colors.categoryHealth)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(healthSteps)")
                        .font(SergiTheme.Typography.h3)
                        .foregroundStyle(SergiTheme.Colors.textPrimary)
                    Text("шагов")
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                }
            }

            Spacer()

            HStack(spacing: SergiTheme.Spacing.sm) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(SergiTheme.Colors.accent)
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(healthActiveMinutes)")
                        .font(SergiTheme.Typography.h3)
                        .foregroundStyle(SergiTheme.Colors.textPrimary)
                    Text("мин активности")
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    // MARK: - Actions

    private func toggleHabit(_ habit: Habit) {
        let habitService = HabitService(modelContext: modelContext)
        habitService.toggleToday(for: habit)

        if habit.isCompletedToday, let profile {
            let gamification = GamificationService(modelContext: modelContext)
            let reward = gamification.onHabitCompleted(
                habit: habit,
                profile: profile,
                allHabits: Array(habits)
            )
            if reward.shouldCelebrate {
                celebrationReward = reward
                showCelebration = true
            }
        }
    }

    private func loadMotivation() async {
        guard let habit = todayHabits.first(where: { !$0.isCompletedToday }) else {
            if !todayHabits.isEmpty {
                dailyMotivation = "Все привычки на сегодня выполнены! 🌟"
            }
            return
        }

        let aiCoach = AICoachService(modelContext: modelContext)
        dailyMotivation = await aiCoach.generateMotivation(
            habitName: habit.name,
            streakDays: habit.currentStreak,
            recentSkips: 0
        )
    }

    // MARK: - Helpers

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Доброе утро"
        case 12..<17: return "Добрый день"
        case 17..<22: return "Добрый вечер"
        default: return "Доброй ночи"
        }
    }

    private var dateString: String {
        Self.russianDateFormatter.string(from: Date()).capitalized
    }

    private static let russianDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter
    }()

    private var maxStreak: Int {
        habits.map(\.currentStreak).max() ?? 0
    }
}

// MARK: - Celebration Overlay

struct CelebrationOverlay: View {
    let reward: CompletionReward
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.4 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: SergiTheme.Spacing.lg) {
                if reward.didLevelUp {
                    Text("⬆️ Новый уровень!")
                        .font(SergiTheme.Typography.h1)
                }

                if let milestone = reward.streakMilestone {
                    Text("🔥 \(milestone) дней подряд!")
                        .font(SergiTheme.Typography.h2)
                }

                if reward.isPerfectDay {
                    Text("✨ Идеальный день!")
                        .font(SergiTheme.Typography.h2)
                }

                ForEach(reward.newBadges, id: \.rawValue) { badge in
                    HStack(spacing: SergiTheme.Spacing.sm) {
                        Image(systemName: badge.icon)
                            .font(.system(size: 28))
                        Text(badge.displayName)
                            .font(SergiTheme.Typography.h3)
                    }
                    .foregroundStyle(SergiTheme.Colors.accent)
                }

                Text("+\(reward.xpEarned) XP")
                    .font(SergiTheme.Typography.statsNumber)
                    .foregroundStyle(SergiTheme.Colors.accent)

                Button("Отлично!", action: onDismiss)
                    .buttonStyle(.sergiPrimary)
                    .frame(maxWidth: 200)
            }
            .padding(SergiTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: SergiTheme.Radius.xl)
                    .fill(.ultraThinMaterial)
            )
            .foregroundStyle(.white)
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(SergiTheme.Animation.celebration) {
                appeared = true
            }
        }
    }
}

// MARK: - Habit Detail Sheet

struct HabitDetailSheet: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SergiTheme.Spacing.lg) {
                    // Icon & Name
                    VStack(spacing: SergiTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(habit.category.color.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: habit.icon)
                                .font(.system(size: 36))
                                .foregroundStyle(habit.category.color)
                        }

                        Text(habit.name)
                            .font(SergiTheme.Typography.h2)

                        HStack(spacing: SergiTheme.Spacing.md) {
                            Label(habit.frequency.displayName, systemImage: "calendar")
                            Label(habit.category.displayName, systemImage: habit.category.icon)
                        }
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                    }

                    // Stats
                    HStack(spacing: SergiTheme.Spacing.lg) {
                        StatBox(title: "Текущая серия", value: "\(habit.currentStreak)", icon: "flame.fill", color: SergiTheme.Colors.streakColor(for: habit.currentStreak))
                        StatBox(title: "Лучшая серия", value: "\(habit.bestStreak)", icon: "trophy.fill", color: SergiTheme.Colors.accent)
                        StatBox(title: "Выполнение", value: "\(Int(habit.completionRate * 100))%", icon: "chart.bar.fill", color: SergiTheme.Colors.primary)
                    }

                    // Heat map
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        Text("История")
                            .font(SergiTheme.Typography.h3)
                        HeatMapCalendarView(entries: habit.entries, weeks: 12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(SergiTheme.Spacing.md)
                    .sergiCard()

                    // Why
                    if let why = habit.whyMotivation, !why.isEmpty {
                        VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                            Text("Почему это важно")
                                .font(SergiTheme.Typography.h3)
                            Text(why)
                                .font(SergiTheme.Typography.body)
                                .foregroundStyle(SergiTheme.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(SergiTheme.Spacing.md)
                        .sergiCard()
                    }
                }
                .padding(SergiTheme.Spacing.lg)
            }
            .background(SergiTheme.Colors.backgroundLight)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Stat Box

private struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: SergiTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
            Text(value)
                .font(SergiTheme.Typography.statsNumberSmall)
                .foregroundStyle(SergiTheme.Colors.textPrimary)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(SergiTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }
}
