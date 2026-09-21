import Foundation

public struct RuleBasedCoach: CoachProvider, Sendable {
    public init() {}

    public var isAvailable: Bool { true }

    public func commentary(for insight: ProgressionInsight) async -> String {
        return insight.message
    }

    public func answer(question: String, context: TrainingContext) async throws -> String {
        let q = question.lowercased()

        if q.contains("stall") || q.contains("plateau") || q.contains("bench") {
            return """
            Analyzing your training logs:
            When a compound lift stalls, double progression offers four evidence-based solutions:
            1. Micro-loading: Use the smallest jump available in your rack (1.25kg plates per side = 2.5kg total).
            2. Set Volume: Add 1 hard set at your current weight before trying to increase load.
            3. 10% Deload: Drop weight by 10% for 1 week, focus on concentric speed and bar path, then ramp back up in 2-week increments.
            4. Variation Rotation: Switch to an equivalent variation (e.g. Incline Dumbbell Press to Smith Machine Incline) for 3–4 weeks.
            """
        }

        if q.contains("split") || q.contains("routine") || q.contains("hypertrophy") {
            return """
            For evidence-based hypertrophy, weekly muscle group frequency of 2× per week is optimal.
            Recommended 6-day routines built into Stellar Lift:
            • Push / Pull / Legs (PPL ×2): Clean division of movement patterns, hitting chest/delts/triceps (Push), lats/rhomboids/biceps (Pull), and quads/hamstrings/calves (Legs).
            • Arnold Split: Chest & Back on Day 1/4, Shoulders & Arms on Day 2/5, Legs on Day 3/6. Provides tremendous antagonist pumps.
            You can import either template with one tap in the Splits tab.
            """
        }

        if q.contains("deload") {
            return """
            A deload is indicated when over 40% of your primary lifts show stagnated reps or dropping e1RM.
            Protocol: Keep your current working weights, but reduce working sets to ⅔ (e.g. 2 sets instead of 3), stopping 3–4 reps shy of failure. This flushes systemic fatigue while preserving neuromuscular adaptations.
            """
        }

        // Generic context-aware fallback response
        return """
        Based on your current logged training:
        You are progressing across multiple lifts using double progression. Continue holding weights until reaching the top of your target rep range on all working sets. Ensure adequate sleep (7–9h) and daily protein intake (~1.6–2.2g per kg bodyweight).
        """
    }
}
