import SwiftUI
import SwiftData

// MARK: - Create Habit View

struct CreateHabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<Habit> { $0.archivedAt == nil })
    private var activeHabits: [Habit]

    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    @State private var selectedCategory: HabitCategory = .productivity
    @State private var selectedType: HabitType = .boolean
    @State private var selectedFrequency: HabitFrequency = .daily
    @State private var targetCount = 1
    @State private var targetMinutes = 5
    @State private var reminderEnabled = false
    @State private var reminderTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var whyMotivation = ""
    @State private var showIconPicker = false
    @State private var creationMode: CreationMode = .manual
    @State private var showPaywall = false

    private var canCreateMore: Bool {
        PremiumManager.shared.canCreateHabit(currentCount: activeHabits.count)
    }

    private enum CreationMode: String, CaseIterable {
        case manual = "Вручную"
        case library = "Из библиотеки"
    }

    private let iconOptions = [
        "star.fill", "heart.fill", "flame.fill", "bolt.fill",
        "brain.fill", "book.fill", "figure.run", "drop.fill",
        "moon.fill", "sun.max.fill", "leaf.fill", "cup.and.saucer.fill",
        "pencil.line", "music.note", "camera.fill", "paintbrush.fill",
        "figure.yoga", "figure.walk", "dumbbell.fill", "pills.fill",
        "banknote.fill", "phone.fill", "envelope.fill", "timer",
        "bed.double.fill", "fork.knife", "shower.fill", "lungs.fill",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SergiTheme.Spacing.lg) {
                    // Free limit banner
                    if !canCreateMore {
                        VStack(spacing: SergiTheme.Spacing.sm) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(SergiTheme.Colors.accent)
                            Text("Лимит \(AppConfig.Limits.maxFreeHabits) привычек достигнут")
                                .font(SergiTheme.Typography.h3)
                            Text("Оформи Premium для безлимитных привычек")
                                .font(SergiTheme.Typography.caption)
                                .foregroundStyle(SergiTheme.Colors.textSecondary)
                            Button("Перейти к Premium") { showPaywall = true }
                                .buttonStyle(.sergiPrimary)
                                .frame(maxWidth: 200)
                        }
                        .padding(SergiTheme.Spacing.lg)
                        .frame(maxWidth: .infinity)
                        .sergiCard()
                        .padding(.horizontal, SergiTheme.Spacing.md)
                    }

                    // Mode picker
                    Picker("", selection: $creationMode) {
                        ForEach(CreationMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, SergiTheme.Spacing.md)
                    .disabled(!canCreateMore)
                    .opacity(canCreateMore ? 1 : 0.5)

                    if creationMode == .manual {
                        manualCreationForm
                    } else {
                        libraryPicker
                    }
                }
                .padding(.vertical, SergiTheme.Spacing.md)
            }
            .background(SergiTheme.Colors.backgroundLight)
            .navigationTitle("Новая привычка")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Создать") { createHabit() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || !canCreateMore)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Manual Form

    private var manualCreationForm: some View {
        VStack(spacing: SergiTheme.Spacing.lg) {
            // Name + Icon
            VStack(spacing: SergiTheme.Spacing.md) {
                HStack(spacing: SergiTheme.Spacing.md) {
                    Button {
                        showIconPicker.toggle()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(selectedCategory.color.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Image(systemName: selectedIcon)
                                .font(.system(size: 24))
                                .foregroundStyle(selectedCategory.color)
                        }
                    }

                    TextField("Название привычки", text: $name)
                        .font(SergiTheme.Typography.h3)
                        .padding(SergiTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                .fill(SergiTheme.Colors.surfaceLight)
                        )
                }

                if showIconPicker {
                    iconPickerGrid
                }
            }
            .padding(.horizontal, SergiTheme.Spacing.md)

            // Category
            sectionCard(title: "Категория") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SergiTheme.Spacing.sm) {
                        ForEach(HabitCategory.allCases) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, SergiTheme.Spacing.md)
                }
            }

            // Type
            sectionCard(title: "Тип отслеживания") {
                HStack(spacing: SergiTheme.Spacing.sm) {
                    ForEach(HabitType.allCases) { type in
                        Button {
                            selectedType = type
                        } label: {
                            VStack(spacing: SergiTheme.Spacing.xs) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 22))
                                Text(type.displayName)
                                    .font(SergiTheme.Typography.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(SergiTheme.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: SergiTheme.Radius.small)
                                    .fill(selectedType == type
                                          ? SergiTheme.Colors.primary.opacity(0.15)
                                          : Color.clear)
                            )
                            .foregroundStyle(selectedType == type
                                             ? SergiTheme.Colors.primary
                                             : SergiTheme.Colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, SergiTheme.Spacing.md)
            }

            // Target (counter/timer)
            if selectedType == .counter {
                sectionCard(title: "Цель (количество)") {
                    Stepper("\(targetCount)", value: $targetCount, in: 1...100)
                        .font(SergiTheme.Typography.h3)
                        .padding(.horizontal, SergiTheme.Spacing.md)
                }
            }

            if selectedType == .timer {
                sectionCard(title: "Цель (минуты)") {
                    Stepper("\(targetMinutes) мин", value: $targetMinutes, in: 1...120, step: 5)
                        .font(SergiTheme.Typography.h3)
                        .padding(.horizontal, SergiTheme.Spacing.md)
                }
            }

            // Frequency
            sectionCard(title: "Частота") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: SergiTheme.Spacing.sm) {
                    ForEach(HabitFrequency.allCases) { freq in
                        Button {
                            selectedFrequency = freq
                        } label: {
                            Text(freq.displayName)
                                .font(SergiTheme.Typography.body)
                                .frame(maxWidth: .infinity)
                                .padding(SergiTheme.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: SergiTheme.Radius.small)
                                        .fill(selectedFrequency == freq
                                              ? SergiTheme.Colors.primary.opacity(0.15)
                                              : SergiTheme.Colors.surfaceLight)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: SergiTheme.Radius.small)
                                        .strokeBorder(selectedFrequency == freq
                                                      ? SergiTheme.Colors.primary
                                                      : Color.clear, lineWidth: 1.5)
                                )
                                .foregroundStyle(selectedFrequency == freq
                                                 ? SergiTheme.Colors.primary
                                                 : SergiTheme.Colors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, SergiTheme.Spacing.md)
            }

            // Reminder
            sectionCard(title: "Напоминание") {
                VStack(spacing: SergiTheme.Spacing.sm) {
                    Toggle("Включить напоминание", isOn: $reminderEnabled)
                        .padding(.horizontal, SergiTheme.Spacing.md)

                    if reminderEnabled {
                        DatePicker("Время", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .padding(.horizontal, SergiTheme.Spacing.md)
                    }
                }
            }

            // Why (optional)
            sectionCard(title: "Почему это важно? (необязательно)") {
                TextField("Помогает не забыть зачем ты это делаешь", text: $whyMotivation, axis: .vertical)
                    .font(SergiTheme.Typography.body)
                    .lineLimit(2...4)
                    .padding(.horizontal, SergiTheme.Spacing.md)
            }
        }
    }

    // MARK: - Icon Picker Grid

    private var iconPickerGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: SergiTheme.Spacing.sm) {
            ForEach(iconOptions, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                    showIconPicker = false
                } label: {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(selectedIcon == icon
                                      ? selectedCategory.color.opacity(0.2)
                                      : Color.clear)
                        )
                        .foregroundStyle(selectedIcon == icon
                                         ? selectedCategory.color
                                         : SergiTheme.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(SergiTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                .fill(SergiTheme.Colors.surfaceLight)
        )
    }

    // MARK: - Library Picker

    private var libraryPicker: some View {
        VStack(spacing: SergiTheme.Spacing.md) {
            ForEach(HabitCategory.allCases) { category in
                let templates = HabitLibrary.byCategory(category)
                if !templates.isEmpty {
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        HStack(spacing: SergiTheme.Spacing.sm) {
                            Image(systemName: category.icon)
                                .foregroundStyle(category.color)
                            Text(category.displayName)
                                .font(SergiTheme.Typography.h3)
                        }
                        .padding(.horizontal, SergiTheme.Spacing.md)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: SergiTheme.Spacing.sm) {
                                ForEach(templates) { template in
                                    Button {
                                        applyTemplate(template)
                                    } label: {
                                        VStack(spacing: SergiTheme.Spacing.xs) {
                                            Image(systemName: template.icon)
                                                .font(.system(size: 24))
                                                .foregroundStyle(category.color)
                                            Text(template.name)
                                                .font(SergiTheme.Typography.caption)
                                                .foregroundStyle(SergiTheme.Colors.textPrimary)
                                                .lineLimit(2)
                                                .multilineTextAlignment(.center)
                                        }
                                        .frame(width: 90, height: 80)
                                        .padding(SergiTheme.Spacing.sm)
                                        .background(
                                            RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                                .fill(SergiTheme.Colors.surfaceLight)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, SergiTheme.Spacing.md)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section Card Helper

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
            Text(title)
                .font(SergiTheme.Typography.caption)
                .foregroundStyle(SergiTheme.Colors.textSecondary)
                .textCase(.uppercase)
                .padding(.horizontal, SergiTheme.Spacing.md)

            content()
        }
    }

    // MARK: - Actions

    private func applyTemplate(_ template: HabitTemplate) {
        name = template.name
        selectedIcon = template.icon
        selectedCategory = template.category
        selectedType = template.type
        selectedFrequency = template.frequency
        targetCount = template.defaultCount
        targetMinutes = Int(template.defaultDuration / 60)
        whyMotivation = template.scientificReason
        creationMode = .manual
    }

    private func createHabit() {
        let habitService = HabitService(modelContext: modelContext)
        let habit = habitService.createHabit(
            name: name,
            icon: selectedIcon,
            category: selectedCategory,
            type: selectedType,
            frequency: selectedFrequency,
            targetCount: selectedType == .counter ? targetCount : 1,
            targetDuration: selectedType == .timer ? TimeInterval(targetMinutes * 60) : 0,
            reminderTime: reminderEnabled ? reminderTime : nil
        )
        habit.whyMotivation = whyMotivation.isEmpty ? nil : whyMotivation

        if reminderEnabled {
            NotificationService.shared.scheduleHabitReminder(for: habit)
        }

        dismiss()
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let category: HabitCategory
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: SergiTheme.Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                Text(category.displayName)
                    .font(SergiTheme.Typography.caption)
            }
            .padding(.horizontal, SergiTheme.Spacing.md)
            .padding(.vertical, SergiTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected
                          ? category.color.opacity(0.2)
                          : SergiTheme.Colors.surfaceLight)
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? category.color : Color.clear, lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? category.color : SergiTheme.Colors.textSecondary)
        }
        .buttonStyle(.plain)
    }
}
