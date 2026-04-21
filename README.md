# Sergi — AI-Коуч по привычкам

iOS-приложение на **SwiftUI + SwiftData** с AI-коучем, трекером привычек, геймификацией и журналом рефлексии.

## Требования

- **Xcode 15+** (Swift 5.9)
- **iOS 17.0+**
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) для генерации `.xcodeproj`

## Быстрый старт

```bash
# 1. Установи XcodeGen (если ещё нет)
brew install xcodegen

# 2. Сгенерируй Xcode-проект
xcodegen generate

# 3. Открой в Xcode
open Sergi.xcodeproj
```

## Архитектура

```
Sergi/
├── Core/Models/         # SwiftData модели + Enum'ы
├── Core/Services/       # HabitService, AICoachService, StoreService, etc.
├── Features/            # Экраны: Home, Library, AICoach, Progress, Journal, Settings, Paywall, Onboarding
├── Navigation/          # MainTabView (кастомный TabBar)
├── SharedUI/            # Дизайн-система (SergiTheme) + переиспользуемые компоненты
└── SergiApp.swift       # Точка входа @main
```

## Ключевые функции

- **AI-Коуч** (OpenAI gpt-4o-mini) — генерация плана, мотивация, инсайты
- **60+ привычек** в библиотеке с научным обоснованием
- **Геймификация** — XP, уровни, 15 значков
- **Журнал** — настроение, энергия, благодарность
- **Подписки** — StoreKit 2 с 3-дневным триалом
- **Уведомления** — контекстные + streak-aware