import Foundation

public struct PlateLoadingResult: Equatable, Sendable {
    public let targetWeightKg: Double
    public let barWeightKg: Double
    public let weightPerSideKg: Double
    public let platesPerSide: [Double]
    public let isExact: Bool
    public let remainderKg: Double

    public init(
        targetWeightKg: Double,
        barWeightKg: Double,
        weightPerSideKg: Double,
        platesPerSide: [Double],
        isExact: Bool,
        remainderKg: Double
    ) {
        self.targetWeightKg = targetWeightKg
        self.barWeightKg = barWeightKg
        self.weightPerSideKg = weightPerSideKg
        self.platesPerSide = platesPerSide
        self.isExact = isExact
        self.remainderKg = remainderKg
    }
}

public enum EquipmentMath {
    /// Calculate exact plate distribution per side for a given barbell weight
    public static func calculatePlates(
        targetWeightKg: Double,
        barWeightKg: Double = 20.0,
        availablePlatesKg: [Double] = [1.25, 2.5, 5.0, 10.0, 15.0, 20.0, 25.0]
    ) -> PlateLoadingResult {
        guard targetWeightKg > barWeightKg else {
            return PlateLoadingResult(
                targetWeightKg: targetWeightKg,
                barWeightKg: barWeightKg,
                weightPerSideKg: 0.0,
                platesPerSide: [],
                isExact: targetWeightKg == barWeightKg,
                remainderKg: max(0, barWeightKg - targetWeightKg)
            )
        }

        let neededPerSide = (targetWeightKg - barWeightKg) / 2.0
        var remaining = neededPerSide
        var chosenPlates: [Double] = []

        // Greedy match with available plates descending
        let sortedPlates = availablePlatesKg.sorted(by: >)
        for plate in sortedPlates {
            while remaining >= plate - 0.001 {
                chosenPlates.append(plate)
                remaining -= plate
            }
        }

        let isExact = remaining < 0.01
        return PlateLoadingResult(
            targetWeightKg: targetWeightKg,
            barWeightKg: barWeightKg,
            weightPerSideKg: neededPerSide,
            platesPerSide: chosenPlates,
            isExact: isExact,
            remainderKg: remaining * 2.0
        )
    }

    /// Check if target weight can be loaded symmetrically on a barbell with available plates
    public static func isLoadableOnBarbell(
        targetWeightKg: Double,
        barWeightKg: Double = 20.0,
        availablePlatesKg: [Double] = [1.25, 2.5, 5.0, 10.0, 15.0, 20.0, 25.0]
    ) -> Bool {
        if targetWeightKg == barWeightKg { return true }
        guard targetWeightKg > barWeightKg else { return false }
        let result = calculatePlates(targetWeightKg: targetWeightKg, barWeightKg: barWeightKg, availablePlatesKg: availablePlatesKg)
        return result.isExact
    }

    /// Calculate next available weight jump strictly respecting user equipment
    public static func nextAvailableWeight(
        above currentWeightKg: Double,
        for equipment: EquipmentType,
        profile: EquipmentProfile
    ) -> Double {
        switch equipment {
        case .dumbbell:
            let sortedRack = profile.availableDumbbellsKg.sorted()
            if let next = sortedRack.first(where: { $0 > currentWeightKg + 0.01 }) {
                return next
            }
            return currentWeightKg + 2.5

        case .barbell:
            let smallestJump = max(profile.smallestBarbellJumpKg, 0.5)
            var candidate = currentWeightKg + smallestJump
            // Search up to 50 increments to find next valid loadable weight
            for _ in 0..<50 {
                if isLoadableOnBarbell(
                    targetWeightKg: candidate,
                    barWeightKg: profile.barbellWeightKg,
                    availablePlatesKg: profile.availablePlatesKg
                ) {
                    return candidate
                }
                candidate += smallestJump
            }
            return currentWeightKg + smallestJump

        case .machine, .cable:
            let increment = max(profile.machineIncrementKg, 1.0)
            let quotient = floor(currentWeightKg / increment)
            let candidate = (quotient + 1) * increment
            return candidate > currentWeightKg ? candidate : currentWeightKg + increment

        case .bodyweight:
            // Bodyweight increment (added load, e.g. weight belt)
            return currentWeightKg > 0 ? currentWeightKg + 2.5 : 2.5

        case .smith:
            let smallestJump = max(profile.smallestBarbellJumpKg, 1.25)
            return currentWeightKg + smallestJump

        case .other:
            return currentWeightKg + 2.5
        }
    }
}
