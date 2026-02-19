import Foundation

enum BackendError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL."
        case .invalidResponse:
            return "Backend response was invalid."
        case .serverError(let statusCode, let message):
            return "Server error \(statusCode): \(message)"
        }
    }
}

protocol SteadyTapBackendClient {
    func fetchCoachPlan(userID: String, history: [SessionSummary]) async throws -> CoachPlan
    func fetchBenchmark(userID: String, history: [SessionSummary]) async throws -> BenchmarkSnapshot
    func uploadSession(_ payload: SessionUploadPayload) async throws
}

struct MockBackendClient: SteadyTapBackendClient {
    func fetchCoachPlan(userID: String, history: [SessionSummary]) async throws -> CoachPlan {
        try await Task.sleep(nanoseconds: 280_000_000)

        let recent = Array(history.prefix(6))
        let avgDelta = recent.isEmpty ? 0 : (recent.map(\.scoreDelta).reduce(0, +) / Double(recent.count))
        let preset: ScoringPreset = avgDelta < 4 ? .missFocused : (avgDelta < 9 ? .balanced : .speedFocused)
        let intensity: ChallengeIntensity = avgDelta < 3 ? .supportive : (avgDelta < 10 ? .standard : .advanced)
        let confidence = (0.55 + min(0.35, abs(avgDelta) / 30.0)).clamped(to: 0...0.94)

        return CoachPlan(
            generatedAt: .now,
            focusArea: avgDelta < 3 ? "Precision stabilization" : "Adaptive speed confidence",
            rationale: avgDelta < 3
                ? "Recent sessions show modest gains. Prioritize fewer misses with stronger confirmation timing."
                : "Improvement trend is healthy. Balance precision and pace while maintaining low accidental inputs.",
            recommendedPresetRawValue: preset.rawValue,
            recommendedIntensityRawValue: intensity.rawValue,
            targetScoreDelta: max(6, avgDelta + 2.5),
            targetSessionsPerWeek: recent.count >= 3 ? 4 : 5,
            confidence: confidence,
            actionItems: buildActionItems(
                avgDelta: avgDelta,
                recommendedPreset: preset,
                recommendedIntensity: intensity
            )
        )
    }

    func fetchBenchmark(userID: String, history: [SessionSummary]) async throws -> BenchmarkSnapshot {
        try await Task.sleep(nanoseconds: 180_000_000)

        let recent = Array(history.prefix(8))
        let avgDelta = recent.isEmpty ? 0 : (recent.map(\.scoreDelta).reduce(0, +) / Double(recent.count))
        let percentile = Int((58 + avgDelta * 2.1).clamped(to: 25...96))

        return BenchmarkSnapshot(
            generatedAt: .now,
            cohortLabel: "Motor accessibility learners",
            percentile: percentile,
            averageScoreDelta: (5.8 + (avgDelta * 0.15)).clamped(to: -5...25)
        )
    }

    func uploadSession(_ payload: SessionUploadPayload) async throws {
        try await Task.sleep(nanoseconds: 150_000_000)
        _ = payload
    }

    private func buildActionItems(
        avgDelta: Double,
        recommendedPreset: ScoringPreset,
        recommendedIntensity: ChallengeIntensity
    ) -> [String] {
        if avgDelta < 3 {
            return [
                "Use \(recommendedPreset.title) for the next 3 sessions.",
                "Set intensity to \(recommendedIntensity.title) for more stable input filtering.",
                "Keep accidental touches under 2 per run.",
                "Recalibrate when confidence is medium or lower."
            ]
        }

        return [
            "Keep \(recommendedPreset.title) as your primary mode this week.",
            "Run sessions in \(recommendedIntensity.title) intensity.",
            "Try to beat your last score delta by +1.5.",
            "Run at least 4 sessions this week to stabilize trend."
        ]
    }
}

struct CloudBackendClient: SteadyTapBackendClient {
    let baseURL: URL
    let token: String?
    let session: URLSession

    init(baseURL: URL, token: String? = nil, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
    }

    func fetchCoachPlan(userID: String, history: [SessionSummary]) async throws -> CoachPlan {
        let requestBody = CoachPlanRequest(userID: userID, recentSessions: history)
        let request = try makeRequest(
            path: "/v1/coach/plan",
            method: "POST",
            body: requestBody
        )
        let response: CoachPlanResponse = try await send(request)
        return response.toDomain()
    }

    func fetchBenchmark(userID: String, history: [SessionSummary]) async throws -> BenchmarkSnapshot {
        let requestBody = BenchmarkRequest(userID: userID, recentSessions: history)
        let request = try makeRequest(
            path: "/v1/benchmarks",
            method: "POST",
            body: requestBody
        )
        let response: BenchmarkResponse = try await send(request)
        return response.toDomain()
    }

    func uploadSession(_ payload: SessionUploadPayload) async throws {
        let request = try makeRequest(
            path: "/v1/sessions",
            method: "POST",
            body: payload
        )
        let _: UploadSessionResponse = try await send(request)
    }

    private func makeRequest<Body: Encodable>(path: String, method: String, body: Body) throws -> URLRequest {
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = baseURL.appendingPathComponent(cleanPath)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder.steadyTap.encode(body)
        return request
    }

    private func send<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, urlResponse) = try await session.data(for: request)

        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw BackendError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown"
            throw BackendError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        return try JSONDecoder.steadyTap.decode(Response.self, from: data)
    }
}

private struct CoachPlanRequest: Encodable {
    let userID: String
    let recentSessions: [SessionSummary]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case recentSessions = "recent_sessions"
    }
}

private struct BenchmarkRequest: Encodable {
    let userID: String
    let recentSessions: [SessionSummary]

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case recentSessions = "recent_sessions"
    }
}

private struct CoachPlanResponse: Decodable {
    let generatedAt: Date
    let focusArea: String
    let rationale: String
    let recommendedPreset: String
    let recommendedIntensity: String?
    let targetScoreDelta: Double
    let targetSessionsPerWeek: Int
    let confidence: Double
    let actionItems: [String]?

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case focusArea = "focus_area"
        case rationale
        case recommendedPreset = "recommended_preset"
        case recommendedIntensity = "recommended_intensity"
        case targetScoreDelta = "target_score_delta"
        case targetSessionsPerWeek = "target_sessions_per_week"
        case confidence
        case actionItems = "action_items"
    }

    func toDomain() -> CoachPlan {
        CoachPlan(
            generatedAt: generatedAt,
            focusArea: focusArea,
            rationale: rationale,
            recommendedPresetRawValue: recommendedPreset,
            recommendedIntensityRawValue: recommendedIntensity ?? ChallengeIntensity.standard.rawValue,
            targetScoreDelta: targetScoreDelta,
            targetSessionsPerWeek: targetSessionsPerWeek,
            confidence: confidence,
            actionItems: actionItems ?? []
        )
    }
}

private struct BenchmarkResponse: Decodable {
    let generatedAt: Date
    let cohortLabel: String
    let percentile: Int
    let averageScoreDelta: Double

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case cohortLabel = "cohort_label"
        case percentile
        case averageScoreDelta = "average_score_delta"
    }

    func toDomain() -> BenchmarkSnapshot {
        BenchmarkSnapshot(
            generatedAt: generatedAt,
            cohortLabel: cohortLabel,
            percentile: percentile,
            averageScoreDelta: averageScoreDelta
        )
    }
}

private struct UploadSessionResponse: Decodable {
    let accepted: Bool
}

private extension JSONEncoder {
    static var steadyTap: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var steadyTap: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
