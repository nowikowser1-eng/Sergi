import Foundation

// MARK: - Habit Library (200+ preset habits)

enum HabitLibrary {
    static let allTemplates: [HabitTemplate] = health + fitness + learning + productivity + mindfulness + nutrition + sleep + relationships + finance + creativity

    // MARK: - Health

    static let health: [HabitTemplate] = [
        HabitTemplate(name: "Пить воду", icon: "drop.fill", category: .health, type: .counter, suggestedTime: "morning", defaultCount: 8, scientificReason: "Достаточное количество воды улучшает метаболизм, когнитивные функции и состояние кожи.", tips: ["Держи бутылку воды на виду", "Пей стакан сразу после пробуждения"], difficulty: 1, popularityScore: 0.95),
        HabitTemplate(name: "Принять витамины", icon: "pill.fill", category: .health, type: .boolean, suggestedTime: "morning", scientificReason: "Регулярный приём витаминов восполняет дефициты, которые сложно покрыть только питанием.", tips: ["Поставь рядом с зубной щёткой"], difficulty: 1, popularityScore: 0.80),
        HabitTemplate(name: "Прогулка на свежем воздухе", icon: "figure.walk", category: .health, type: .timer, suggestedTime: "afternoon", defaultDuration: 1800, scientificReason: "30 минут ходьбы ежедневно снижают риск сердечно-сосудистых заболеваний на 30%.", tips: ["Выйди на одну остановку раньше"], difficulty: 1, popularityScore: 0.88),
        HabitTemplate(name: "Не есть после 20:00", icon: "fork.knife", category: .health, type: .boolean, suggestedTime: "evening", scientificReason: "Интервальное голодание улучшает метаболизм и качество сна.", difficulty: 2, popularityScore: 0.72),
        HabitTemplate(name: "Контрастный душ", icon: "shower.fill", category: .health, type: .boolean, suggestedTime: "morning", scientificReason: "Холодный душ активизирует иммунную систему и повышает уровень энергии.", difficulty: 3, popularityScore: 0.60),
        HabitTemplate(name: "Подняться пешком по лестнице", icon: "figure.stairs", category: .health, type: .boolean, suggestedTime: "morning", scientificReason: "Подъём по лестнице сжигает в 7 раз больше калорий, чем лифт.", difficulty: 1, popularityScore: 0.65),
        HabitTemplate(name: "Размять шею и плечи", icon: "figure.mixed.cardio", category: .health, type: .timer, suggestedTime: "afternoon", defaultDuration: 300, scientificReason: "Регулярные разминки предотвращают боли в спине при сидячей работе.", difficulty: 1, popularityScore: 0.70),
        HabitTemplate(name: "Проветрить комнату", icon: "wind", category: .health, type: .boolean, suggestedTime: "morning", scientificReason: "Свежий воздух повышает концентрацию CO₂ снижает на 15%.", difficulty: 1, popularityScore: 0.75),
    ]

    // MARK: - Fitness

    static let fitness: [HabitTemplate] = [
        HabitTemplate(name: "Утренняя зарядка", icon: "figure.cooldown", category: .fitness, type: .timer, suggestedTime: "morning", defaultDuration: 600, scientificReason: "Утренняя физическая активность улучшает настроение и продуктивность на весь день.", tips: ["Начни с 5 минут", "Включи музыку"], difficulty: 1, popularityScore: 0.92),
        HabitTemplate(name: "Отжимания", icon: "figure.strengthtraining.traditional", category: .fitness, type: .counter, suggestedTime: "morning", defaultCount: 10, scientificReason: "Отжимания задействуют более 6 групп мышц одновременно.", tips: ["Начни с 1 отжимания — это уже привычка"], difficulty: 2, popularityScore: 0.85),
        HabitTemplate(name: "Планка", icon: "figure.core.training", category: .fitness, type: .timer, suggestedTime: "morning", defaultDuration: 60, scientificReason: "Планка укрепляет весь корпус и улучшает осанку.", tips: ["Начни с 20 секунд"], difficulty: 2, popularityScore: 0.82),
        HabitTemplate(name: "Пробежка", icon: "figure.run", category: .fitness, type: .timer, frequency: .threePerWeek, suggestedTime: "morning", defaultDuration: 1800, scientificReason: "Бег улучшает сердечно-сосудистую систему и вырабатывает эндорфины.", tips: ["Начни с 10 минут бега/ходьбы"], difficulty: 3, popularityScore: 0.80),
        HabitTemplate(name: "Растяжка", icon: "figure.flexibility", category: .fitness, type: .timer, suggestedTime: "evening", defaultDuration: 600, scientificReason: "Растяжка снижает риск травм и улучшает восстановление мышц.", difficulty: 1, popularityScore: 0.78),
        HabitTemplate(name: "10 000 шагов", icon: "figure.walk", category: .fitness, type: .counter, suggestedTime: "afternoon", defaultCount: 10000, scientificReason: "10 000 шагов в день связаны с уменьшением риска хронических заболеваний.", difficulty: 2, popularityScore: 0.87),
        HabitTemplate(name: "Приседания", icon: "figure.strengthtraining.functional", category: .fitness, type: .counter, suggestedTime: "morning", defaultCount: 20, scientificReason: "Приседания — лучшее базовое упражнение для нижней части тела.", difficulty: 2, popularityScore: 0.75),
        HabitTemplate(name: "Йога", icon: "figure.yoga", category: .fitness, type: .timer, frequency: .threePerWeek, suggestedTime: "morning", defaultDuration: 1200, scientificReason: "Йога улучшает гибкость, силу и ментальное здоровье.", difficulty: 2, popularityScore: 0.76),
    ]

    // MARK: - Learning

    static let learning: [HabitTemplate] = [
        HabitTemplate(name: "Чтение книги", icon: "book.fill", category: .learning, type: .timer, suggestedTime: "evening", defaultDuration: 1200, scientificReason: "Регулярное чтение развивает критическое мышление и эмпатию.", tips: ["Начни с 1 страницы в день", "Читай перед сном вместо телефона"], difficulty: 1, popularityScore: 0.93),
        HabitTemplate(name: "Изучение языка", icon: "character.book.closed.fill", category: .learning, type: .timer, suggestedTime: "morning", defaultDuration: 900, scientificReason: "Ежедневная 15-минутная практика эффективнее, чем редкие длинные сессии.", tips: ["Используй Duolingo или Anki"], difficulty: 2, popularityScore: 0.85),
        HabitTemplate(name: "Учить новые слова", icon: "text.book.closed.fill", category: .learning, type: .counter, suggestedTime: "morning", defaultCount: 5, scientificReason: "5 новых слов в день = 1825 слов в год.", difficulty: 1, popularityScore: 0.78),
        HabitTemplate(name: "Онлайн-курс", icon: "play.rectangle.fill", category: .learning, type: .timer, frequency: .weekdays, suggestedTime: "evening", defaultDuration: 1800, scientificReason: "Непрерывное обучение повышает конкурентоспособность и нейропластичность.", difficulty: 2, popularityScore: 0.72),
        HabitTemplate(name: "Практика программирования", icon: "chevron.left.forwardslash.chevron.right", category: .learning, type: .timer, suggestedTime: "morning", defaultDuration: 1800, scientificReason: "Ежедневная практика — самый эффективный способ изучения программирования.", tips: ["Решай 1 задачу на LeetCode"], difficulty: 3, popularityScore: 0.68),
        HabitTemplate(name: "Подкаст / Аудиокнига", icon: "headphones", category: .learning, type: .timer, suggestedTime: "afternoon", defaultDuration: 1200, scientificReason: "Аудио-обучение позволяет учиться во время рутинных дел.", difficulty: 1, popularityScore: 0.82),
        HabitTemplate(name: "Записать конспект", icon: "pencil.line", category: .learning, type: .boolean, suggestedTime: "evening", scientificReason: "Записывание помогает лучше запоминать информацию на 40%.", difficulty: 2, popularityScore: 0.65),
    ]

    // MARK: - Productivity

    static let productivity: [HabitTemplate] = [
        HabitTemplate(name: "Составить план на день", icon: "list.bullet.clipboard.fill", category: .productivity, type: .boolean, suggestedTime: "morning", scientificReason: "Планирование утром помогает расставить приоритеты и снижает стресс.", tips: ["Выдели 3 главных задачи дня"], difficulty: 1, popularityScore: 0.90),
        HabitTemplate(name: "Фокус-сессия (Pomodoro)", icon: "timer", category: .productivity, type: .counter, suggestedTime: "morning", defaultCount: 4, scientificReason: "Метод Pomodoro повышает продуктивность на 25% за счёт управления вниманием.", tips: ["25 минут работы, 5 минут отдыха"], difficulty: 2, popularityScore: 0.82),
        HabitTemplate(name: "Убрать рабочее место", icon: "sparkles", category: .productivity, type: .boolean, suggestedTime: "morning", scientificReason: "Чистое рабочее место снижает когнитивную нагрузку и повышает фокусировку.", difficulty: 1, popularityScore: 0.74),
        HabitTemplate(name: "Без телефона 1 час", icon: "iphone.slash", category: .productivity, type: .timer, suggestedTime: "morning", defaultDuration: 3600, scientificReason: "Цифровая гигиена уменьшает тревожность и увеличивает глубокую работу.", difficulty: 3, popularityScore: 0.70),
        HabitTemplate(name: "Проверить email 2 раза в день", icon: "envelope.fill", category: .productivity, type: .counter, suggestedTime: "morning", defaultCount: 2, scientificReason: "Ограничение проверок почты экономит до 1 часа в день.", difficulty: 2, popularityScore: 0.65),
        HabitTemplate(name: "Подвести итоги дня", icon: "checklist.checked", category: .productivity, type: .boolean, suggestedTime: "evening", scientificReason: "Вечерний обзор помогает учиться на своих действиях и планировать лучше.", difficulty: 1, popularityScore: 0.76),
    ]

    // MARK: - Mindfulness

    static let mindfulness: [HabitTemplate] = [
        HabitTemplate(name: "Медитация", icon: "brain.fill", category: .mindfulness, type: .timer, suggestedTime: "morning", defaultDuration: 600, scientificReason: "10 минут медитации снижают уровень кортизола и улучшают фокусировку.", tips: ["Начни с 1 минуты дыхания"], difficulty: 1, popularityScore: 0.90),
        HabitTemplate(name: "Дыхательное упражнение", icon: "lungs.fill", category: .mindfulness, type: .timer, suggestedTime: "morning", defaultDuration: 300, scientificReason: "Техника 4-7-8 активирует парасимпатическую нервную систему.", difficulty: 1, popularityScore: 0.82),
        HabitTemplate(name: "Благодарность", icon: "heart.text.square.fill", category: .mindfulness, type: .boolean, suggestedTime: "morning", scientificReason: "Практика благодарности повышает уровень счастья на 25%.", tips: ["Запиши 3 вещи, за которые благодарен"], difficulty: 1, popularityScore: 0.85),
        HabitTemplate(name: "Без соцсетей перед сном", icon: "moon.zzz.fill", category: .mindfulness, type: .boolean, suggestedTime: "evening", scientificReason: "Отказ от экрана за час до сна улучшает качество сна на 20%.", difficulty: 2, popularityScore: 0.78),
        HabitTemplate(name: "Прогулка в тишине", icon: "ear.fill", category: .mindfulness, type: .timer, suggestedTime: "afternoon", defaultDuration: 900, scientificReason: "Тишина помогает мозгу обработать информацию и снизить стресс.", difficulty: 1, popularityScore: 0.68),
    ]

    // MARK: - Nutrition

    static let nutrition: [HabitTemplate] = [
        HabitTemplate(name: "Здоровый завтрак", icon: "cup.and.saucer.fill", category: .nutrition, type: .boolean, suggestedTime: "morning", scientificReason: "Завтрак запускает метаболизм и стабилизирует уровень сахара.", difficulty: 1, popularityScore: 0.85),
        HabitTemplate(name: "Съесть овощи", icon: "carrot.fill", category: .nutrition, type: .counter, suggestedTime: "afternoon", defaultCount: 3, scientificReason: "ВОЗ рекомендует 400г овощей и фруктов в день для снижения рисков заболеваний.", difficulty: 2, popularityScore: 0.78),
        HabitTemplate(name: "Съесть фрукт", icon: "leaf.fill", category: .nutrition, type: .boolean, suggestedTime: "afternoon", scientificReason: "Фрукты содержат антиоксиданты, витамины и клетчатку.", difficulty: 1, popularityScore: 0.80),
        HabitTemplate(name: "Готовить дома", icon: "frying.pan.fill", category: .nutrition, type: .boolean, frequency: .weekdays, suggestedTime: "evening", scientificReason: "Домашняя еда содержит в среднем на 30% меньше калорий, чем ресторанная.", difficulty: 2, popularityScore: 0.72),
        HabitTemplate(name: "Без сладкого", icon: "xmark.circle.fill", category: .nutrition, type: .boolean, suggestedTime: "morning", scientificReason: "Снижение сахара улучшает состояние кожи, энергию и фокусировку.", difficulty: 3, popularityScore: 0.65),
    ]

    // MARK: - Sleep

    static let sleep: [HabitTemplate] = [
        HabitTemplate(name: "Спать 8 часов", icon: "bed.double.fill", category: .sleep, type: .boolean, suggestedTime: "evening", scientificReason: "7-9 часов сна критичны для когнитивных функций и физического восстановления.", difficulty: 2, popularityScore: 0.88),
        HabitTemplate(name: "Лечь до 23:00", icon: "moon.fill", category: .sleep, type: .boolean, suggestedTime: "evening", scientificReason: "Раннее засыпание улучшает циркадные ритмы и выработку мелатонина.", difficulty: 2, popularityScore: 0.80),
        HabitTemplate(name: "Без экранов за час до сна", icon: "iphone.slash", category: .sleep, type: .boolean, suggestedTime: "evening", scientificReason: "Синий свет экранов подавляет выработку мелатонина на 50%.", difficulty: 3, popularityScore: 0.72),
        HabitTemplate(name: "Вечерний ритуал", icon: "sparkles", category: .sleep, type: .boolean, suggestedTime: "evening", scientificReason: "Постоянный вечерний ритуал сигнализирует мозгу о подготовке ко сну.", tips: ["Чай, книга, лёгкая растяжка"], difficulty: 1, popularityScore: 0.75),
    ]

    // MARK: - Relationships

    static let relationships: [HabitTemplate] = [
        HabitTemplate(name: "Позвонить близкому", icon: "phone.fill", category: .relationships, type: .boolean, frequency: .threePerWeek, suggestedTime: "evening", scientificReason: "Регулярное общение с близкими снижает стресс и повышает уровень счастья.", difficulty: 1, popularityScore: 0.78),
        HabitTemplate(name: "Комплимент другому", icon: "heart.fill", category: .relationships, type: .boolean, suggestedTime: "afternoon", scientificReason: "Проявление доброты укрепляет социальные связи и повышает собственное настроение.", difficulty: 1, popularityScore: 0.72),
        HabitTemplate(name: "Проведение времени с семьёй", icon: "person.2.fill", category: .relationships, type: .timer, suggestedTime: "evening", defaultDuration: 1800, scientificReason: "Качественное время с семьёй — ключевой фактор благополучия детей и взрослых.", difficulty: 1, popularityScore: 0.82),
        HabitTemplate(name: "Написать сообщение другу", icon: "message.fill", category: .relationships, type: .boolean, suggestedTime: "afternoon", scientificReason: "Мини-жесты поддерживают дружбу, даже когда нет времени на встречу.", difficulty: 1, popularityScore: 0.75),
    ]

    // MARK: - Finance

    static let finance: [HabitTemplate] = [
        HabitTemplate(name: "Записать расходы", icon: "banknote.fill", category: .finance, type: .boolean, suggestedTime: "evening", scientificReason: "Осознанный учёт расходов снижает импульсивные покупки на 20-30%.", difficulty: 1, popularityScore: 0.78),
        HabitTemplate(name: "Правило 24 часов (покупки)", icon: "clock.fill", category: .finance, type: .boolean, suggestedTime: "afternoon", scientificReason: "Ожидание перед покупкой снижает количество ненужных трат.", difficulty: 2, popularityScore: 0.65),
        HabitTemplate(name: "Отложить часть дохода", icon: "chart.line.uptrend.xyaxis", category: .finance, type: .boolean, frequency: .weekdays, suggestedTime: "morning", scientificReason: "Привычка откладывать даже маленькие суммы формирует финансовую подушку.", difficulty: 2, popularityScore: 0.70),
    ]

    // MARK: - Creativity

    static let creativity: [HabitTemplate] = [
        HabitTemplate(name: "Писать (journaling)", icon: "pencil.line", category: .creativity, type: .timer, suggestedTime: "morning", defaultDuration: 600, scientificReason: "Утреннее письмо освобождает мозг от навязчивых мыслей (Morning Pages).", tips: ["Пиши поток сознания, не оценивая"], difficulty: 1, popularityScore: 0.80),
        HabitTemplate(name: "Рисование / скетч", icon: "paintbrush.fill", category: .creativity, type: .timer, suggestedTime: "evening", defaultDuration: 900, scientificReason: "Рисование развивает пространственное мышление и снижает стресс.", difficulty: 1, popularityScore: 0.65),
        HabitTemplate(name: "Музыка (практика)", icon: "music.note", category: .creativity, type: .timer, frequency: .fivePerWeek, suggestedTime: "evening", defaultDuration: 1200, scientificReason: "Регулярная практика на инструменте улучшает нейронные связи.", difficulty: 2, popularityScore: 0.60),
        HabitTemplate(name: "Фотография дня", icon: "camera.fill", category: .creativity, type: .boolean, suggestedTime: "afternoon", scientificReason: "Ежедневная фотография развивает наблюдательность и эстетическое чувство.", difficulty: 1, popularityScore: 0.68),
    ]

    // MARK: - Goal Packs

    static func pack(for goalKeyword: String) -> [HabitTemplate] {
        let keyword = goalKeyword.lowercased()
        if keyword.contains("похуд") || keyword.contains("вес") {
            return [fitness[0], nutrition[0], nutrition[1], health[0], sleep[0]]
        }
        if keyword.contains("англ") || keyword.contains("язык") {
            return [learning[1], learning[2], learning[5]]
        }
        if keyword.contains("продуктив") || keyword.contains("работа") {
            return [productivity[0], productivity[1], mindfulness[0], sleep[0]]
        }
        if keyword.contains("здоров") {
            return [health[0], fitness[0], nutrition[0], sleep[0], mindfulness[0]]
        }
        if keyword.contains("спорт") || keyword.contains("фитнес") {
            return [fitness[0], fitness[1], fitness[3], nutrition[0], sleep[0]]
        }
        if keyword.contains("чита") || keyword.contains("книг") {
            return [learning[0], productivity[3], mindfulness[3]]
        }
        if keyword.contains("программ") || keyword.contains("код") {
            return [learning[4], productivity[0], productivity[1], health[0]]
        }
        // Default
        return [mindfulness[0], health[0], learning[0], productivity[0]]
    }

    // MARK: - Search

    static func search(query: String) -> [HabitTemplate] {
        let lowered = query.lowercased()
        return allTemplates.filter {
            $0.name.lowercased().contains(lowered) ||
            $0.category.displayName.lowercased().contains(lowered) ||
            $0.scientificReason.lowercased().contains(lowered)
        }
    }

    static func byCategory(_ category: HabitCategory) -> [HabitTemplate] {
        allTemplates.filter { $0.category == category }
    }
}
