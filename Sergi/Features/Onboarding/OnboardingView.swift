import SwiftUI
import SwiftData

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep: OnboardingStep = .welcome
    @State private var goalText = ""
    @State private var availableMinutes = 30
    @State private var selectedSuggestions: Set<UUID> = []
    @State private var suggestions: [HabitSuggestion] = []
    @State private var isGenerating = false
    @State private var userName = ""

    let onComplete: () -> Void

    var body: some View {
        ZStack {
            SergiTheme.Colors.backgroundLight
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress dots
                progressIndicator
                    .padding(.top, SergiTheme.Spacing.lg)

                // Content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(OnboardingStep.welcome)
                    nameStep.tag(OnboardingStep.name)
                    goalStep.tag(OnboardingStep.goal)
                    timeStep.tag(OnboardingStep.time)
                    suggestionsStep.tag(OnboardingStep.suggestions)
                    readyStep.tag(OnboardingStep.ready)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(SergiTheme.Animation.navigation, value: currentStep)

                // Navigation button
                bottomButton
                    .padding(SergiTheme.Spacing.xl)
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: SergiTheme.Spacing.sm) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Capsule()
                    .fill(step.rawValue <= currentStep.rawValue
                          ? SergiTheme.Colors.primary
                          : SergiTheme.Colors.primary.opacity(0.2))
                    .frame(height: 4)
                    .animation(SergiTheme.Animation.standard, value: currentStep)
            }
        }
        .padding(.horizontal, SergiTheme.Spacing.xl)
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: SergiTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SergiTheme.Colors.primary, SergiTheme.Colors.primaryLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                Image(systemName: "brain.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.white)
            }

            VStack(spacing: SergiTheme.Spacing.md) {
                Text("Привет!")
                    .font(SergiTheme.Typography.h1)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)

                Text("Я **Sergi** — твой персональный AI-коуч по привычкам")
                    .font(SergiTheme.Typography.bodyLarge)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                Text("Помогу создать привычки на основе науки и достичь твоих целей")
                    .font(SergiTheme.Typography.body)
                    .foregroundStyle(SergiTheme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, SergiTheme.Spacing.xl)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 2: Name

    private var nameStep: some View {
        VStack(spacing: SergiTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "hand.wave.fill")
                .font(.system(size: 60))
                .foregroundStyle(SergiTheme.Colors.accent)

            VStack(spacing: SergiTheme.Spacing.md) {
                Text("Как тебя зовут?")
                    .font(SergiTheme.Typography.h2)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)

                TextField("Твоё имя", text: $userName)
                    .font(SergiTheme.Typography.h3)
                    .multilineTextAlignment(.center)
                    .padding(SergiTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                            .fill(SergiTheme.Colors.surfaceLight)
                    )
                    .padding(.horizontal, SergiTheme.Spacing.xxl)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 3: Goal

    private var goalStep: some View {
        VStack(spacing: SergiTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "target")
                .font(.system(size: 60))
                .foregroundStyle(SergiTheme.Colors.primary)

            VStack(spacing: SergiTheme.Spacing.md) {
                Text("Какая твоя главная цель?")
                    .font(SergiTheme.Typography.h2)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)

                Text("Расскажи, и я подберу привычки для тебя")
                    .font(SergiTheme.Typography.body)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)

                TextField("Похудеть, выучить язык, стать продуктивнее...", text: $goalText, axis: .vertical)
                    .font(SergiTheme.Typography.body)
                    .lineLimit(3...5)
                    .padding(SergiTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                            .fill(SergiTheme.Colors.surfaceLight)
                    )
                    .padding(.horizontal, SergiTheme.Spacing.lg)

                // Quick picks
                quickGoalPicker
            }

            Spacer()
        }
    }

    private var quickGoalPicker: some View {
        let goals = [
            ("💪", "Быть здоровее"),
            ("📚", "Учиться"),
            ("⚡", "Продуктивность"),
            ("🧘", "Меньше стресса"),
        ]

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SergiTheme.Spacing.sm) {
            ForEach(goals, id: \.1) { emoji, title in
                Button {
                    goalText = title
                } label: {
                    HStack(spacing: SergiTheme.Spacing.sm) {
                        Text(emoji)
                        Text(title)
                            .font(SergiTheme.Typography.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(SergiTheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: SergiTheme.Radius.small)
                            .fill(goalText == title
                                  ? SergiTheme.Colors.primary.opacity(0.15)
                                  : SergiTheme.Colors.surfaceLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: SergiTheme.Radius.small)
                            .strokeBorder(goalText == title
                                          ? SergiTheme.Colors.primary
                                          : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, SergiTheme.Spacing.lg)
    }

    // MARK: - Step 4: Available Time

    private var timeStep: some View {
        VStack(spacing: SergiTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundStyle(SergiTheme.Colors.categoryProductivity)

            VStack(spacing: SergiTheme.Spacing.md) {
                Text("Сколько минут в день\nты готов уделять?")
                    .font(SergiTheme.Typography.h2)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("\(availableMinutes) мин")
                    .font(SergiTheme.Typography.statsNumber)
                    .foregroundStyle(SergiTheme.Colors.primary)
                    .contentTransition(.numericText())

                Slider(value: .init(
                    get: { Double(availableMinutes) },
                    set: { availableMinutes = Int($0) }
                ), in: 5...120, step: 5)
                .tint(SergiTheme.Colors.primary)
                .padding(.horizontal, SergiTheme.Spacing.xl)

                HStack {
                    Text("5 мин")
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textTertiary)
                    Spacer()
                    Text("2 часа")
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textTertiary)
                }
                .padding(.horizontal, SergiTheme.Spacing.xl)
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Step 5: AI Suggestions

    private var suggestionsStep: some View {
        VStack(spacing: SergiTheme.Spacing.lg) {
            VStack(spacing: SergiTheme.Spacing.sm) {
                Text("AI рекомендует")
                    .font(SergiTheme.Typography.h2)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)

                Text("Выбери привычки для начала")
                    .font(SergiTheme.Typography.body)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
            }
            .padding(.top, SergiTheme.Spacing.lg)

            if isGenerating {
                VStack(spacing: SergiTheme.Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("AI подбирает привычки...")
                        .font(SergiTheme.Typography.body)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: SergiTheme.Spacing.sm) {
                        ForEach(suggestions) { suggestion in
                            SuggestionRow(
                                suggestion: suggestion,
                                isSelected: selectedSuggestions.contains(suggestion.id),
                                onToggle: {
                                    if selectedSuggestions.contains(suggestion.id) {
                                        selectedSuggestions.remove(suggestion.id)
                                    } else {
                                        selectedSuggestions.insert(suggestion.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, SergiTheme.Spacing.lg)
                }
            }
        }
    }

    // MARK: - Step 6: Ready

    private var readyStep: some View {
        VStack(spacing: SergiTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(SergiTheme.Colors.success.opacity(0.15))
                    .frame(width: 140, height: 140)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(SergiTheme.Colors.success)
            }

            VStack(spacing: SergiTheme.Spacing.md) {
                Text("Всё готово! 🎉")
                    .font(SergiTheme.Typography.h1)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)

                Text("\(selectedSuggestions.count) привычек добавлены.\nНачни сегодня — всего по 1 маленькому шагу.")
                    .font(SergiTheme.Typography.bodyLarge)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, SergiTheme.Spacing.xl)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        Button {
            advanceStep()
        } label: {
            Text(buttonTitle)
        }
        .buttonStyle(.sergiPrimary)
        .disabled(isButtonDisabled)
        .opacity(isButtonDisabled ? 0.5 : 1)
    }

    private var buttonTitle: String {
        switch currentStep {
        case .welcome: return "Начать"
        case .name: return "Продолжить"
        case .goal: return "Подобрать привычки"
        case .time: return "Дальше"
        case .suggestions: return "Добавить \(selectedSuggestions.count) привычек"
        case .ready: return "Поехали! 🚀"
        }
    }

    private var isButtonDisabled: Bool {
        switch currentStep {
        case .goal: return goalText.trimmingCharacters(in: .whitespaces).isEmpty
        case .suggestions: return selectedSuggestions.isEmpty || isGenerating
        default: return false
        }
    }

    // MARK: - Navigation

    private func advanceStep() {
        switch currentStep {
        case .welcome:
            currentStep = .name
        case .name:
            currentStep = .goal
        case .goal:
            currentStep = .time
        case .time:
            currentStep = .suggestions
            generateSuggestions()
        case .suggestions:
            currentStep = .ready
            createSelectedHabits()
        case .ready:
            completeOnboarding()
        }
    }

    // MARK: - Logic

    private func generateSuggestions() {
        isGenerating = true

        // Use library-based suggestions (instant, offline-first)
        let templates = HabitLibrary.pack(for: goalText)
        suggestions = templates.map { template in
            HabitSuggestion(
                name: template.name,
                icon: template.icon,
                category: template.category,
                frequency: template.frequency,
                durationMinutes: Int(template.defaultDuration / 60),
                reason: template.scientificReason
            )
        }
        selectedSuggestions = Set(suggestions.map(\.id))
        isGenerating = false

        // Also try AI-powered suggestions asynchronously
        let capturedGoal = goalText
        let capturedMinutes = availableMinutes
        Task {
            let aiCoach = AICoachService(modelContext: modelContext)
            let aiSuggestions = await aiCoach.generateHabitPlan(
                goal: capturedGoal,
                availableMinutes: capturedMinutes,
                currentLevel: nil,
                timeframe: nil
            )
            // Only replace if user hasn't navigated away from suggestions step
            if !aiSuggestions.isEmpty && currentStep == .suggestions {
                suggestions = aiSuggestions
                selectedSuggestions = Set(aiSuggestions.map(\.id))
            }
        }
    }

    private func createSelectedHabits() {
        let habitService = HabitService(modelContext: modelContext)
        let goal = Goal(
            title: goalText,
            availableMinutesPerDay: availableMinutes
        )
        modelContext.insert(goal)

        for (index, suggestion) in suggestions.enumerated() {
            guard selectedSuggestions.contains(suggestion.id) else { continue }

            let habit = habitService.createHabit(
                name: suggestion.name,
                icon: suggestion.icon,
                category: suggestion.category,
                frequency: suggestion.frequency,
                targetDuration: TimeInterval(suggestion.durationMinutes * 60),
                isAIGenerated: true,
                goal: goal
            )
            habit.sortOrder = index
        }
    }

    private func completeOnboarding() {
        // Create or update user profile
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []

        if let profile = profiles.first {
            profile.displayName = userName.isEmpty ? "Друг" : userName
            profile.onboardingCompleted = true
        } else {
            let profile = UserProfile(displayName: userName.isEmpty ? "Друг" : userName)
            profile.onboardingCompleted = true
            modelContext.insert(profile)
        }

        try? modelContext.save()

        // Request notifications
        Task {
            await NotificationService.shared.requestAuthorization()
            NotificationService.shared.setupNotificationCategories()
            NotificationService.shared.scheduleEveningReflection()
            NotificationService.shared.scheduleWeeklyReview()
        }

        onComplete()
    }
}

// MARK: - Suggestion Row

private struct SuggestionRow: View {
    let suggestion: HabitSuggestion
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: SergiTheme.Spacing.md) {
                Image(systemName: suggestion.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(suggestion.category.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(suggestion.category.color.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                    Text(suggestion.name)
                        .font(SergiTheme.Typography.h3)
                        .foregroundStyle(SergiTheme.Colors.textPrimary)

                    Text(suggestion.reason)
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(isSelected ? SergiTheme.Colors.primary : SergiTheme.Colors.textTertiary)
            }
            .padding(SergiTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                    .fill(SergiTheme.Colors.surfaceLight)
                    .overlay(
                        RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                            .strokeBorder(isSelected ? SergiTheme.Colors.primary : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Onboarding Step

private enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case name = 1
    case goal = 2
    case time = 3
    case suggestions = 4
    case ready = 5
}
