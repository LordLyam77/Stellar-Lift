import Foundation

public struct WarmupStep: Identifiable, Sendable {
    public let id: Int
    public let weightKg: Double
    public let reps: Int
    public let percentage: Int
    public let instruction: String

    public init(id: Int, weightKg: Double, reps: Int, percentage: Int, instruction: String) {
        self.id = id
        self.weightKg = weightKg
        self.reps = reps
        self.percentage = percentage
        self.instruction = instruction
    }
}

public enum WarmupCalculator {
    public static func generateRampSets(
        targetWorkingWeightKg: Double,
        barbellWeightKg: Double = 20.0,
        equipment: EquipmentType = .barbell
    ) -> [WarmupStep] {
        guard targetWorkingWeightKg > 0 else { return [] }

        var steps: [WarmupStep] = []
        var stepId = 1

        if equipment == .barbell {
            // Step 1: Empty bar if working weight is > 40kg
            if targetWorkingWeightKg > 40.0 {
                steps.append(WarmupStep(
                    id: stepId,
                    weightKg: barbellWeightKg,
                    reps: 10,
                    percentage: Int(round((barbellWeightKg / targetWorkingWeightKg) * 100)),
                    instruction: "Empty bar mobility & joint prep"
                ))
                stepId += 1
            }

            // 40% ramp
            let weight40 = roundToNearest(targetWorkingWeightKg * 0.40, increment: 2.5)
            if weight40 > barbellWeightKg && weight40 < targetWorkingWeightKg * 0.55 {
                steps.append(WarmupStep(
                    id: stepId,
                    weightKg: weight40,
                    reps: 6,
                    percentage: 40,
                    instruction: "Warmup: Groove motor pattern"
                ))
                stepId += 1
            }

            // 60% ramp
            let weight60 = roundToNearest(targetWorkingWeightKg * 0.60, increment: 2.5)
            if weight60 > barbellWeightKg && weight60 < targetWorkingWeightKg * 0.75 {
                steps.append(WarmupStep(
                    id: stepId,
                    weightKg: weight60,
                    reps: 4,
                    percentage: 60,
                    instruction: "Moderate prep: Accelerate bar speed"
                ))
                stepId += 1
            }

            // 80% ramp
            let weight80 = roundToNearest(targetWorkingWeightKg * 0.80, increment: 2.5)
            if weight80 > barbellWeightKg && weight80 < targetWorkingWeightKg - 2.5 {
                steps.append(WarmupStep(
                    id: stepId,
                    weightKg: weight80,
                    reps: 2,
                    percentage: 80,
                    instruction: "Heavy potentiation: Priming CNS"
                ))
                stepId += 1
            }
        } else {
            // Dumbbell, machine, cable
            let weight50 = roundToNearest(targetWorkingWeightKg * 0.50, increment: 2.5)
            let weight75 = roundToNearest(targetWorkingWeightKg * 0.75, increment: 2.5)

            if weight50 > 0 && weight50 < targetWorkingWeightKg {
                steps.append(WarmupStep(
                    id: stepId,
                    weightKg: weight50,
                    reps: 8,
                    percentage: 50,
                    instruction: "Light warm-up"
                ))
                stepId += 1
            }

            if weight75 > weight50 && weight75 < targetWorkingWeightKg {
                steps.append(WarmupStep(
                    id: stepId,
                    weightKg: weight75,
                    reps: 4,
                    percentage: 75,
                    instruction: "Priming set"
                ))
                stepId += 1
            }
        }

        return steps
    }

    private static func roundToNearest(_ value: Double, increment: Double) -> Double {
        return round(value / increment) * increment
    }
}
