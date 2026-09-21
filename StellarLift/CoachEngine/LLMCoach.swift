import Foundation

public struct LLMCoach: CoachProvider, Sendable {
    private let ruleFallback = RuleBasedCoach()

    public init() {}

    public var isAvailable: Bool {
        let mode = UserDefaults.standard.string(forKey: "aiCoachMode") ?? "off"
        return mode != "off"
    }

    public func commentary(for insight: ProgressionInsight) async -> String {
        return insight.message
    }

    public func answer(question: String, context: TrainingContext) async throws -> String {
        let mode = UserDefaults.standard.string(forKey: "aiCoachMode") ?? "off"
        guard mode != "off" else {
            return try await ruleFallback.answer(question: question, context: context)
        }

        let baseURLString = UserDefaults.standard.string(forKey: "aiCoachBaseURL") ?? "https://api.openai.com/v1"
        let apiKey = UserDefaults.standard.string(forKey: "aiCoachAPIKey") ?? ""
        let modelName = UserDefaults.standard.string(forKey: "aiCoachModelName") ?? "gpt-4o-mini"

        guard let endpoint = URL(string: baseURLString.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + "/chat/completions") else {
            return try await ruleFallback.answer(question: question, context: context)
        }

        let systemPrompt = """
        You are Stellar Lift's elite, evidence-based hypertrophy strength coach.
        Guidelines:
        - Strict metric units (kg).
        - Double progression model: hold weight until top of rep range is reached across all sets, then increase load.
        - Extremely concise, actionable answers (under 120 words).
        - No medical advice. Never hallucinate weights not in context.
        """

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt + "\n\n" + context.summaryText],
            ["role": "user", "content": question]
        ]

        let payload: [String: Any] = [
            "model": modelName,
            "messages": messages,
            "temperature": 0.3,
            "max_tokens": 300
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            return try await ruleFallback.answer(question: question, context: context)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = httpBody
        request.timeoutInterval = 12.0 // short timeout for responsiveness

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
                return try await ruleFallback.answer(question: question, context: context)
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let msg = firstChoice["message"] as? [String: Any],
               let content = msg["content"] as? String {
                return content.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            // Silently fall back to rule-based coach on network failure / offline mode
            return try await ruleFallback.answer(question: question, context: context)
        }

        return try await ruleFallback.answer(question: question, context: context)
    }
}
