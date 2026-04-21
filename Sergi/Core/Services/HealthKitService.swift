import Foundation
import HealthKit

// MARK: - HealthKit Service

@Observable
final class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false
    private(set) var todaySteps: Int = 0
    private(set) var todayActiveMinutes: Int = 0
    private(set) var todaySleepHours: Double = 0

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.appleExerciseTime),
            HKCategoryType(.sleepAnalysis),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning)
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            return true
        } catch {
            return false
        }
    }

    // MARK: - Fetch Today Steps

    func fetchTodaySteps() async -> Int {
        guard isAvailable else { return 0 }

        let stepsType = HKQuantityType(.stepCount)
        let predicate = todayPredicate()

        do {
            let result = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: stepsType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, stats, error in
                    if let error {
                        cont.resume(throwing: error)
                        return
                    }
                    let sum = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    cont.resume(returning: sum)
                }
                healthStore.execute(query)
            }
            todaySteps = Int(result)
            return todaySteps
        } catch {
            return 0
        }
    }

    // MARK: - Fetch Today Active Minutes

    func fetchTodayActiveMinutes() async -> Int {
        guard isAvailable else { return 0 }

        let exerciseType = HKQuantityType(.appleExerciseTime)
        let predicate = todayPredicate()

        do {
            let result = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: exerciseType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, stats, error in
                    if let error {
                        cont.resume(throwing: error)
                        return
                    }
                    let sum = stats?.sumQuantity()?.doubleValue(for: .minute()) ?? 0
                    cont.resume(returning: sum)
                }
                healthStore.execute(query)
            }
            todayActiveMinutes = Int(result)
            return todayActiveMinutes
        } catch {
            return 0
        }
    }

    // MARK: - Fetch Today Sleep

    func fetchTodaySleepHours() async -> Double {
        guard isAvailable else { return 0 }

        let sleepType = HKCategoryType(.sleepAnalysis)
        let calendar = Calendar.current
        let now = Date()
        guard let start = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: now)) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now, options: .strictEndDate)

        do {
            let result = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Double, Error>) in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                ) { _, samples, error in
                    if let error {
                        cont.resume(throwing: error)
                        return
                    }
                    guard let samples = samples as? [HKCategorySample] else {
                        cont.resume(returning: 0)
                        return
                    }
                    let asleepSamples = samples.filter {
                        $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                        $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                        $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                        $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                    }
                    let totalSeconds = asleepSamples.reduce(0.0) { sum, sample in
                        sum + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                    cont.resume(returning: totalSeconds / 3600.0)
                }
                healthStore.execute(query)
            }
            todaySleepHours = result
            return todaySleepHours
        } catch {
            return 0
        }
    }

    // MARK: - Refresh All

    func refreshAll() async {
        _ = await fetchTodaySteps()
        _ = await fetchTodayActiveMinutes()
        _ = await fetchTodaySleepHours()
    }

    // MARK: - Private

    private func todayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        return HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
    }
}
