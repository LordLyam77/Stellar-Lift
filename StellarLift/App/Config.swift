import Foundation
import SwiftData

public enum Config {
    /// Clearly marked flag for free provisioning profile compatibility.
    /// Free profiles do not support CloudKit sync entitlements.
    public static let iCloudSyncEnabled: Bool = false

    /// Live Activity rest timer support flag (requires paid developer profile).
    public static let liveActivityEnabled: Bool = false

    /// App identity
    public static let appName = "Stellar Lift"
    public static let appVersion = "1.0.0"
    public static let appBuild = "1"

    /// Create ModelContainer with appropriate schema and configuration
    @MainActor
    public static func createModelContainer() -> ModelContainer {
        let schema = Schema([
            Exercise.self,
            SplitDay.self,
            PlannedExercise.self,
            WeeklySchedule.self,
            WorkoutSession.self,
            PerformedExercise.self,
            SetEntry.self,
            BodyMetric.self,
            EquipmentProfile.self,
            PersonalRecord.self,
            WorkoutTemplate.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: iCloudSyncEnabled ? .automatic : .none
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return container
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }
}
