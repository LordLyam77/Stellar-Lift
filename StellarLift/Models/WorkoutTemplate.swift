import Foundation
import SwiftData

public struct TemplateExerciseItem: Codable, Identifiable, Sendable {
    public var id: UUID = UUID()
    public var exerciseId: UUID
    public var exerciseName: String
    public var targetSets: Int
    public var targetRepLow: Int
    public var targetRepHigh: Int
    public var restSeconds: Int
    public var orderIndex: Int

    public init(
        id: UUID = UUID(),
        exerciseId: UUID,
        exerciseName: String,
        targetSets: Int = 3,
        targetRepLow: Int = 8,
        targetRepHigh: Int = 12,
        restSeconds: Int = 90,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.targetSets = targetSets
        self.targetRepLow = targetRepLow
        self.targetRepHigh = targetRepHigh
        self.restSeconds = restSeconds
        self.orderIndex = orderIndex
    }
}

@Model
public final class WorkoutTemplate {
    public var id: UUID = UUID()
    public var name: String = ""
    public var notes: String = ""
    public var createdAt: Date = Date()
    public var exercisesData: Data?

    public init(
        id: UUID = UUID(),
        name: String,
        notes: String = "",
        createdAt: Date = Date(),
        items: [TemplateExerciseItem] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.items = items
    }

    public var items: [TemplateExerciseItem] {
        get {
            guard let data = exercisesData else { return [] }
            return (try? JSONDecoder().decode([TemplateExerciseItem].self, from: data)) ?? []
        }
        set {
            exercisesData = try? JSONEncoder().encode(newValue)
        }
    }
}
