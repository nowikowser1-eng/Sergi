import Foundation

// MARK: - App Configuration

enum AppConfig {
    // MARK: - Environment

    enum Environment {
        case debug, testFlight, release

        static var current: Environment {
            #if DEBUG
            return .debug
            #else
            if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
                return .testFlight
            }
            return .release
            #endif
        }
    }

    static var environment: Environment { .current }
    static var isDebug: Bool { environment == .debug }

    // MARK: - API

    enum API {
        static var openAIBaseURL: String { "https://api.openai.com/v1" }
        static var openAIModel: String { "gpt-4o-mini" }
        static var requestTimeout: TimeInterval { 30 }
        static var maxRetries: Int { 3 }
    }

    // MARK: - StoreKit

    enum Store {
        static var monthlyProductID: String { SubscriptionPlan.monthly.rawValue }
        static var quarterlyProductID: String { SubscriptionPlan.quarterly.rawValue }
        static var annualProductID: String { SubscriptionPlan.annual.rawValue }

        static var allProductIDs: Set<String> {
            Set(SubscriptionPlan.allCases.map(\.rawValue))
        }
    }

    // MARK: - Gamification

    enum Gamification {
        static var baseXP: Int { 10 }
        static var streakBonusMultiplier: Double { 0.1 }
        static var maxStreakBonus: Double { 2.0 }
        static var perfectDayBonusXP: Int { 20 }
    }

    // MARK: - Notifications

    enum Notifications {
        static var eveningReflectionHour: Int { 21 }
        static var weeklyReviewDay: Int { 1 } // Monday
        static var weeklyReviewHour: Int { 10 }
    }

    // MARK: - Limits

    enum Limits {
        static var maxFreeHabits: Int { 5 }
        static var maxChatHistoryForContext: Int { 10 }
        static var exportDateFormatter: DateFormatter {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd_HH-mm"
            f.locale = Locale(identifier: "en_US_POSIX")
            return f
        }
    }

    // MARK: - Links

    enum Links {
        static var privacyPolicy: URL { URL(string: "https://sergi.app/privacy")! }
        static var termsOfUse: URL { URL(string: "https://sergi.app/terms")! }
        static var support: URL { URL(string: "mailto:support@sergi.app")! }
    }

    // MARK: - App Info

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var fullVersion: String {
        "\(appVersion) (\(buildNumber))"
    }
}
