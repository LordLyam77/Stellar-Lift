import XCTest
@testable import StellarLift

final class EquipmentMathTests: XCTestCase {
    var profile: EquipmentProfile!

    override func setUp() {
        super.setUp()
        profile = EquipmentProfile(
            availableDumbbellsKg: [2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20, 22.5, 25, 30],
            barbellWeightKg: 20.0,
            availablePlatesKg: [1.25, 2.5, 5, 10, 15, 20, 25],
            machineIncrementKg: 5.0,
            smallestBarbellJumpKg: 2.5
        )
    }

    func testPlateCalculatorForStandardBarbellLoads() {
        // 100kg total = 20kg bar + 40kg per side (25 + 15)
        let result100 = EquipmentMath.calculatePlates(
            targetWeightKg: 100.0,
            barWeightKg: 20.0,
            availablePlatesKg: [1.25, 2.5, 5, 10, 15, 20, 25]
        )
        XCTAssertTrue(result100.isExact)
        XCTAssertEqual(result100.weightPerSideKg, 40.0)
        XCTAssertEqual(result100.platesPerSide, [25.0, 15.0])
        XCTAssertEqual(result100.remainderKg, 0.0)

        // 62.5kg total = 20kg bar + 21.25kg per side (20 + 1.25)
        let result62 = EquipmentMath.calculatePlates(
            targetWeightKg: 62.5,
            barWeightKg: 20.0,
            availablePlatesKg: [1.25, 2.5, 5, 10, 15, 20, 25]
        )
        XCTAssertTrue(result62.isExact)
        XCTAssertEqual(result62.weightPerSideKg, 21.25)
        XCTAssertEqual(result62.platesPerSide, [20.0, 1.25])
    }

    func testDumbbellNextAvailableWeightRespectsAvailableRack() {
        // Current: 20kg -> Next must be 22.5kg, never 21kg!
        let next = EquipmentMath.nextAvailableWeight(above: 20.0, for: .dumbbell, profile: profile)
        XCTAssertEqual(next, 22.5)

        // 25kg -> 30kg (since 27.5 is not in this custom rack)
        let nextFrom25 = EquipmentMath.nextAvailableWeight(above: 25.0, for: .dumbbell, profile: profile)
        XCTAssertEqual(nextFrom25, 30.0)
    }

    func testBarbellNextAvailableWeightRespectsSmallestJumpAndSymmetricPlates() {
        // Current: 60kg on 20kg bar with 2.5kg smallest jump (2 x 1.25kg plates)
        let next = EquipmentMath.nextAvailableWeight(above: 60.0, for: .barbell, profile: profile)
        XCTAssertEqual(next, 62.5)
    }

    func testMachineNextAvailableWeightRespectsIncrement() {
        // Machine at 42.5kg with 5kg increment -> next is 45.0kg
        let next = EquipmentMath.nextAvailableWeight(above: 42.5, for: .machine, profile: profile)
        XCTAssertEqual(next, 45.0)

        // Machine at 40kg -> next is 45kg
        let nextFrom40 = EquipmentMath.nextAvailableWeight(above: 40.0, for: .machine, profile: profile)
        XCTAssertEqual(nextFrom40, 45.0)
    }
}
