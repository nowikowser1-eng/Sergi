import SwiftUI
import SwiftData

@main
struct SergiApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            Habit.self,
            HabitEntry.self,
            Goal.self,
            JournalEntry.self,
            UserProfile.self,
            Badge.self,
            AIChatMessage.self
        ])
    }
}

// MARK: - Root View

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var showOnboarding = true
    @State private var isCheckingProfile = true

    private var errorHandler = ErrorHandler.shared
    private var networkMonitor = NetworkMonitor.shared

    var body: some View {
        Group {
            if isCheckingProfile {
                launchScreen
            } else if showOnboarding {
                OnboardingView {
                    withAnimation(SergiTheme.Animation.standard) {
                        showOnboarding = false
                    }
                }
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            if !networkMonitor.isConnected {
                HStack(spacing: SergiTheme.Spacing.sm) {
                    Image(systemName: "wifi.slash")
                    Text("Нет подключения к интернету")
                        .font(SergiTheme.Typography.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, SergiTheme.Spacing.md)
                .padding(.vertical, SergiTheme.Spacing.sm)
                .background(SergiTheme.Colors.error.opacity(0.9))
                .clipShape(Capsule())
                .padding(.top, SergiTheme.Spacing.xs)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(SergiTheme.Animation.standard, value: networkMonitor.isConnected)
            }
        }
        .alert("Ошибка", isPresented: Binding(
            get: { errorHandler.showError },
            set: { if !$0 { errorHandler.dismiss() } }
        )) {
            Button("OK") { errorHandler.dismiss() }
        } message: {
            if let error = errorHandler.currentError {
                Text(error.localizedDescription)
            }
        }
        .onAppear {
            checkProfile()
        }
        .task {
            // Sync StoreKit entitlements → UserProfile on launch
            await StoreService.shared.updatePurchasedProducts()
            await PremiumManager.shared.syncWithProfile(modelContext: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: .premiumStatusChanged)) { _ in
            Task { @MainActor in
                PremiumManager.shared.syncWithProfile(modelContext: modelContext)
            }
        }
    }

    private var launchScreen: some View {
        ZStack {
            SergiTheme.Colors.backgroundLight
                .ignoresSafeArea()

            VStack(spacing: SergiTheme.Spacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SergiTheme.Colors.primary, SergiTheme.Colors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Sergi")
                    .font(SergiTheme.Typography.h1)
                    .foregroundStyle(SergiTheme.Colors.textPrimary)
            }
        }
    }

    private func checkProfile() {
        if let profile = profiles.first, profile.onboardingCompleted {
            showOnboarding = false
        } else {
            showOnboarding = true
        }
        withAnimation {
            isCheckingProfile = false
        }
    }
}
