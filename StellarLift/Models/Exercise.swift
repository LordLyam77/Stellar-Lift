import Foundation
import SwiftData

public enum MuscleGroup: String, Codable, CaseIterable, Identifiable, Sendable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case quads
    case hamstrings
    case glutes
    case calves
    case abs
    case forearms
    case cardio
    case fullBody

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .calves: return "Calves"
        case .abs: return "Abs"
        case .forearms: return "Forearms"
        case .cardio: return "Cardio"
        case .fullBody: return "Full Body"
        }
    }

    public var iconName: String {
        switch self {
        case .chest: return "shield.fill"
        case .back: return "arrow.triangle.swap"
        case .shoulders: return "figure.arms.open"
        case .biceps: return "figure.strengthtraining.traditional"
        case .triceps: return "bolt.fill"
        case .quads: return "figure.walk"
        case .hamstrings: return "figure.run"
        case .glutes: return "flame.fill"
        case .calves: return "shoeprints.fill"
        case .abs: return "square.grid.2x2.fill"
        case .forearms: return "hand.raised.fill"
        case .cardio: return "heart.fill"
        case .fullBody: return "sparkles"
        }
    }
}

public enum EquipmentType: String, Codable, CaseIterable, Identifiable, Sendable {
    case barbell
    case dumbbell
    case machine
    case cable
    case bodyweight
    case smith
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .machine: return "Machine"
        case .cable: return "Cable"
        case .bodyweight: return "Bodyweight"
        case .smith: return "Smith Machine"
        case .other: return "Other"
        }
    }

    public var iconName: String {
        switch self {
        case .barbell: return "scalemass.fill"
        case .dumbbell: return "dumbbell.fill"
        case .machine: return "gearshape.2.fill"
        case .cable: return "point.topleft.down.curvedto.point.bottomright.up"
        case .bodyweight: return "figure.walk"
        case .smith: return "line.horizontal.3.decrease.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

@Model
public final class Exercise {
    public var id: UUID = UUID()
    public var name: String = ""
    public var muscleGroupRaw: String = MuscleGroup.chest.rawValue
    public var equipmentRaw: String = EquipmentType.barbell.rawValue
    public var isUnilateral: Bool = false
    public var defaultRepRangeLow: Int = 8
    public var defaultRepRangeHigh: Int = 12
    public var notes: String = ""
    public var isArchived: Bool = false
    public var createdAt: Date = Date()
    public var variationExerciseIds: [UUID] = []

    @Relationship(inverse: \PlannedExercise.exercise)
    public var plannedExercises: [PlannedExercise]? = []

    @Relationship(inverse: \PerformedExercise.exercise)
    public var performedExercises: [PerformedExercise]? = []

    @Relationship(deleteRule: .cascade, inverse: \PersonalRecord.exercise)
    public var personalRecords: [PersonalRecord]? = []

    public init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup,
        equipment: EquipmentType,
        isUnilateral: Bool = false,
        defaultRepRangeLow: Int = 8,
        defaultRepRangeHigh: Int = 12,
        notes: String = "",
        isArchived: Bool = false,
        createdAt: Date = Date(),
        variationExerciseIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.equipmentRaw = equipment.rawValue
        self.isUnilateral = isUnilateral
        self.defaultRepRangeLow = defaultRepRangeLow
        self.defaultRepRangeHigh = defaultRepRangeHigh
        self.notes = notes
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.variationExerciseIds = variationExerciseIds
    }

    public var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .chest }
        set { muscleGroupRaw = newValue.rawValue }
    }

    public var equipment: EquipmentType {
        get { EquipmentType(rawValue: equipmentRaw) ?? .other }
        set { equipmentRaw = newValue.rawValue }
    }
}
