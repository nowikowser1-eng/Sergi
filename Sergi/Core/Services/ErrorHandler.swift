import Foundation

// MARK: - App Error Handling

enum AppError: LocalizedError {
    case network(underlying: Error)
    case persistence(underlying: Error)
    case aiService(message: String)
    case healthKit(message: String)
    case storeKit(message: String)
    case export(message: String)
    case validation(message: String)
    case unknown(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .network:
            return "Проблема с подключением к интернету"
        case .persistence:
            return "Ошибка сохранения данных"
        case .aiService(let message):
            return "AI-коуч: \(message)"
        case .healthKit(let message):
            return "Apple Health: \(message)"
        case .storeKit(let message):
            return "Покупка: \(message)"
        case .export(let message):
            return "Экспорт: \(message)"
        case .validation(let message):
            return message
        case .unknown:
            return "Произошла непредвиденная ошибка"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .network:
            return "Проверьте подключение к интернету и попробуйте снова"
        case .persistence:
            return "Перезапустите приложение. Если проблема повторяется, обратитесь в поддержку"
        case .aiService:
            return "AI-коуч работает офлайн с ограниченным функционалом"
        case .healthKit:
            return "Проверьте разрешения в Настройках → Здоровье → Sergi"
        case .storeKit:
            return "Проверьте подключение и попробуйте снова"
        case .export:
            return "Попробуйте экспортировать позже"
        case .validation:
            return nil
        case .unknown:
            return "Попробуйте перезапустить приложение"
        }
    }
}

// MARK: - Error Handler (Global)

@Observable
final class ErrorHandler {
    static let shared = ErrorHandler()

    var currentError: AppError?
    var showError = false

    private init() {}

    @MainActor
    func handle(_ error: Error, context: String = "") {
        let appError: AppError
        if let existing = error as? AppError {
            appError = existing
        } else if (error as NSError).domain == NSURLErrorDomain {
            appError = .network(underlying: error)
        } else {
            appError = .unknown(underlying: error)
        }

        currentError = appError
        showError = true

        #if DEBUG
        print("⚠️ [\(context)] \(appError.localizedDescription): \(error)")
        #endif
    }

    @MainActor
    func dismiss() {
        showError = false
        currentError = nil
    }
}
