import Foundation

public struct TrainingContext: Sendable {
    public let summaryText: String
    public let topSetsPerExercise: [String: String]
    public let currentVerdicts: [String: String]
    public let weeklyVolumePerMuscle: [String: Int]

    public init(
        topSetsPerExercise: [String: String],
        currentVerdicts: [String: String],
        weeklyVolumePerMuscle: [String: Int]
    ) {
        self.topSetsPerExercise = topSetsPerExercise
        self.currentVerdicts = currentVerdicts
        self.weeklyVolumePerMuscle = weeklyVolumePerMuscle

        var lines: [String] = ["USER TRAINING CONTEXT (Metric):"]

        // 1. Current Verdicts
        lines.append("Progression Status:")
        for (ex, verdict) in currentVerdicts.prefix(8) {
            lines.append("  - \(ex): \(verdict)")
        }

        // 2. Recent Top Sets
        lines.append("Recent Top Sets:")
        for (ex, topSet) in topSetsPerExercise.prefix(8) {
            lines.append("  - \(ex): \(topSet)")
        }

        // 3. Weekly Volume
        lines.append("Weekly Sets / Muscle Group:")
        for (muscle, count) in weeklyVolumePerMuscle {
            lines.append("  - \(muscle): \(count) sets")
        }

        self.summaryText = lines.joined(separator: "\n")
    }

    public static var empty: TrainingContext {
        TrainingContext(
            topSetsPerExercise: [:],
            currentVerdicts: [:],
            weeklyVolumePerMuscle: [:]
        )
    }
}
