import SwiftUI
import SwiftData

// MARK: - Settings / Profile View

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showPaywall = false
    @State private var showAICoach = false
    @State private var showJournal = false
    @State private var showExportSheet = false
    @State private var exportURLs: [URL] = []
    @State private var healthKitEnabled = false
    @State private var showGoals = false

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                SergiTheme.Colors.backgroundLight
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SergiTheme.Spacing.lg) {
                        // Profile card
                        profileCard

                        // Premium card
                        if !(profile?.isPremium ?? false) {
                            premiumCard
                        }

                        // Quick links
                        settingsSection(title: "Основное") {
                            settingsRow(icon: "target", title: "Цели", color: SergiTheme.Colors.accent) {
                                showGoals = true
                            }
                            settingsRow(icon: "brain.fill", title: "AI-Коуч", color: SergiTheme.Colors.primary) {
                                showAICoach = true
                            }
                            settingsRow(icon: "book.closed.fill", title: "Журнал рефлексии", color: SergiTheme.Colors.categoryLearning) {
                                showJournal = true
                            }
                        }

                        // Notifications
                        settingsSection(title: "Уведомления") {
                            if let profile {
                                Picker("Стиль", selection: Binding(
                                    get: { profile.preferredNotificationStyle },
                                    set: { profile.preferredNotificationStyle = $0; try? modelContext.save() }
                                )) {
                                    ForEach(NotificationStyle.allCases, id: \.self) { style in
                                        Text(style.displayName).tag(style)
                                    }
                                }
                                .padding(.horizontal, SergiTheme.Spacing.md)

                                Toggle("Тихие дни (AI определяет)", isOn: Binding(
                                    get: { profile.quietDaysEnabled },
                                    set: { profile.quietDaysEnabled = $0; try? modelContext.save() }
                                ))
                                .padding(.horizontal, SergiTheme.Spacing.md)
                            }
                        }

                        // Appearance
                        settingsSection(title: "Оформление") {
                            if let profile {
                                Picker("Тема", selection: Binding(
                                    get: { profile.darkModePreference },
                                    set: { profile.darkModePreference = $0; try? modelContext.save() }
                                )) {
                                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                                        Text(mode.displayName).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .padding(.horizontal, SergiTheme.Spacing.md)
                            }
                        }

                        // Health
                        if HealthKitService.shared.isAvailable {
                            settingsSection(title: "Здоровье") {
                                Toggle("Интеграция с Apple Health", isOn: $healthKitEnabled)
                                    .padding(.horizontal, SergiTheme.Spacing.md)
                                    .onChange(of: healthKitEnabled) { _, enabled in
                                        if enabled {
                                            Task {
                                                let granted = await HealthKitService.shared.requestAuthorization()
                                                if !granted { healthKitEnabled = false }
                                            }
                                        }
                                    }

                                if healthKitEnabled {
                                    VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                                        Text("Шаги, минуты активности и сон будут отображаться на главном экране и в аналитике")
                                            .font(SergiTheme.Typography.caption)
                                            .foregroundStyle(SergiTheme.Colors.textSecondary)
                                    }
                                    .padding(.horizontal, SergiTheme.Spacing.md)
                                }
                            }
                        }

                        // Data
                        settingsSection(title: "Данные") {
                            if PremiumManager.shared.canExportData {
                                settingsRow(icon: "arrow.down.doc.fill", title: "Экспорт данных", color: SergiTheme.Colors.info) {
                                    exportData()
                                }
                            } else {
                                HStack {
                                    Image(systemName: "arrow.down.doc.fill")
                                        .foregroundStyle(SergiTheme.Colors.info.opacity(0.5))
                                        .frame(width: 32, height: 32)
                                    Text("Экспорт данных")
                                        .font(SergiTheme.Typography.body)
                                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(SergiTheme.Colors.textSecondary)
                                }
                                .padding(.horizontal, SergiTheme.Spacing.md)
                                .contentShape(Rectangle())
                                .onTapGesture { showPaywall = true }
                            }
                            settingsRow(icon: "arrow.clockwise", title: "Восстановить покупки", color: SergiTheme.Colors.textSecondary) {
                                Task { await StoreService.shared.restorePurchases() }
                            }
                        }

                        // About
                        settingsSection(title: "О приложении") {
                            HStack {
                                Text("Версия")
                                    .font(SergiTheme.Typography.body)
                                Spacer()
                                Text(AppConfig.fullVersion)
                                    .font(SergiTheme.Typography.body)
                                    .foregroundStyle(SergiTheme.Colors.textSecondary)
                            }
                            .padding(.horizontal, SergiTheme.Spacing.md)
                        }
                    }
                    .padding(SergiTheme.Spacing.md)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Профиль")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showAICoach) {
                AICoachView()
            }
            .sheet(isPresented: $showJournal) {
                JournalView()
            }
            .sheet(isPresented: $showExportSheet) {
                if !exportURLs.isEmpty {
                    ShareSheet(items: exportURLs)
                }
            }
            .sheet(isPresented: $showGoals) {
                GoalsView()
            }
        }
    }

    // MARK: - Export

    private func exportData() {
        let exportService = ExportService(modelContext: modelContext)
        var urls: [URL] = []
        if let habitsURL = exportService.exportHabitsCSV() { urls.append(habitsURL) }
        if let entriesURL = exportService.exportEntriesCSV() { urls.append(entriesURL) }
        if let journalURL = exportService.exportJournalCSV() { urls.append(journalURL) }
        if !urls.isEmpty {
            exportURLs = urls
            showExportSheet = true
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        VStack(spacing: SergiTheme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SergiTheme.Colors.primary, SergiTheme.Colors.primaryLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Text(profile?.avatarEmoji ?? "🌟")
                    .font(.system(size: 36))
            }

            VStack(spacing: SergiTheme.Spacing.xs) {
                Text(profile?.displayName ?? "Друг")
                    .font(SergiTheme.Typography.h2)

                Text(profile?.currentLevelTitle ?? "Новичок")
                    .font(SergiTheme.Typography.body)
                    .foregroundStyle(SergiTheme.Colors.primary)

                if let profile {
                    XPProgressBar(
                        currentXP: profile.totalXP % profile.xpForNextLevel,
                        requiredXP: profile.xpForNextLevel,
                        level: profile.level
                    )
                    .padding(.horizontal, SergiTheme.Spacing.xl)
                }
            }
        }
        .padding(SergiTheme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .sergiCard()
    }

    // MARK: - Premium Card

    private var premiumCard: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: SergiTheme.Spacing.xs) {
                    Text("Sergi Premium ✨")
                        .font(SergiTheme.Typography.h3)
                        .foregroundStyle(.white)

                    Text("AI-коуч, безлимит привычек, аналитика")
                        .font(SergiTheme.Typography.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(SergiTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SergiTheme.Radius.medium)
                    .fill(
                        LinearGradient(
                            colors: [SergiTheme.Colors.primary, SergiTheme.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: SergiTheme.Spacing.sm) {
            Text(title)
                .font(SergiTheme.Typography.caption)
                .foregroundStyle(SergiTheme.Colors.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: SergiTheme.Spacing.sm) {
                content()
            }
            .padding(.vertical, SergiTheme.Spacing.sm)
            .sergiCard()
        }
    }

    private func settingsRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: SergiTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(title)
                    .font(SergiTheme.Typography.body)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(SergiTheme.Colors.textTertiary)
            }
            .padding(.horizontal, SergiTheme.Spacing.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Share Sheet (UIActivityViewController)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
