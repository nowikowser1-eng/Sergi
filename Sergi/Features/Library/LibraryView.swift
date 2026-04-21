import SwiftUI
import SwiftData

// MARK: - Library View (Explore)

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedCategory: HabitCategory?
    @State private var showDetail: HabitTemplate?
    @State private var addedTemplateIDs: Set<UUID> = []

    private var filteredTemplates: [HabitTemplate] {
        var results = HabitLibrary.allTemplates

        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            results = HabitLibrary.search(query: searchText)
        }

        return results.sorted { $0.popularityScore > $1.popularityScore }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SergiTheme.Colors.backgroundLight
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SergiTheme.Spacing.lg) {
                        // Search
                        HStack(spacing: SergiTheme.Spacing.sm) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(SergiTheme.Colors.textTertiary)
                            TextField("Поиск привычек...", text: $searchText)
                                .font(SergiTheme.Typography.body)
                        }
                        .padding(SergiTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                                .fill(SergiTheme.Colors.surfaceLight)
                        )
                        .padding(.horizontal, SergiTheme.Spacing.md)

                        // Category filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: SergiTheme.Spacing.sm) {
                                Button {
                                    selectedCategory = nil
                                } label: {
                                    Text("Все")
                                        .font(SergiTheme.Typography.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, SergiTheme.Spacing.md)
                                        .padding(.vertical, SergiTheme.Spacing.sm)
                                        .background(
                                            Capsule()
                                                .fill(selectedCategory == nil
                                                      ? SergiTheme.Colors.primary.opacity(0.2)
                                                      : SergiTheme.Colors.surfaceLight)
                                        )
                                        .foregroundStyle(selectedCategory == nil
                                                         ? SergiTheme.Colors.primary
                                                         : SergiTheme.Colors.textSecondary)
                                }
                                .buttonStyle(.plain)

                                ForEach(HabitCategory.allCases) { category in
                                    Button {
                                        selectedCategory = selectedCategory == category ? nil : category
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: category.icon)
                                                .font(.system(size: 12))
                                            Text(category.displayName)
                                                .font(SergiTheme.Typography.caption)
                                        }
                                        .padding(.horizontal, SergiTheme.Spacing.md)
                                        .padding(.vertical, SergiTheme.Spacing.sm)
                                        .background(
                                            Capsule()
                                                .fill(selectedCategory == category
                                                      ? category.color.opacity(0.2)
                                                      : SergiTheme.Colors.surfaceLight)
                                        )
                                        .foregroundStyle(selectedCategory == category
                                                         ? category.color
                                                         : SergiTheme.Colors.textSecondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, SergiTheme.Spacing.md)
                        }

                        // Template cards
                        LazyVStack(spacing: SergiTheme.Spacing.sm) {
                            ForEach(filteredTemplates) { template in
                                TemplateCard(
                                    template: template,
                                    isAdded: addedTemplateIDs.contains(template.id),
                                    onAdd: { addFromTemplate(template) },
                                    onTap: { showDetail = template }
                                )
                            }
                        }
                        .padding(.horizontal, SergiTheme.Spacing.md)
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Библиотека")
            .sheet(item: $showDetail) { template in
                TemplateDetailSheet(template: template, onAdd: { addFromTemplate(template) })
            }
        }
    }

    private func addFromTemplate(_ template: HabitTemplate) {
        let habitService = HabitService(modelContext: modelContext)
        let habit = habitService.createHabit(
            name: template.name,
            icon: template.icon,
            category: template.category,
            type: template.type,
            frequency: template.frequency,
            targetCount: template.defaultCount,
            targetDuration: template.defaultDuration
        )
        habit.whyMotivation = template.scientificReason
        addedTemplateIDs.insert(template.id)
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: HabitTemplate
    let isAdded: Bool
    let onAdd: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: SergiTheme.Spacing.md) {
                Image(systemName: template.icon)
                    .font(.system(size: 24))
                    .foregroundStyle(template.category.color)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(template.category.color.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                    Text(template.name)
                        .font(SergiTheme.Typography.h3)
                        .foregroundStyle(SergiTheme.Colors.textPrimary)

                    Text(template.scientificReason)
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: SergiTheme.Spacing.sm) {
                        Label(template.frequency.shortName, systemImage: "calendar")
                        if template.difficulty > 0 {
                            HStack(spacing: 1) {
                                ForEach(0..<template.difficulty, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 8))
                                }
                            }
                        }
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(SergiTheme.Colors.textTertiary)
                }

                Spacer()

                Button {
                    onAdd()
                } label: {
                    Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(isAdded ? SergiTheme.Colors.success : SergiTheme.Colors.primary)
                }
                .buttonStyle(.plain)
                .disabled(isAdded)
            }
            .padding(SergiTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                    .fill(SergiTheme.Colors.surfaceLight)
            )
            .sergiShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Detail Sheet

private struct TemplateDetailSheet: View {
    let template: HabitTemplate
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: SergiTheme.Spacing.lg) {
                    // Header
                    ZStack {
                        Circle()
                            .fill(template.category.color.opacity(0.15))
                            .frame(width: 90, height: 90)
                        Image(systemName: template.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(template.category.color)
                    }

                    Text(template.name)
                        .font(SergiTheme.Typography.h1)

                    // Details
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.md) {
                        detailRow(icon: "calendar", title: "Частота", value: template.frequency.displayName)
                        detailRow(icon: "tag.fill", title: "Категория", value: template.category.displayName)

                        if template.defaultDuration > 0 {
                            detailRow(icon: "timer", title: "Длительность", value: "\(Int(template.defaultDuration / 60)) мин")
                        }

                        if template.defaultCount > 1 {
                            detailRow(icon: "number", title: "Цель", value: "\(template.defaultCount)")
                        }
                    }
                    .padding(SergiTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .sergiCard()

                    // Science
                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                        Label("Зачем это работает", systemImage: "brain.fill")
                            .font(SergiTheme.Typography.h3)
                            .foregroundStyle(SergiTheme.Colors.primary)

                        Text(template.scientificReason)
                            .font(SergiTheme.Typography.body)
                            .foregroundStyle(SergiTheme.Colors.textSecondary)
                    }
                    .padding(SergiTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .sergiCard()

                    // Tips
                    if !template.tips.isEmpty {
                        VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
                            Label("Советы", systemImage: "lightbulb.fill")
                                .font(SergiTheme.Typography.h3)
                                .foregroundStyle(SergiTheme.Colors.accent)

                            ForEach(template.tips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: SergiTheme.Spacing.sm) {
                                    Text("•")
                                    Text(tip)
                                }
                                .font(SergiTheme.Typography.body)
                                .foregroundStyle(SergiTheme.Colors.textSecondary)
                            }
                        }
                        .padding(SergiTheme.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .sergiCard()
                    }

                    // Add button
                    Button("Добавить привычку") {
                        onAdd()
                        dismiss()
                    }
                    .buttonStyle(.sergiPrimary)
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

    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(SergiTheme.Typography.body)
                .foregroundStyle(SergiTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(SergiTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(SergiTheme.Colors.textPrimary)
        }
    }
}
