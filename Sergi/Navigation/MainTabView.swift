import SwiftUI

// MARK: - Main Tab View

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var showCreateHabit = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(AppTab.home)

                LibraryView()
                    .tag(AppTab.explore)

                // Placeholder for center button
                Color.clear
                    .tag(AppTab.create)

                ProgressDashboardView()
                    .tag(AppTab.progress)

                SettingsView()
                    .tag(AppTab.profile)
            }
            .toolbar(.hidden, for: .tabBar)

            // Custom tab bar
            customTabBar
        }
        .sheet(isPresented: $showCreateHabit) {
            CreateHabitView()
        }
    }

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabItem(.home, icon: "house.fill", label: "Главная")
            tabItem(.explore, icon: "magnifyingglass", label: "Обзор")

            // Center + button
            Button {
                showCreateHabit = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [SergiTheme.Colors.primary, SergiTheme.Colors.primary.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: SergiTheme.Colors.primary.opacity(0.35), radius: 10, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .offset(y: -16)
            }

            tabItem(.progress, icon: "chart.bar.fill", label: "Прогресс")
            tabItem(.profile, icon: "person.fill", label: "Профиль")
        }
        .padding(.horizontal, SergiTheme.Spacing.sm)
        .padding(.top, SergiTheme.Spacing.sm)
        .padding(.bottom, SergiTheme.Spacing.xs)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 12, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabItem(_ tab: AppTab, icon: String, label: String) -> some View {
        Button {
            withAnimation(SergiTheme.Animation.microInteraction) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .symbolVariant(selectedTab == tab ? .fill : .none)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(selectedTab == tab ? SergiTheme.Colors.primary : SergiTheme.Colors.textTertiary)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - App Tab

enum AppTab: Int, CaseIterable {
    case home
    case explore
    case create
    case progress
    case profile
}
