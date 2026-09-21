import Foundation
import SwiftData

@Model
public final class BodyMetric {
    public var id: UUID = UUID()
    public var date: Date = Date()
    public var weightKg: Double = 70.0
    public var bodyFatPct: Double?
    public var notes: String = ""
    public var measurementsData: Data?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        weightKg: Double = 70.0,
        bodyFatPct: Double? = nil,
        notes: String = "",
        measurements: [String: Double] = [:]
    ) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.bodyFatPct = bodyFatPct
        self.notes = notes
        self.measurements = measurements
    }

    public var measurements: [String: Double] {
        get {
            guard let data = measurementsData else { return [:] }
            return (try? JSONDecoder().decode([String: Double].self, from: data)) ?? [:]
        }
        set {
            measurementsData = try? JSONEncoder().encode(newValue)
        }
    }
}
