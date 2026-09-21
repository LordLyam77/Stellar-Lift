import Foundation

public protocol CoachProvider: Sendable {
    func commentary(for insight: ProgressionInsight) async -> String
    func answer(question: String, context: TrainingContext) async throws -> String
    var isAvailable: Bool { get }
}
