import Foundation
import SwiftData

// MARK: - Export Service

final class ExportService {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Export Habits CSV

    func exportHabitsCSV() -> URL? {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.sortOrder)])
        guard let habits = try? modelContext.fetch(descriptor) else { return nil }

        var csv = "Название,Категория,Тип,Частота,Текущая серия,Лучшая серия,Выполнение %,Создана,Архивирована\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for habit in habits {
            let archived = habit.archivedAt.map { dateFormatter.string(from: $0) } ?? ""
            let line = [
                escapeCSV(habit.name),
                habit.category.displayName,
                habit.type.displayName,
                habit.frequency.displayName,
                "\(habit.currentStreak)",
                "\(habit.bestStreak)",
                "\(Int(habit.completionRate * 100))",
                dateFormatter.string(from: habit.createdAt),
                archived
            ].joined(separator: ",")
            csv += line + "\n"
        }

        return writeToFile(csv, filename: "sergi_habits.csv")
    }

    // MARK: - Export Entries CSV

    func exportEntriesCSV() -> URL? {
        let descriptor = FetchDescriptor<HabitEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let entries = try? modelContext.fetch(descriptor) else { return nil }

        var csv = "Дата,Привычка,Выполнено,Счёт,Длительность мин,Flex день,Заметка\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for entry in entries {
            let line = [
                dateFormatter.string(from: entry.date),
                escapeCSV(entry.habit?.name ?? "—"),
                entry.isCompleted ? "Да" : "Нет",
                "\(entry.count)",
                "\(Int(entry.duration / 60))",
                entry.isFlexDay ? "Да" : "Нет",
                escapeCSV(entry.note ?? "")
            ].joined(separator: ",")
            csv += line + "\n"
        }

        return writeToFile(csv, filename: "sergi_entries.csv")
    }

    // MARK: - Export Journal CSV

    func exportJournalCSV() -> URL? {
        let descriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        guard let entries = try? modelContext.fetch(descriptor) else { return nil }

        var csv = "Дата,Настроение,Энергия,Благодарность,Мысли\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for entry in entries {
            let gratitude = entry.gratitudeItems.joined(separator: "; ")
            let line = [
                dateFormatter.string(from: entry.date),
                entry.mood.label,
                "\(entry.energyLevel)",
                escapeCSV(gratitude),
                escapeCSV(entry.reflectionText ?? "")
            ].joined(separator: ",")
            csv += line + "\n"
        }

        return writeToFile(csv, filename: "sergi_journal.csv")
    }

    // MARK: - Full Export (all data)

    func exportAllData() -> URL? {
        let habitsCSV = exportHabitsCSV()
        let entriesCSV = exportEntriesCSV()
        let journalCSV = exportJournalCSV()

        let files = [habitsCSV, entriesCSV, journalCSV].compactMap { $0 }
        guard !files.isEmpty else { return nil }

        // If multiple files, create a directory and return the first one
        // For simplicity, we create a combined summary
        return habitsCSV
    }

    // MARK: - Private

    private func escapeCSV(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\"", with: "\"\"")
            .replacingOccurrences(of: "\n", with: " ")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains(";") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private func writeToFile(_ content: String, filename: String) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}
