import SwiftUI
import SwiftData

// MARK: - Goals View

struct GoalsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]

    @State private var showCreateGoal = false
    @State private var selectedGoal: Goal?

    var body: some View {
        NavigationStack {
            ZStack {
                SergiTheme.Colors.backgroundLight
                    .ignoresSafeArea()

                if goals.isEmpty {
                    EmptyStateView(
                        icon: "target",
                        title: "Нет целей",
                        subtitle: "Создай цель, чтобы объединить привычки в осмысленный план",
                        actionTitle: "Создать цель"
                    ) {
                        showCreateGoal = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: SergiTheme.Spacing.sm) {
                            ForEach(goals) { goal in
                                GoalCardView(goal: goal)
                                    .onTapGesture { selectedGoal = goal }
                            }
                        }
                        .padding(SergiTheme.Spacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Цели")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateGoal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateGoal) {
                CreateGoalView()
            }
            .sheet(item: $selectedGoal) { goal in
                GoalDetailView(goal: goal)
            }
        }
    }
}

// MARK: - Goal Card

private struct GoalCardView: View {
    let goal: Goal

    private var progress: Double {
        guard !goal.habits.isEmpty else { return 0 }
        let completed = goal.habits.filter { $0.isCompletedToday }.count
        return Double(completed) / Double(goal.habits.count)
    }

    var body: some View {
        HStack(spacing: SergiTheme.Spacing.md) {
            ProgressRingView(
                progress: progress,
                lineWidth: 6,
                size: 50,
                color: SergiTheme.Colors.primary,
                showPercentage: false
            )

            VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                HStack {
                    Text(goal.title)
                        .font(SergiTheme.Typography.h3)
                        .foregroundStyle(SergiTheme.Colors.textPrimary)

                    if goal.isCompleted {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(SergiTheme.Colors.success)
                    }
                }

                if !goal.goalDescription.isEmpty {
                    Text(goal.goalDescription)
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                        .lineLimit(1)
                }

                HStack(spacing: SergiTheme.Spacing.sm) {
                    Label("\(goal.habits.count) привычек", systemImage: "checklist")
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textTertiary)

                    if let deadline = goal.deadline {
                        Label(deadlineString(deadline), systemImage: "calendar")
                            .font(SergiTheme.Typography.caption)
                            .foregroundStyle(deadline < Date() ? SergiTheme.Colors.error : SergiTheme.Colors.textTertiary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(SergiTheme.Colors.textTertiary)
        }
        .padding(SergiTheme.Spacing.md)
        .sergiCard()
    }

    private func deadlineString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

// MARK: - Create Goal View

struct CreateGoalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<Habit> { $0.archivedAt == nil }, sort: \Habit.sortOrder)
    private var availableHabits: [Habit]

    @State private var title = ""
    @State private var description = ""
    @State private var hasDeadline = false
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var availableMinutes = 30
    @State private var identityStatement = ""
    @State private var selectedHabitIDs: Set<UUID> = []
    @State private var showAISuggestions = false
    @State private var aiSuggestions: [HabitSuggestion] = []
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SergiTheme.Spacing.lg) {
                    // Title
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        Text("НАЗВАНИЕ ЦЕЛИ")
                            .font(SergiTheme.Typography.caption)
                            .foregroundStyle(SergiTheme.Colors.textSecondary)
                            .textCase(.uppercase)

                        TextField("Например: Пробежать полумарафон", text: $title)
                            .font(SergiTheme.Typography.h3)
                            .padding(SergiTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                    .fill(SergiTheme.Colors.surfaceLight)
                            )
                    }

                    // Description
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        Text("ОПИСАНИЕ")
                            .font(SergiTheme.Typography.caption)
                            .foregroundStyle(SergiTheme.Colors.textSecondary)

                        TextField("Зачем тебе эта цель?", text: $description, axis: .vertical)
                            .font(SergiTheme.Typography.body)
                            .lineLimit(2...5)
                            .padding(SergiTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                    .fill(SergiTheme.Colors.surfaceLight)
                            )
                    }

                    // Identity statement
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        Text("КЕМ ТЫ ХОЧЕШЬ СТАТЬ? (НЕОБЯЗАТЕЛЬНО)")
                            .font(SergiTheme.Typography.caption)
                            .foregroundStyle(SergiTheme.Colors.textSecondary)

                        TextField("Я — человек, который...", text: $identityStatement)
                            .font(SergiTheme.Typography.body)
                            .padding(SergiTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                    .fill(SergiTheme.Colors.surfaceLight)
                            )
                    }

                    // Deadline
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        Toggle("Дедлайн", isOn: $hasDeadline)
                        if hasDeadline {
                            DatePicker("Дата", selection: $deadline, in: Date()..., displayedComponents: .date)
                        }
                    }
                    .padding(SergiTheme.Spacing.md)
                    .sergiCard()

                    // Available time
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        Text("ДОСТУПНОЕ ВРЕМЯ В ДЕНЬ")
                            .font(SergiTheme.Typography.caption)
                            .foregroundStyle(SergiTheme.Colors.textSecondary)

                        Stepper("\(availableMinutes) минут", value: $availableMinutes, in: 5...240, step: 5)
                            .padding(SergiTheme.Spacing.md)
                            .sergiCard()
                    }

                    // Link existing habits
                    if !availableHabits.isEmpty {
                        VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                            Text("ПРИВЯЗАТЬ ПРИВЫЧКИ")
                                .font(SergiTheme.Typography.caption)
                                .foregroundStyle(SergiTheme.Colors.textSecondary)

                            ForEach(availableHabits) { habit in
                                Button {
                                    if selectedHabitIDs.contains(habit.id) {
                                        selectedHabitIDs.remove(habit.id)
                                    } else {
                                        selectedHabitIDs.insert(habit.id)
                                    }
                                } label: {
                                    HStack(spacing: SergiTheme.Spacing.sm) {
                                        Image(systemName: selectedHabitIDs.contains(habit.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedHabitIDs.contains(habit.id) ? SergiTheme.Colors.primary : SergiTheme.Colors.textTertiary)
                                        Image(systemName: habit.icon)
                                            .font(.system(size: 16))
                                            .foregroundStyle(habit.category.color)
                                        Text(habit.name)
                                            .font(SergiTheme.Typography.body)
                                            .foregroundStyle(SergiTheme.Colors.textPrimary)
                                        Spacer()
                                    }
                                    .padding(SergiTheme.Spacing.sm)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(SergiTheme.Spacing.md)
                        .sergiCard()
                    }

                    // AI suggestions
                    VStack(spacing: SergiTheme.Spacing.md) {
                        Button {
                            generateAISuggestions()
                        } label: {
                            HStack(spacing: SergiTheme.Spacing.sm) {
                                if isGenerating {
                                    ProgressView()
                                        .tint(SergiTheme.Colors.primary)
                                } else {
                                    Image(systemName: "brain.fill")
                                }
                                Text("AI подберёт привычки для цели")
                            }
                        }
                        .buttonStyle(.sergiSecondary)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isGenerating)

                        ForEach(aiSuggestions) { suggestion in
                            HStack(spacing: SergiTheme.Spacing.sm) {
                                Image(systemName: suggestion.icon)
                                    .foregroundStyle(suggestion.category.color)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(suggestion.name)
                                        .font(SergiTheme.Typography.body)
                                        .fontWeight(.medium)
                                    Text(suggestion.reason)
                                        .font(SergiTheme.Typography.caption)
                                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding(SergiTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                    .fill(SergiTheme.Colors.primary.opacity(0.05))
                            )
                        }
                    }
                }
                .padding(SergiTheme.Spacing.lg)
            }
            .background(SergiTheme.Colors.backgroundLight)
            .navigationTitle("Новая цель")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Создать") { createGoal() }
                        .fontWeight(.semibold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func generateAISuggestions() {
        isGenerating = true
        Task {
            let aiCoach = AICoachService(modelContext: modelContext)
            aiSuggestions = await aiCoach.generateHabitPlan(
                goal: title,
                availableMinutes: availableMinutes,
                currentLevel: nil,
                timeframe: hasDeadline ? "до \(deadlineString)" : nil
            )
            isGenerating = false
        }
    }

    private var deadlineString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: deadline)
    }

    private func createGoal() {
        let goal = Goal(
            title: title,
            description: description,
            deadline: hasDeadline ? deadline : nil,
            availableMinutesPerDay: availableMinutes
        )
        goal.identityStatement = identityStatement.isEmpty ? nil : identityStatement

        // Link selected existing habits
        for habit in availableHabits where selectedHabitIDs.contains(habit.id) {
            goal.habits.append(habit)
            habit.goal = goal
            habit.linkedGoalID = goal.id
        }

        // Create habits from AI suggestions
        let habitService = HabitService(modelContext: modelContext)
        for suggestion in aiSuggestions {
            let habit = habitService.createHabit(
                name: suggestion.name,
                icon: suggestion.icon,
                category: suggestion.category,
                frequency: suggestion.frequency,
                targetDuration: TimeInterval(suggestion.durationMinutes * 60),
                isAIGenerated: true,
                goal: goal
            )
            habit.linkedGoalID = goal.id
        }

        modelContext.insert(goal)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Goal Detail View

struct GoalDetailView: View {
    let goal: Goal
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SergiTheme.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        Text(goal.title)
                            .font(SergiTheme.Typography.h1)

                        if !goal.goalDescription.isEmpty {
                            Text(goal.goalDescription)
                                .font(SergiTheme.Typography.body)
                                .foregroundStyle(SergiTheme.Colors.textSecondary)
                        }

                        if let identity = goal.identityStatement, !identity.isEmpty {
                            HStack(spacing: SergiTheme.Spacing.sm) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(SergiTheme.Colors.primary)
                                Text(identity)
                                    .font(SergiTheme.Typography.body)
                                    .italic()
                                    .foregroundStyle(SergiTheme.Colors.primary)
                            }
                            .padding(SergiTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                    .fill(SergiTheme.Colors.primary.opacity(0.08))
                            )
                        }
                    }

                    // Progress
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.md) {
                        Text("Прогресс")
                            .font(SergiTheme.Typography.h3)

                        let overallRate = goalCompletionRate
                        HStack(spacing: SergiTheme.Spacing.lg) {
                            ProgressRingView(
                                progress: overallRate,
                                lineWidth: 8,
                                size: 80,
                                color: SergiTheme.Colors.primary
                            )

                            VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                                Text("\(goal.habits.count) привычек привязано")
                                    .font(SergiTheme.Typography.body)
                                if let deadline = goal.deadline {
                                    let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
                                    Text(daysLeft > 0 ? "Осталось \(daysLeft) дн." : "Дедлайн прошёл")
                                        .font(SergiTheme.Typography.caption)
                                        .foregroundStyle(daysLeft > 0 ? SergiTheme.Colors.textSecondary : SergiTheme.Colors.error)
                                }
                            }
                        }
                    }
                    .padding(SergiTheme.Spacing.md)
                    .sergiCard()

                    // Linked habits
                    if !goal.habits.isEmpty {
                        VStack(alignment: .leading, spacing: SergiTheme.Spacing.md) {
                            Text("Привычки")
                                .font(SergiTheme.Typography.h3)

                            ForEach(goal.habits) { habit in
                                HStack(spacing: SergiTheme.Spacing.md) {
                                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(habit.isCompletedToday ? SergiTheme.Colors.success : SergiTheme.Colors.textTertiary)

                                    Image(systemName: habit.icon)
                                        .font(.system(size: 18))
                                        .foregroundStyle(habit.category.color)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(habit.name)
                                            .font(SergiTheme.Typography.body)
                                            .strikethrough(habit.isCompletedToday, color: SergiTheme.Colors.textTertiary)
                                        HStack(spacing: SergiTheme.Spacing.sm) {
                                            Text("\(Int(habit.completionRate * 100))%")
                                                .font(SergiTheme.Typography.caption)
                                                .foregroundStyle(SergiTheme.Colors.textSecondary)
                                            if habit.currentStreak > 0 {
                                                StreakBadge(days: habit.currentStreak)
                                            }
                                        }
                                    }

                                    Spacer()
                                }
                                .padding(SergiTheme.Spacing.sm)
                            }
                        }
                        .padding(SergiTheme.Spacing.md)
                        .sergiCard()
                    }

                    // Actions
                    if !goal.isCompleted {
                        Button {
                            goal.isCompleted = true
                            try? modelContext.save()
                            dismiss()
                        } label: {
                            Text("Отметить цель выполненной")
                        }
                        .buttonStyle(.sergiPrimary)
                    }

                    Button(role: .destructive) {
                        modelContext.delete(goal)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Text("Удалить цель")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.sergiGhost)
                }
                .padding(SergiTheme.Spacing.lg)
            }
            .background(SergiTheme.Colors.backgroundLight)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private var goalCompletionRate: Double {
        guard !goal.habits.isEmpty else { return 0 }
        let rates = goal.habits.map(\.completionRate)
        return rates.reduce(0, +) / Double(rates.count)
    }
}
