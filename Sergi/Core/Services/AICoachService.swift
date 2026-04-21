import Foundation
import SwiftData

// MARK: - AI Coach Service

@Observable
final class AICoachService {
    private let modelContext: ModelContext

    private(set) var isGenerating = false
    private(set) var chatHistory: [AIChatMessage] = []

    // OpenAI API configuration — key stored in Keychain
    private var apiKey: String { KeychainManager.resolvedOpenAIKey }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadChatHistory()
    }

    // MARK: - Chat

    func sendMessage(_ text: String) async -> String {
        let userMessage = AIChatMessage(role: .user, content: text)
        modelContext.insert(userMessage)
        chatHistory.append(userMessage)
        try? modelContext.save()

        isGenerating = true
        defer { isGenerating = false }

        let response = await generateResponse(for: text)

        let aiMessage = AIChatMessage(role: .assistant, content: response)
        modelContext.insert(aiMessage)
        chatHistory.append(aiMessage)
        try? modelContext.save()

        return response
    }

    // MARK: - Habit Plan Generation

    func generateHabitPlan(
        goal: String,
        availableMinutes: Int,
        currentLevel: String?,
        timeframe: String?
    ) async -> [HabitSuggestion] {
        isGenerating = true
        defer { isGenerating = false }

        let prompt = """
        Пользователь хочет: \(goal)
        Доступное время: \(availableMinutes) минут в день
        Текущий уровень: \(currentLevel ?? "начинающий")
        Срок: \(timeframe ?? "не указан")

        Создай оптимальный план из 3-5 ключевых привычек в формате JSON.
        Для каждой привычки:
        - name: короткое actionable название (на русском)
        - icon: SF Symbol name
        - category: одна из [health, fitness, learning, productivity, mindfulness, nutrition, sleep]
        - frequency: daily / weekdays / 3x_week / 5x_week
        - duration_minutes: начальная продолжительность
        - reason: обоснование 1-2 предложения (на русском)

        Фокус на атомных привычках (минимальные действия).
        Ответь ТОЛЬКО JSON массивом, без дополнительного текста.
        """

        let responseText = await callOpenAI(prompt: prompt, systemPrompt: systemPromptForCoach)

        return parseHabitSuggestions(from: responseText)
    }

    // MARK: - Motivational Message

    func generateMotivation(
        habitName: String,
        streakDays: Int,
        recentSkips: Int
    ) async -> String {
        let prompt = """
        Привычка: \(habitName)
        Текущий streak: \(streakDays) дней
        Пропуски за неделю: \(recentSkips)

        Создай короткое (макс 2 предложения) мотивационное сообщение на русском.
        Тон: дружелюбный, поддерживающий, не назидательный.
        Если streak высокий — хвали. Если были пропуски — мягко мотивируй вернуться.
        Ответь только текстом сообщения.
        """

        return await callOpenAI(prompt: prompt, systemPrompt: systemPromptForCoach)
    }

    // MARK: - Daily Insight

    func generateDailyInsight(completionRates: [String: Double]) async -> String {
        var ratesDescription = ""
        for (habit, rate) in completionRates {
            ratesDescription += "\(habit): \(Int(rate * 100))%\n"
        }

        let prompt = """
        Статистика привычек пользователя за последние 7 дней:
        \(ratesDescription)

        Дай один короткий полезный инсайт на русском (1-2 предложения).
        Примеры: "Ты лучше справляешься утром", "Твоя продуктивность растёт".
        """

        return await callOpenAI(prompt: prompt, systemPrompt: systemPromptForCoach)
    }

    // MARK: - Reflection Question

    func generateReflectionQuestion() async -> String {
        let prompts = [
            "Что сегодня принесло тебе больше всего удовольствия?",
            "Какой момент дня был самым продуктивным?",
            "За что ты благодарен сегодня?",
            "Что ты хотел бы сделать иначе завтра?",
            "Какая маленькая победа случилась сегодня?",
            "Что нового ты узнал о себе?",
            "Какой привычке ты рад больше всего?",
        ]
        // Offline fallback — returns a random question
        return prompts.randomElement() ?? prompts[0]
    }

    // MARK: - Risk Prediction

    func predictDropoffRisk(for habit: Habit) -> Double {
        let streak = habit.currentStreak
        let rate = habit.completionRate
        let daysSinceCreation = Calendar.current.dateComponents(
            [.day], from: habit.createdAt, to: Date()
        ).day ?? 0

        // Simple heuristic model (to be replaced with CoreML)
        var risk = 0.5

        // Lower streak = higher risk
        if streak == 0 { risk += 0.3 }
        else if streak < 7 { risk += 0.1 }
        else if streak > 21 { risk -= 0.2 }

        // Low completion rate = higher risk
        if rate < 0.3 { risk += 0.2 }
        else if rate > 0.7 { risk -= 0.15 }

        // Critical period: days 8-14
        if daysSinceCreation > 7 && daysSinceCreation < 15 { risk += 0.1 }

        return min(1.0, max(0, risk))
    }

    // MARK: - Private

    private let systemPromptForCoach = """
    Ты — Sergi, персональный AI-коуч по привычкам. Ты дружелюбный, поддерживающий \
    и научно обоснованный. Ты используешь принципы из "Atomic Habits" Джеймса Клира. \
    Ты всегда отвечаешь на русском языке. Ты не читаешь мораль — ты мотивируешь через \
    понимание и поддержку. Ты фокусируешься на минимальных действиях и постепенном прогрессе.
    """

    private func callOpenAI(prompt: String, systemPrompt: String) async -> String {
        guard !apiKey.isEmpty else {
            return offlineFallback(for: prompt)
        }

        // Check network before making request
        guard NetworkMonitor.shared.isConnected else {
            return offlineFallback(for: prompt)
        }

        let apiBaseURL = AppConfig.API.openAIBaseURL + "/chat/completions"
        guard let url = URL(string: apiBaseURL) else { return offlineFallback(for: prompt) }

        let body: [String: Any] = [
            "model": AppConfig.API.openAIModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 500
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = AppConfig.API.requestTimeout
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return offlineFallback(for: prompt)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            // Fallback to offline
        }

        return offlineFallback(for: prompt)
    }

    private func offlineFallback(for prompt: String) -> String {
        // Basic offline responses
        if prompt.contains("мотивационное") || prompt.contains("мотивируй") {
            let messages = [
                "Каждый маленький шаг приближает тебя к цели. Продолжай! 💪",
                "Ты уже проделал большой путь. Сегодня — ещё один шаг вперёд.",
                "Помни, почему ты начал. Ты справишься!",
                "Прогресс важнее совершенства. Просто сделай сегодня хоть что-то.",
            ]
            return messages.randomElement() ?? messages[0]
        }

        if prompt.contains("инсайт") || prompt.contains("статистика") {
            return "Продолжай в том же темпе! Регулярность — ключ к успеху."
        }

        return "Я здесь, чтобы помочь тебе с привычками. Расскажи, что тебя интересует?"
    }

    private func parseHabitSuggestions(from text: String) -> [HabitSuggestion] {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return defaultSuggestions()
        }

        return json.compactMap { item in
            guard let name = item["name"] as? String,
                  let icon = item["icon"] as? String,
                  let reason = item["reason"] as? String else { return nil }

            let categoryStr = item["category"] as? String ?? "productivity"
            let category = HabitCategory(rawValue: categoryStr) ?? .productivity
            let frequencyStr = item["frequency"] as? String ?? "daily"
            let frequency = HabitFrequency(rawValue: frequencyStr) ?? .daily
            let duration = item["duration_minutes"] as? Int ?? 5

            return HabitSuggestion(
                name: name,
                icon: icon,
                category: category,
                frequency: frequency,
                durationMinutes: duration,
                reason: reason
            )
        }
    }

    private func defaultSuggestions() -> [HabitSuggestion] {
        [
            HabitSuggestion(name: "Утренняя зарядка", icon: "figure.walk", category: .fitness, frequency: .daily, durationMinutes: 5, reason: "Активизирует тело и ум на весь день"),
            HabitSuggestion(name: "Чтение", icon: "book.fill", category: .learning, frequency: .daily, durationMinutes: 10, reason: "Развивает мышление и расширяет кругозор"),
            HabitSuggestion(name: "Медитация", icon: "brain.fill", category: .mindfulness, frequency: .daily, durationMinutes: 5, reason: "Снижает стресс и улучшает фокусировку"),
        ]
    }

    private func loadChatHistory() {
        let descriptor = FetchDescriptor<AIChatMessage>(
            sortBy: [SortDescriptor(\.timestamp)]
        )
        chatHistory = (try? modelContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Habit Suggestion DTO

struct HabitSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let category: HabitCategory
    let frequency: HabitFrequency
    let durationMinutes: Int
    let reason: String
}
