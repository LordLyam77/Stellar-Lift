import Foundation

public enum ProgressionVerdict: String, CaseIterable, Sendable {
    case readyToProgress
    case progressing
    case grinding
    case stalled
    case stagnantLong
    case regressing
    case newExercise

    public var title: String {
        switch self {
        case .readyToProgress: return "Ready to Progress"
        case .progressing: return "Progressing"
        case .grinding: return "Grinding"
        case .stalled: return "Stalled"
        case .stagnantLong: return "Stagnant (> 21 Days)"
        case .regressing: return "Regressing"
        case .newExercise: return "New Exercise"
        }
    }

    public var badgeColorHex: String {
        switch self {
        case .readyToProgress: return "#4ADE80" // Green
        case .progressing: return "#38E8FF"     // Cyan
        case .grinding: return "#7C5CFF"        // Violet
        case .stalled: return "#FBBF24"         // Amber/Yellow
        case .stagnantLong: return "#FB7185"    // Crimson Danger
        case .regressing: return "#F43F5E"      // Red
        case .newExercise: return "#94A3B8"     // Slate
        }
    }
}

public struct ExerciseSessionMetrics: Sendable {
    public let date: Date
    public let topSetWeightKg: Double
    public let topSetReps: Int
    public let bestE1RM: Double
    public let totalVolumeKg: Double
    public let workingSetsCount: Int
    public let allWorkingSetsHitRepHigh: Bool

    public init(
        date: Date,
        topSetWeightKg: Double,
        topSetReps: Int,
        bestE1RM: Double,
        totalVolumeKg: Double,
        workingSetsCount: Int,
        allWorkingSetsHitRepHigh: Bool
    ) {
        self.date = date
        self.topSetWeightKg = topSetWeightKg
        self.topSetReps = topSetReps
        self.bestE1RM = bestE1RM
        self.totalVolumeKg = totalVolumeKg
        self.workingSetsCount = workingSetsCount
        self.allWorkingSetsHitRepHigh = allWorkingSetsHitRepHigh
    }
}

public struct ProgressionInsight: Sendable, Identifiable {
    public let id = UUID()
    public let exerciseName: String
    public let exerciseId: UUID?
    public let verdict: ProgressionVerdict
    public let message: String
    public let currentWeightKg: Double
    public let suggestedWeightKg: Double?
    public let suggestedRepRangeLow: Int
    public let suggestedRepRangeHigh: Int
    public let daysAtCurrentWeight: Int
    public let sessionsAtCurrentWeight: Int
    public let stalledOptions: [String]?

    public init(
        exerciseName: String,
        exerciseId: UUID? = nil,
        verdict: ProgressionVerdict,
        message: String,
        currentWeightKg: Double,
        suggestedWeightKg: Double? = nil,
        suggestedRepRangeLow: Int = 8,
        suggestedRepRangeHigh: Int = 12,
        daysAtCurrentWeight: Int = 0,
        sessionsAtCurrentWeight: Int = 0,
        stalledOptions: [String]? = nil
    ) {
        self.exerciseName = exerciseName
        self.exerciseId = exerciseId
        self.verdict = verdict
        self.message = message
        self.currentWeightKg = currentWeightKg
        self.suggestedWeightKg = suggestedWeightKg
        self.suggestedRepRangeLow = suggestedRepRangeLow
        self.suggestedRepRangeHigh = suggestedRepRangeHigh
        self.daysAtCurrentWeight = daysAtCurrentWeight
        self.sessionsAtCurrentWeight = sessionsAtCurrentWeight
        self.stalledOptions = stalledOptions
    }
}

public struct ProgressionAnalyzer: Sendable {
    public init() {}

    /// Extract per-session metrics for an exercise, using only working sets (isWarmup == false)
    public static func computeSessionMetrics(
        performed: PerformedExercise,
        sessionDate: Date,
        targetRepHigh: Int
    ) -> ExerciseSessionMetrics {
        let workingSets = performed.sets.filter { !$0.isWarmup }
        guard !workingSets.isEmpty else {
            return ExerciseSessionMetrics(
                date: sessionDate,
                topSetWeightKg: 0,
                topSetReps: 0,
                bestE1RM: 0,
                totalVolumeKg: 0,
                workingSetsCount: 0,
                allWorkingSetsHitRepHigh: false
            )
        }

        let maxWeight = workingSets.map(\.weightKg).max() ?? 0.0
        let topSets = workingSets.filter { abs($0.weightKg - maxWeight) < 0.001 }
        let bestRepsAtTopWeight = topSets.map(\.reps).max() ?? 0

        let bestE1RM = workingSets.map(\.e1RM).max() ?? 0.0
        let totalVol = workingSets.reduce(0.0) { $0 + $1.volumeKg }

        let allHitTop = workingSets.allSatisfy { $0.reps >= targetRepHigh }

        return ExerciseSessionMetrics(
            date: sessionDate,
            topSetWeightKg: maxWeight,
            topSetReps: bestRepsAtTopWeight,
            bestE1RM: bestE1RM,
            totalVolumeKg: totalVol,
            workingSetsCount: workingSets.count,
            allWorkingSetsHitRepHigh: allHitTop
        )
    }

    /// Analyze an exercise's history across the last 6 sessions and determine progression verdict
    public static func evaluate(
        exerciseName: String,
        exerciseId: UUID? = nil,
        equipment: EquipmentType,
        targetRepLow: Int,
        targetRepHigh: Int,
        history: [ExerciseSessionMetrics],
        profile: EquipmentProfile,
        now: Date = Date()
    ) -> ProgressionInsight {
        // Sort history by date ascending (oldest to newest)
        let sortedHistory = history.sorted { $0.date < $1.date }

        // Take up to the last 6 sessions
        let recent = Array(sortedHistory.suffix(6))

        guard recent.count >= 2, let latest = recent.last else {
            let curWeight = recent.last?.topSetWeightKg ?? 0.0
            return ProgressionInsight(
                exerciseName: exerciseName,
                exerciseId: exerciseId,
                verdict: .newExercise,
                message: "Log a couple more sessions and I'll start tracking progression.",
                currentWeightKg: curWeight,
                suggestedRepRangeLow: targetRepLow,
                suggestedRepRangeHigh: targetRepHigh
            )
        }

        let previous = recent[recent.count - 2]
        let currentWeight = latest.topSetWeightKg
        let nextWeight = EquipmentMath.nextAvailableWeight(above: currentWeight, for: equipment, profile: profile)

        // Count consecutive sessions at current top weight
        var sessionsAtCurrentWeight = 0
        var earliestDateAtWeight: Date = latest.date
        for session in recent.reversed() {
            if abs(session.topSetWeightKg - currentWeight) < 0.001 {
                sessionsAtCurrentWeight += 1
                earliestDateAtWeight = session.date
            } else {
                break
            }
        }

        let calendar = Calendar.current
        let daysAtWeight = max(0, calendar.dateComponents([.day], from: earliestDateAtWeight, to: now).day ?? 0)

        // Rule 1: Stagnant Long (>= 21 days at same weight)
        if daysAtWeight >= 21 && sessionsAtCurrentWeight >= 2 {
            let daysText = "\(daysAtWeight) days"
            let msg = "\(exerciseName) has been \(formatWeight(currentWeight)) since \(formatDate(earliestDateAtWeight)) — that's \(daysText) and \(sessionsAtCurrentWeight) sessions. Time to test \(formatWeight(nextWeight)) for \(targetRepLow)–\(targetRepHigh) reps."
            return ProgressionInsight(
                exerciseName: exerciseName,
                exerciseId: exerciseId,
                verdict: .stagnantLong,
                message: msg,
                currentWeightKg: currentWeight,
                suggestedWeightKg: nextWeight,
                suggestedRepRangeLow: targetRepLow,
                suggestedRepRangeHigh: targetRepHigh,
                daysAtCurrentWeight: daysAtWeight,
                sessionsAtCurrentWeight: sessionsAtCurrentWeight
            )
        }

        // Rule 2: Regressing (e1RM down >= 5% across last 3 sessions)
        if recent.count >= 3 {
            let slice = Array(recent.suffix(3))
            let firstE1RM = slice[0].bestE1RM
            let latestE1RM = slice[2].bestE1RM
            if firstE1RM > 0 && ((firstE1RM - latestE1RM) / firstE1RM) >= 0.05 {
                return ProgressionInsight(
                    exerciseName: exerciseName,
                    exerciseId: exerciseId,
                    verdict: .regressing,
                    message: "Numbers are sliding. Check sleep, food, or take a deload week.",
                    currentWeightKg: currentWeight,
                    suggestedRepRangeLow: targetRepLow,
                    suggestedRepRangeHigh: targetRepHigh,
                    daysAtCurrentWeight: daysAtWeight,
                    sessionsAtCurrentWeight: sessionsAtCurrentWeight
                )
            }
        }

        // Rule 3: Ready to Progress
        // Top-set weight unchanged for >= 2 sessions AND reps at that weight reached targetRepHigh on all target sets in the most recent session
        if sessionsAtCurrentWeight >= 2 && latest.allWorkingSetsHitRepHigh {
            let msg = "You've maxed the rep range at \(formatWeight(currentWeight)). Next session start at \(formatWeight(nextWeight)) and drop back to \(targetRepLow) reps."
            return ProgressionInsight(
                exerciseName: exerciseName,
                exerciseId: exerciseId,
                verdict: .readyToProgress,
                message: msg,
                currentWeightKg: currentWeight,
                suggestedWeightKg: nextWeight,
                suggestedRepRangeLow: targetRepLow,
                suggestedRepRangeHigh: targetRepHigh,
                daysAtCurrentWeight: daysAtWeight,
                sessionsAtCurrentWeight: sessionsAtCurrentWeight
            )
        }

        // Rule 4: Progressing
        // Top-set weight or e1RM increased vs previous session
        if latest.topSetWeightKg > previous.topSetWeightKg || latest.bestE1RM > (previous.bestE1RM + 0.5) {
            let weightDiff = latest.topSetWeightKg - previous.topSetWeightKg
            let note = weightDiff > 0 ? "Up \(formatWeight(weightDiff)) from last time. Keep it." : "Estimated 1RM is climbing. Solid progression."
            return ProgressionInsight(
                exerciseName: exerciseName,
                exerciseId: exerciseId,
                verdict: .progressing,
                message: note,
                currentWeightKg: currentWeight,
                suggestedRepRangeLow: targetRepLow,
                suggestedRepRangeHigh: targetRepHigh,
                daysAtCurrentWeight: daysAtWeight,
                sessionsAtCurrentWeight: sessionsAtCurrentWeight
            )
        }

        // Rule 5: Stalled (Same weight for >= 3 sessions AND reps have not improved)
        if sessionsAtCurrentWeight >= 3 {
            let relevantSlice = Array(recent.suffix(sessionsAtCurrentWeight))
            let repsHistory = relevantSlice.map(\.topSetReps)
            let isRepsImproving = repsHistory.count >= 2 && (repsHistory.last ?? 0) > (repsHistory.first ?? 0)

            if !isRepsImproving {
                let options = [
                    "Micro-load: Use smallest available jump (\(formatWeight(EquipmentMath.nextAvailableWeight(above: currentWeight, for: equipment, profile: profile) - currentWeight)))",
                    "Add an extra working set at \(formatWeight(currentWeight))",
                    "Deload 10% to \(formatWeight(currentWeight * 0.9)) and build back up with cleaner form",
                    "Swap to a variation for 3–4 weeks"
                ]
                return ProgressionInsight(
                    exerciseName: exerciseName,
                    exerciseId: exerciseId,
                    verdict: .stalled,
                    message: "Plateau detected at \(formatWeight(currentWeight)) across \(sessionsAtCurrentWeight) sessions.",
                    currentWeightKg: currentWeight,
                    suggestedRepRangeLow: targetRepLow,
                    suggestedRepRangeHigh: targetRepHigh,
                    daysAtCurrentWeight: daysAtWeight,
                    sessionsAtCurrentWeight: sessionsAtCurrentWeight,
                    stalledOptions: options
                )
            }
        }

        // Rule 6: Grinding (Same weight for 2–3 sessions, reps still climbing inside range)
        if sessionsAtCurrentWeight >= 2 {
            let relevantSlice = Array(recent.suffix(sessionsAtCurrentWeight))
            let repsSequence = relevantSlice.map { "\($0.topSetReps)" }.joined(separator: " → ")
            let msg = "Reps are moving — \(repsSequence). Keep pushing toward \(targetRepHigh) reps at \(formatWeight(currentWeight))."
            return ProgressionInsight(
                exerciseName: exerciseName,
                exerciseId: exerciseId,
                verdict: .grinding,
                message: msg,
                currentWeightKg: currentWeight,
                suggestedRepRangeLow: targetRepLow,
                suggestedRepRangeHigh: targetRepHigh,
                daysAtCurrentWeight: daysAtWeight,
                sessionsAtCurrentWeight: sessionsAtCurrentWeight
            )
        }

        // Default: Progressing or stable
        return ProgressionInsight(
            exerciseName: exerciseName,
            exerciseId: exerciseId,
            verdict: .progressing,
            message: "Consistent performance. Focus on controlled reps.",
            currentWeightKg: currentWeight,
            suggestedRepRangeLow: targetRepLow,
            suggestedRepRangeHigh: targetRepHigh,
            daysAtCurrentWeight: daysAtWeight,
            sessionsAtCurrentWeight: sessionsAtCurrentWeight
        )
    }

    /// Deload Detector: Check if >= 40% of tracked exercises are stalled or regressing in the same week
    public static func shouldRecommendDeload(insights: [ProgressionInsight]) -> Bool {
        guard insights.count >= 3 else { return false }
        let problemCount = insights.filter { $0.verdict == .stalled || $0.verdict == .stagnantLong || $0.verdict == .regressing }.count
        let ratio = Double(problemCount) / Double(insights.count)
        return ratio >= 0.40
    }

    private static func formatWeight(_ kg: Double) -> String {
        if kg.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(kg))kg"
        }
        return String(format: "%.1fkg", kg)
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
