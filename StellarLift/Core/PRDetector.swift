import Foundation
import SwiftData

public struct PRHit: Identifiable, Sendable {
    public let id = UUID()
    public let exerciseId: UUID?
    public let exerciseName: String
    public let recordType: RecordType
    public let oldValue: Double
    public let newValue: Double
    public let displayText: String
}

public enum PRDetector {
    /// Detect if a completed set breaks existing personal records for an exercise
    public static func checkForPR(
        exercise: Exercise?,
        exerciseName: String,
        set: SetEntry,
        existingRecords: [PersonalRecord]
    ) -> [PRHit] {
        guard !set.isWarmup && set.weightKg > 0 && set.reps > 0 else { return [] }

        var hits: [PRHit] = []
        let exerciseRecords = existingRecords.filter {
            if let ex = exercise, let recEx = $0.exercise {
                return ex.id == recEx.id
            }
            return $0.exerciseName.lowercased() == exerciseName.lowercased()
        }

        // 1. Max Weight PR
        let maxWeightRecord = exerciseRecords.first { $0.recordType == .maxWeight }
        let currentMaxWeight = maxWeightRecord?.value ?? 0.0
        if set.weightKg > currentMaxWeight {
            hits.append(PRHit(
                exerciseId: exercise?.id,
                exerciseName: exerciseName,
                recordType: .maxWeight,
                oldValue: currentMaxWeight,
                newValue: set.weightKg,
                displayText: "\(exerciseName): \(format(set.weightKg))kg (Previous: \(format(currentMaxWeight))kg)"
            ))
        }

        // 2. Max Estimated 1RM PR
        let maxE1RMRecord = exerciseRecords.first { $0.recordType == .maxE1RM }
        let currentMaxE1RM = maxE1RMRecord?.value ?? 0.0
        if set.e1RM > currentMaxE1RM && set.e1RM > set.weightKg {
            hits.append(PRHit(
                exerciseId: exercise?.id,
                exerciseName: exerciseName,
                recordType: .maxE1RM,
                oldValue: currentMaxE1RM,
                newValue: set.e1RM,
                displayText: "\(exerciseName) e1RM: \(format(set.e1RM))kg (Previous: \(format(currentMaxE1RM))kg)"
            ))
        }

        // 3. Max Reps at this weight
        let weightRecords = exerciseRecords.filter { $0.recordType == .maxReps && abs(($0.weightAtReps ?? 0) - set.weightKg) < 0.1 }
        let currentMaxReps = weightRecords.map(\.value).max() ?? 0.0
        if Double(set.reps) > currentMaxReps && currentMaxReps > 0 {
            hits.append(PRHit(
                exerciseId: exercise?.id,
                exerciseName: exerciseName,
                recordType: .maxReps,
                oldValue: currentMaxReps,
                newValue: Double(set.reps),
                displayText: "\(exerciseName): \(set.reps) reps at \(format(set.weightKg))kg"
            ))
        }

        return hits
    }

    private static func format(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(val))"
        }
        return String(format: "%.1f", val)
    }
}
