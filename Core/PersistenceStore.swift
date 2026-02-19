import Foundation

enum PersistenceStore {
    private static let historyKey = "steadytap.history.v1"
    private static let preferencesKey = "steadytap.preferences.v1"
    private static let syncJobsKey = "steadytap.syncjobs.v1"
    private static let coachPlanKey = "steadytap.coachplan.v1"
    private static let benchmarkKey = "steadytap.benchmark.v1"
    private static let maxHistoryCount = 12
    private static let maxSyncJobCount = 80

    static func loadHistory() -> [SessionSummary] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            return []
        }

        do {
            return try decoder.decode([SessionSummary].self, from: data)
        } catch {
            return []
        }
    }

    static func saveHistory(_ history: [SessionSummary]) {
        let trimmed = Array(history.prefix(maxHistoryCount))

        do {
            let data = try encoder.encode(trimmed)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            return
        }
    }

    static func clearHistory() {
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    static func loadPreferences() -> AppPreferences {
        guard let data = UserDefaults.standard.data(forKey: preferencesKey) else {
            return .default
        }

        do {
            return try decoder.decode(AppPreferences.self, from: data)
        } catch {
            return .default
        }
    }

    static func savePreferences(_ preferences: AppPreferences) {
        do {
            let data = try encoder.encode(preferences)
            UserDefaults.standard.set(data, forKey: preferencesKey)
        } catch {
            return
        }
    }

    static func loadSyncJobs() -> [SyncJob] {
        guard let data = UserDefaults.standard.data(forKey: syncJobsKey) else {
            return []
        }

        do {
            return try decoder.decode([SyncJob].self, from: data)
        } catch {
            return []
        }
    }

    static func saveSyncJobs(_ jobs: [SyncJob]) {
        let trimmed = Array(jobs.prefix(maxSyncJobCount))

        do {
            let data = try encoder.encode(trimmed)
            UserDefaults.standard.set(data, forKey: syncJobsKey)
        } catch {
            return
        }
    }

    static func clearSyncJobs() {
        UserDefaults.standard.removeObject(forKey: syncJobsKey)
    }

    static func loadCoachPlan() -> CoachPlan? {
        guard let data = UserDefaults.standard.data(forKey: coachPlanKey) else {
            return nil
        }

        return try? decoder.decode(CoachPlan.self, from: data)
    }

    static func saveCoachPlan(_ coachPlan: CoachPlan?) {
        guard let coachPlan else {
            UserDefaults.standard.removeObject(forKey: coachPlanKey)
            return
        }

        do {
            let data = try encoder.encode(coachPlan)
            UserDefaults.standard.set(data, forKey: coachPlanKey)
        } catch {
            return
        }
    }

    static func loadBenchmark() -> BenchmarkSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: benchmarkKey) else {
            return nil
        }

        return try? decoder.decode(BenchmarkSnapshot.self, from: data)
    }

    static func saveBenchmark(_ benchmark: BenchmarkSnapshot?) {
        guard let benchmark else {
            UserDefaults.standard.removeObject(forKey: benchmarkKey)
            return
        }

        do {
            let data = try encoder.encode(benchmark)
            UserDefaults.standard.set(data, forKey: benchmarkKey)
        } catch {
            return
        }
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
