import Foundation
import SwiftData

@Model
public final class WorkoutSession {
    public var id: UUID = UUID()
    public var date: Date = Date()
    public var splitDayName: String = ""
    public var notes: String = ""
    public var startedAt: Date = Date()
    public var endedAt: Date?
    public var isFinished: Bool = false
    public var bodyweightKg: Double?
    public var sessionRpe: Double?
    public var moodEnergy: Int? // 1...5

    public var splitDay: SplitDay?

    @Relationship(deleteRule: .cascade, inverse: \PerformedExercise.session)
    public var performedExercises: [PerformedExercise] = []

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        splitDay: SplitDay? = nil,
        splitDayName: String = "",
        notes: String = "",
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        isFinished: Bool = false,
        bodyweightKg: Double? = nil,
        sessionRpe: Double? = nil,
        moodEnergy: Int? = nil
    ) {
        self.id = id
        self.date = date
        self.splitDay = splitDay
        self.splitDayName = splitDay?.name ?? splitDayName
        self.notes = notes
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.isFinished = isFinished
        self.bodyweightKg = bodyweightKg
        self.sessionRpe = sessionRpe
        self.moodEnergy = moodEnergy
    }

    public var sortedPerformedExercises: [PerformedExercise] {
        performedExercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    public var totalVolumeKg: Double {
        performedExercises.reduce(0) { $0 + $1.totalVolumeKg }
    }

    public var totalSetsCount: Int {
        performedExercises.reduce(0) { $0 + $1.sets.count }
    }

    public var totalWorkingSetsCount: Int {
        performedExercises.reduce(0) { $0 + $1.workingSets.count }
    }

    public var durationSeconds: TimeInterval {
        let end = endedAt ?? Date()
        return max(0, end.timeIntervalSince(startedAt))
    }
}

@Model
public final class PerformedExercise {
    public var id: UUID = UUID()
    public var exerciseName: String = ""
    public var orderIndex: Int = 0
    public var notes: String = ""

    public var session: WorkoutSession?
    public var exercise: Exercise?

    @Relationship(deleteRule: .cascade, inverse: \SetEntry.performedExercise)
    public var sets: [SetEntry] = []

    public init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        exerciseName: String = "",
        orderIndex: Int = 0,
        notes: String = "",
        session: WorkoutSession? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.exerciseName = exercise?.name ?? exerciseName
        self.orderIndex = orderIndex
        self.notes = notes
        self.session = session
    }

    public var sortedSets: [SetEntry] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    public var workingSets: [SetEntry] {
        sortedSets.filter { !$0.isWarmup }
    }

    public var topSetWeightKg: Double {
        workingSets.map(\.weightKg).max() ?? 0.0
    }

    public var topSetReps: Int {
        guard let topSet = workingSets.max(by: { a, b in
            if a.weightKg != b.weightKg {
                return a.weightKg < b.weightKg
            }
            return a.reps < b.reps
        }) else { return 0 }
        return topSet.reps
    }

    public var bestE1RM: Double {
        workingSets.map(\.e1RM).max() ?? 0.0
    }

    public var totalVolumeKg: Double {
        sets.reduce(0) { $0 + $1.volumeKg }
    }
}

@Model
public final class SetEntry {
    public var id: UUID = UUID()
    public var setNumber: Int = 1
    public var weightKg: Double = 0.0
    public var reps: Int = 0
    public var rpe: Double? // 6.0 - 10.0 in 0.5 steps
    public var isWarmup: Bool = false
    public var isDropSet: Bool = false
    public var isFailure: Bool = false
    public var completedAt: Date = Date()

    public var performedExercise: PerformedExercise?

    public init(
        id: UUID = UUID(),
        setNumber: Int = 1,
        weightKg: Double = 0.0,
        reps: Int = 0,
        rpe: Double? = nil,
        isWarmup: Bool = false,
        isDropSet: Bool = false,
        isFailure: Bool = false,
        completedAt: Date = Date(),
        performedExercise: PerformedExercise? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.rpe = rpe
        self.isWarmup = isWarmup
        self.isDropSet = isDropSet
        self.isFailure = isFailure
        self.completedAt = completedAt
        self.performedExercise = performedExercise
    }

    public var volumeKg: Double {
        return weightKg * Double(reps)
    }

    /// Epley formula: weight * (1 + reps/30), capped at reps <= 12 for reliable strength calculation
    public var e1RM: Double {
        guard weightKg > 0 && reps > 0 else { return 0.0 }
        let effectiveReps = min(Double(reps), 12.0)
        return weightKg * (1.0 + (effectiveReps / 30.0))
    }
}
