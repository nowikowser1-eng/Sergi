import SwiftUI

// MARK: - Habit Card Component

struct HabitCardView: View {
    let habit: Habit
    let onToggle: () -> Void
    let onTap: () -> Void

    @State private var checkScale: CGFloat = 1.0
    @State private var showConfetti = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: SergiTheme.Spacing.md) {
                // Completion checkbox
                Button {
                    withAnimation(SergiTheme.Animation.celebration) {
                        checkScale = 0.8
                        onToggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(SergiTheme.Animation.celebration) {
                            checkScale = 1.15
                        }
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(SergiTheme.Animation.celebration) {
                            checkScale = 1.0
                        }
                    }
                    if !habit.isCompletedToday {
                        showConfetti = true
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(habit.isCompletedToday
                                  ? habit.category.color
                                  : Color.clear)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        habit.isCompletedToday
                                        ? habit.category.color
                                        : SergiTheme.Colors.textTertiary,
                                        lineWidth: 2
                                    )
                            )

                        if habit.isCompletedToday {
                            Image(systemName: "checkmark")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .scaleEffect(checkScale)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: habit.isCompletedToday)

                // Habit info
                VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                    Text(habit.name)
                        .font(SergiTheme.Typography.h3)
                        .foregroundStyle(
                            habit.isCompletedToday
                            ? SergiTheme.Colors.textTertiary
                            : SergiTheme.Colors.textPrimary
                        )
                        .strikethrough(habit.isCompletedToday, color: SergiTheme.Colors.textTertiary)

                    HStack(spacing: SergiTheme.Spacing.sm) {
                        Label(habit.frequency.shortName, systemImage: "calendar")
                            .font(SergiTheme.Typography.caption)
                            .foregroundStyle(SergiTheme.Colors.textSecondary)

                        if habit.currentStreak > 0 {
                            StreakBadge(days: habit.currentStreak)
                        }
                    }
                }

                Spacer()

                // Category icon
                Image(systemName: habit.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(habit.category.color.opacity(habit.isCompletedToday ? 0.4 : 1))
                    .frame(width: 32, height: 32)
            }
            .padding(SergiTheme.Spacing.md)
            .sergiCard()
        }
        .buttonStyle(.plain)
        .overlay {
            if showConfetti {
                MiniConfettiView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showConfetti = false
                        }
                    }
            }
        }
    }
}

// MARK: - Streak Badge

struct StreakBadge: View {
    let days: Int

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .font(.system(size: 11))
            Text("\(days)")
                .font(SergiTheme.Typography.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(SergiTheme.Colors.streakColor(for: days))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(SergiTheme.Colors.streakColor(for: days).opacity(0.15))
        )
    }
}

// MARK: - Streak Counter (large)

struct StreakCounterView: View {
    let days: Int
    let bestStreak: Int

    @State private var animatedDays: Int = 0

    var body: some View {
        VStack(spacing: SergiTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                SergiTheme.Colors.streakColor(for: days),
                                SergiTheme.Colors.streakColor(for: days).opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                VStack(spacing: 0) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)

                    Text("\(animatedDays)")
                        .font(SergiTheme.Typography.statsNumber)
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }
            }

            Text("дней подряд")
                .font(SergiTheme.Typography.caption)
                .foregroundStyle(SergiTheme.Colors.textSecondary)

            if bestStreak > days {
                Text("Лучший: \(bestStreak)")
                    .font(SergiTheme.Typography.caption)
                    .foregroundStyle(SergiTheme.Colors.textTertiary)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedDays = days
            }
        }
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let progress: Double // 0.0 - 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    var showPercentage: Bool = true

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.5), color],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * animatedProgress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            if showPercentage {
                Text("\(Int(animatedProgress * 100))%")
                    .font(size > 80 ? SergiTheme.Typography.statsNumberSmall : SergiTheme.Typography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = min(1.0, max(0, progress))
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeOut(duration: 0.5)) {
                animatedProgress = min(1.0, max(0, newValue))
            }
        }
    }
}

// MARK: - AI Message Bubble

struct AIMessageBubble: View {
    let message: AIChatMessage
    @State private var appeared = false

    var body: some View {
        HStack(alignment: .top, spacing: SergiTheme.Spacing.sm) {
            if message.role == .assistant {
                aiAvatar
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: SergiTheme.Spacing.xs) {
                Text(message.content)
                    .font(SergiTheme.Typography.body)
                    .foregroundStyle(message.role == .user ? .white : SergiTheme.Colors.textPrimary)
                    .padding(SergiTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: SergiTheme.Radius.large)
                            .fill(
                                message.role == .user
                                ? AnyShapeStyle(SergiTheme.Colors.primary)
                                : AnyShapeStyle(SergiTheme.Colors.backgroundLight)
                            )
                    )

                Text(message.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundStyle(SergiTheme.Colors.textTertiary)
            }
            .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(SergiTheme.Animation.standard) {
                appeared = true
            }
        }
    }

    private var aiAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [SergiTheme.Colors.primary, SergiTheme.Colors.primaryLight],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)

            Image(systemName: "brain.fill")
                .font(.system(size: 16))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotOpacities: [Double] = [0.3, 0.3, 0.3]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(SergiTheme.Colors.textTertiary)
                    .frame(width: 8, height: 8)
                    .opacity(dotOpacities[index])
            }
        }
        .padding(.horizontal, SergiTheme.Spacing.md)
        .padding(.vertical, SergiTheme.Spacing.sm)
        .background(
            Capsule()
                .fill(SergiTheme.Colors.backgroundLight)
        )
        .onAppear { startAnimation() }
    }

    private func startAnimation() {
        for i in 0..<3 {
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
                .delay(Double(i) * 0.2)
            ) {
                dotOpacities[i] = 1.0
            }
        }
    }
}

// MARK: - Mini Confetti

struct MiniConfettiView: View {
    @State private var particles: [(id: Int, offset: CGSize, rotation: Double, opacity: Double)] = []

    let colors: [Color] = [
        SergiTheme.Colors.accent,
        SergiTheme.Colors.primary,
        SergiTheme.Colors.success,
        SergiTheme.Colors.categoryRelationships,
        .yellow
    ]

    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colors[p.id % colors.count])
                    .frame(width: 6, height: 6)
                    .rotationEffect(.degrees(p.rotation))
                    .offset(p.offset)
                    .opacity(p.opacity)
            }
        }
        .onAppear { startConfetti() }
        .allowsHitTesting(false)
    }

    private func startConfetti() {
        for i in 0..<20 {
            let particle = (
                id: i,
                offset: CGSize.zero,
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            particles.append(particle)

            let targetOffset = CGSize(
                width: CGFloat.random(in: -80...80),
                height: CGFloat.random(in: -120...(-20))
            )

            withAnimation(
                .easeOut(duration: Double.random(in: 0.6...1.2))
                .delay(Double.random(in: 0...0.2))
            ) {
                particles[i].offset = targetOffset
                particles[i].rotation += Double.random(in: 180...720)
            }

            withAnimation(
                .easeIn(duration: 0.4)
                .delay(Double.random(in: 0.8...1.2))
            ) {
                particles[i].opacity = 0
            }
        }
    }
}

// MARK: - Heat Map Calendar

struct HeatMapCalendarView: View {
    let entries: [HabitEntry]
    let weeks: Int

    private let columns = Array(repeating: GridItem(.fixed(14), spacing: 2), count: 7)
    private let calendar = Calendar.current

    var body: some View {
        let days = generateDays()
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(days, id: \.self) { date in
                let hasEntry = entryFor(date)
                RoundedRectangle(cornerRadius: 2)
                    .fill(colorFor(entry: hasEntry))
                    .frame(width: 14, height: 14)
            }
        }
    }

    private func generateDays() -> [Date] {
        let today = calendar.startOfDay(for: Date())
        let totalDays = weeks * 7
        return (0..<totalDays).compactMap {
            calendar.date(byAdding: .day, value: -totalDays + $0 + 1, to: today)
        }
    }

    private func entryFor(_ date: Date) -> HabitEntry? {
        let day = calendar.startOfDay(for: date)
        return entries.first {
            calendar.startOfDay(for: $0.date) == day
        }
    }

    private func colorFor(entry: HabitEntry?) -> Color {
        guard let entry = entry else {
            return SergiTheme.Colors.backgroundLight
        }
        if entry.isCompleted {
            return SergiTheme.Colors.success.opacity(0.8)
        } else if entry.isFlexDay {
            return SergiTheme.Colors.warning.opacity(0.4)
        }
        return SergiTheme.Colors.error.opacity(0.3)
    }
}

// MARK: - Mood Selector

struct MoodSelector: View {
    @Binding var selected: MoodLevel

    var body: some View {
        HStack(spacing: SergiTheme.Spacing.md) {
            ForEach(MoodLevel.allCases) { mood in
                Button {
                    withAnimation(SergiTheme.Animation.celebration) {
                        selected = mood
                    }
                } label: {
                    VStack(spacing: SergiTheme.Spacing.xs) {
                        Text(mood.emoji)
                            .font(.system(size: selected == mood ? 36 : 28))
                        Text(mood.label)
                            .font(SergiTheme.Typography.caption)
                            .foregroundStyle(
                                selected == mood
                                ? SergiTheme.Colors.primary
                                : SergiTheme.Colors.textTertiary
                            )
                    }
                    .scaleEffect(selected == mood ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: selected)
            }
        }
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: SergiTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(SergiTheme.Colors.textTertiary)

            VStack(spacing: SergiTheme.Spacing.sm) {
                Text(title)
                    .font(SergiTheme.Typography.h3)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)

                Text(subtitle)
                    .font(SergiTheme.Typography.body)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.sergiPrimary)
                    .frame(maxWidth: 200)
            }
        }
        .padding(SergiTheme.Spacing.xl)
    }
}

// MARK: - XP Progress Bar

struct XPProgressBar: View {
    let currentXP: Int
    let requiredXP: Int
    let level: Int

    var progress: Double {
        guard requiredXP > 0 else { return 0 }
        return Double(currentXP) / Double(requiredXP)
    }

    var body: some View {
        VStack(spacing: SergiTheme.Spacing.xs) {
            HStack {
                Text("Уровень \(level)")
                    .font(SergiTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(SergiTheme.Colors.primary)

                Spacer()

                Text("\(currentXP)/\(requiredXP) XP")
                    .font(SergiTheme.Typography.caption)
                    .foregroundStyle(SergiTheme.Colors.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SergiTheme.Colors.primary.opacity(0.15))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [SergiTheme.Colors.primary, SergiTheme.Colors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut(duration: 0.8), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}
