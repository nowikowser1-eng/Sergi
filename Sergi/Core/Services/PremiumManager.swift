import Foundation
import SwiftData

// MARK: - Premium Manager

/// Single source of truth for premium status.
/// Syncs StoreKit entitlements with UserProfile model.
@Observable
final class PremiumManager {
    static let shared = PremiumManager()

    private init() {}

    // MARK: - Premium Check (Real-time)

    /// Checks premium status from StoreService entitlements (source of truth)
    var isPremium: Bool {
        StoreService.shared.isPremium
    }

    // MARK: - Feature Gating

    func canCreateHabit(currentCount: Int) -> Bool {
        isPremium || currentCount < AppConfig.Limits.maxFreeHabits
    }

    var canUseAICoach: Bool {
        isPremium
    }

    var canExportData: Bool {
        isPremium
    }

    var canViewAdvancedAnalytics: Bool {
        isPremium
    }

    var remainingFreeHabits: Int {
        max(0, AppConfig.Limits.maxFreeHabits)
    }

    // MARK: - Sync with UserProfile

    /// Call after purchase/restore to persist premium flag in SwiftData
    @MainActor
    func syncWithProfile(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let storeIsPremium = StoreService.shared.isPremium
        if profile.isPremium != storeIsPremium {
            profile.isPremium = storeIsPremium
            try? modelContext.save()
        }
    }
}
