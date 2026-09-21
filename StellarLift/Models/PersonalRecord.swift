import Foundation
import SwiftData

public enum RecordType: String, Codable, CaseIterable, Sendable {
    case maxWeight
    case maxReps
    case maxE1RM
    case maxVolume

    public var displayName: String {
        switch self {
        case .maxWeight: return "Max Weight"
        case .maxReps: return "Max Reps"
        case .maxE1RM: return "Estimated 1RM"
        case .maxVolume: return "Max Volume"
        }
    }

    public var unitSuffix: String {
        switch self {
        case .maxWeight, .maxE1RM, .maxVolume: return "kg"
        case .maxReps: return "reps"
        }
    }

    public var iconName: String {
        switch self {
        case .maxWeight: return "scalemass.fill"
        case .maxReps: return "repeat"
        case .maxE1RM: return "bolt.fill"
        case .maxVolume: return "chart.bar.fill"
        }
    }
}

@Model
public final class PersonalRecord {
    public var id: UUID = UUID()
    public var exerciseName: String = ""
    public var typeRaw: String = RecordType.maxWeight.rawValue
    public var value: Double = 0.0
    public var date: Date = Date()
    public var sessionId: UUID?
    public var repsAtWeight: Int?
    public var weightAtReps: Double?

    public var exercise: Exercise?

    public init(
        id: UUID = UUID(),
        exercise: Exercise? = nil,
        exerciseName: String = "",
        type: RecordType = .maxWeight,
        value: Double = 0.0,
        date: Date = Date(),
        sessionId: UUID? = nil,
        repsAtWeight: Int? = nil,
        weightAtReps: Double? = nil
    ) {
        self.id = id
        self.exercise = exercise
        self.exerciseName = exercise?.name ?? exerciseName
        self.typeRaw = type.rawValue
        self.value = value
        self.date = date
        self.sessionId = sessionId
        self.repsAtWeight = repsAtWeight
        self.weightAtReps = weightAtReps
    }

    public var recordType: RecordType {
        get { RecordType(rawValue: typeRaw) ?? .maxWeight }
        set { typeRaw = newValue.rawValue }
    }
}
