import Foundation
import SwiftData

@Model
public final class SplitDay {
    public var id: UUID = UUID()
    public var name: String = ""
    public var colorHex: String = "#7C5CFF"
    public var orderIndex: Int = 0
    public var isCardioDay: Bool = false
    public var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \PlannedExercise.splitDay)
    public var plannedExercises: [PlannedExercise] = []

    @Relationship(inverse: \WorkoutSession.splitDay)
    public var sessions: [WorkoutSession]? = []

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#7C5CFF",
        orderIndex: Int = 0,
        isCardioDay: Bool = false,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.orderIndex = orderIndex
        self.isCardioDay = isCardioDay
        self.notes = notes
    }

    public var sortedPlannedExercises: [PlannedExercise] {
        plannedExercises.sorted { $0.orderIndex < $1.orderIndex }
    }
}

@Model
public final class PlannedExercise {
    public var id: UUID = UUID()
    public var targetSets: Int = 3
    public var targetRepLow: Int = 8
    public var targetRepHigh: Int = 12
    public var restSeconds: Int = 90
    public var orderIndex: Int = 0
    public var supersetGroup: String?

    public var splitDay: SplitDay?
    public var exercise: Exercise?

    public init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        targetSets: Int = 3,
        targetRepLow: Int = 8,
        targetRepHigh: Int = 12,
        restSeconds: Int = 90,
        orderIndex: Int = 0,
        supersetGroup: String? = nil,
        splitDay: SplitDay? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.targetSets = targetSets
        self.targetRepLow = targetRepLow
        self.targetRepHigh = targetRepHigh
        self.restSeconds = restSeconds
        self.orderIndex = orderIndex
        self.supersetGroup = supersetGroup
        self.splitDay = splitDay
    }
}
