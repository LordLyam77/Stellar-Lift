import Foundation
import SwiftData

@Model
public final class EquipmentProfile {
    public var id: UUID = UUID()
    public var availableDumbbellsKg: [Double] = [
        2.5, 5.0, 7.5, 10.0, 12.5, 15.0, 17.5, 20.0, 22.5, 25.0,
        27.5, 30.0, 32.5, 35.0, 37.5, 40.0, 42.5, 45.0, 47.5, 50.0
    ]
    public var barbellWeightKg: Double = 20.0
    public var availablePlatesKg: [Double] = [1.25, 2.5, 5.0, 10.0, 15.0, 20.0, 25.0]
    public var machineIncrementKg: Double = 5.0
    public var smallestBarbellJumpKg: Double = 2.5
    public var useLbs: Bool = false

    public init(
        id: UUID = UUID(),
        availableDumbbellsKg: [Double] = [
            2.5, 5.0, 7.5, 10.0, 12.5, 15.0, 17.5, 20.0, 22.5, 25.0,
            27.5, 30.0, 32.5, 35.0, 37.5, 40.0, 42.5, 45.0, 47.5, 50.0
        ],
        barbellWeightKg: Double = 20.0,
        availablePlatesKg: [Double] = [1.25, 2.5, 5.0, 10.0, 15.0, 20.0, 25.0],
        machineIncrementKg: Double = 5.0,
        smallestBarbellJumpKg: Double = 2.5,
        useLbs: Bool = false
    ) {
        self.id = id
        self.availableDumbbellsKg = availableDumbbellsKg.sorted()
        self.barbellWeightKg = barbellWeightKg
        self.availablePlatesKg = availablePlatesKg.sorted()
        self.machineIncrementKg = machineIncrementKg
        self.smallestBarbellJumpKg = smallestBarbellJumpKg
        self.useLbs = useLbs
    }

    public static var defaultProfile: EquipmentProfile {
        EquipmentProfile()
    }
}
