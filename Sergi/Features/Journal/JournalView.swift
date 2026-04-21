import SwiftUI
import SwiftData

// MARK: - Journal View

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]

    @State private var showNewEntry = false
    @State private var selectedEntry: JournalEntry?

    var body: some View {
        NavigationStack {
            ZStack {
                SergiTheme.Colors.backgroundLight
                    .ignoresSafeArea()

                if entries.isEmpty {
                    EmptyStateView(
                        icon: "book.closed.fill",
                        title: "Журнал пуст",
                        subtitle: "Записывай свои мысли и отслеживай настроение каждый день",
                        actionTitle: "Написать"
                    ) {
                        showNewEntry = true
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: SergiTheme.Spacing.sm) {
                            ForEach(entries) { entry in
                                JournalEntryRow(entry: entry)
                                    .onTapGesture {
                                        selectedEntry = entry
                                    }
                            }
                        }
                        .padding(SergiTheme.Spacing.md)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Журнал")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewEntry = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showNewEntry) {
                NewJournalEntryView()
            }
            .sheet(item: $selectedEntry) { entry in
                JournalEntryDetailView(entry: entry)
            }
        }
    }
}

// MARK: - Journal Entry Row

private struct JournalEntryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack(spacing: SergiTheme.Spacing.md) {
            // Mood emoji
            Text(entry.mood.emoji)
                .font(.system(size: 32))
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(SergiTheme.Colors.primary.opacity(0.08))
                )

            VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                Text(dateString(entry.date))
                    .font(SergiTheme.Typography.h3)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)

                if let text = entry.reflectionText, !text.isEmpty {
                    Text(text)
                        .font(SergiTheme.Typography.body)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                        .lineLimit(2)
                }

                // Energy level
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { i in
                        Image(systemName: i < entry.energyLevel ? "bolt.fill" : "bolt")
                            .font(.system(size: 10))
                            .foregroundStyle(
                                i < entry.energyLevel
                                ? SergiTheme.Colors.accent
                                : SergiTheme.Colors.textTertiary
                            )
                    }
                    Text("Энергия")
                        .font(.system(size: 10))
                        .foregroundStyle(SergiTheme.Colors.textTertiary)
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

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM, EEEE"
        return formatter.string(from: date).capitalized
    }
}

// MARK: - New Journal Entry

struct NewJournalEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var mood: MoodLevel = .neutral
    @State private var reflectionText = ""
    @State private var energyLevel = 3
    @State private var gratitudeItems: [String] = ["", "", ""]
    @State private var aiQuestion = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SergiTheme.Spacing.xl) {
                    // Mood
                    VStack(spacing: SergiTheme.Spacing.md) {
                        Text("Как ты себя чувствуешь?")
                            .font(SergiTheme.Typography.h2)
                        MoodSelector(selected: $mood)
                    }

                    // Energy
                    VStack(spacing: SergiTheme.Spacing.sm) {
                        Text("Уровень энергии")
                            .font(SergiTheme.Typography.h3)
                        HStack(spacing: SergiTheme.Spacing.md) {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    energyLevel = level
                                } label: {
                                    Image(systemName: level <= energyLevel ? "bolt.fill" : "bolt")
                                        .font(.system(size: 28))
                                        .foregroundStyle(
                                            level <= energyLevel
                                            ? SergiTheme.Colors.accent
                                            : SergiTheme.Colors.textTertiary
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // AI Question
                    if !aiQuestion.isEmpty {
                        VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                            HStack(spacing: SergiTheme.Spacing.sm) {
                                Image(systemName: "brain.fill")
                                    .foregroundStyle(SergiTheme.Colors.primary)
                                Text("Sergi спрашивает:")
                                    .font(SergiTheme.Typography.caption)
                                    .foregroundStyle(SergiTheme.Colors.primary)
                            }
                            Text(aiQuestion)
                                .font(SergiTheme.Typography.bodyLarge)
                                .foregroundStyle(SergiTheme.Colors.textPrimary)
                        }
                        .padding(SergiTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                .fill(SergiTheme.Colors.primary.opacity(0.08))
                        )
                    }

                    // Reflection
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        Text("Мысли дня")
                            .font(SergiTheme.Typography.h3)
                        TextField("Что запомнилось сегодня?", text: $reflectionText, axis: .vertical)
                            .font(SergiTheme.Typography.body)
                            .lineLimit(3...10)
                            .padding(SergiTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                    .fill(SergiTheme.Colors.surfaceLight)
                            )
                    }

                    // Gratitude
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        Text("Благодарность")
                            .font(SergiTheme.Typography.h3)
                        Text("3 вещи, за которые ты благодарен сегодня")
                            .font(SergiTheme.Typography.caption)
                            .foregroundStyle(SergiTheme.Colors.textSecondary)

                        ForEach(0..<3, id: \.self) { index in
                            HStack(spacing: SergiTheme.Spacing.sm) {
                                Text("\(index + 1).")
                                    .font(SergiTheme.Typography.body)
                                    .foregroundStyle(SergiTheme.Colors.textTertiary)
                                    .frame(width: 24)
                                TextField("", text: $gratitudeItems[index])
                                    .font(SergiTheme.Typography.body)
                            }
                            .padding(SergiTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: SergiTheme.Radius.small)
                                    .fill(SergiTheme.Colors.surfaceLight)
                            )
                        }
                    }
                }
                .padding(SergiTheme.Spacing.lg)
            }
            .background(SergiTheme.Colors.backgroundLight)
            .navigationTitle("Запись в журнал")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Сохранить") { saveEntry() }
                        .fontWeight(.semibold)
                }
            }
            .task {
                let aiCoach = AICoachService(modelContext: modelContext)
                aiQuestion = await aiCoach.generateReflectionQuestion()
            }
        }
    }

    private func saveEntry() {
        let entry = JournalEntry(
            mood: mood,
            reflectionText: reflectionText.isEmpty ? nil : reflectionText,
            aiQuestion: aiQuestion.isEmpty ? nil : aiQuestion
        )
        entry.energyLevel = energyLevel
        entry.gratitudeItems = gratitudeItems.filter { !$0.isEmpty }
        modelContext.insert(entry)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Journal Entry Detail

private struct JournalEntryDetailView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: SergiTheme.Spacing.lg) {
                    // Mood & Energy
                    HStack {
                        VStack {
                            Text(entry.mood.emoji)
                                .font(.system(size: 48))
                            Text(entry.mood.label)
                                .font(SergiTheme.Typography.caption)
                        }
                        Spacer()
                        VStack {
                            HStack(spacing: 2) {
                                ForEach(0..<entry.energyLevel, id: \.self) { _ in
                                    Image(systemName: "bolt.fill")
                                        .foregroundStyle(SergiTheme.Colors.accent)
                                }
                            }
                            Text("Энергия: \(entry.energyLevel)/5")
                                .font(SergiTheme.Typography.caption)
                        }
                    }

                    if let text = entry.reflectionText, !text.isEmpty {
                        VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                            Text("Мысли")
                                .font(SergiTheme.Typography.h3)
                            Text(text)
                                .font(SergiTheme.Typography.body)
                                .foregroundStyle(SergiTheme.Colors.textSecondary)
                        }
                    }

                    if !entry.gratitudeItems.isEmpty {
                        VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                            Text("Благодарность")
                                .font(SergiTheme.Typography.h3)
                            ForEach(entry.gratitudeItems, id: \.self) { item in
                                HStack(spacing: SergiTheme.Spacing.sm) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 12))
                                        .foregroundStyle(SergiTheme.Colors.categoryRelationships)
                                    Text(item)
                                        .font(SergiTheme.Typography.body)
                                }
                            }
                        }
                    }

                    if let insight = entry.aiInsight, !insight.isEmpty {
                        HStack(spacing: SergiTheme.Spacing.sm) {
                            Image(systemName: "brain.fill")
                                .foregroundStyle(SergiTheme.Colors.primary)
                            Text(insight)
                                .font(SergiTheme.Typography.body)
                                .foregroundStyle(SergiTheme.Colors.textSecondary)
                        }
                        .padding(SergiTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                .fill(SergiTheme.Colors.primary.opacity(0.08))
                        )
                    }
                }
                .padding(SergiTheme.Spacing.lg)
            }
            .background(SergiTheme.Colors.backgroundLight)
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: entry.date)
    }
}
