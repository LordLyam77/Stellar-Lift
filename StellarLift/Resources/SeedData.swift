import Foundation
import SwiftData

public struct SeedExerciseDTO: Codable {
    public let name: String
    public let muscleGroup: String
    public let equipment: String
    public let isUnilateral: Bool
    public let defaultRepRangeLow: Int
    public let defaultRepRangeHigh: Int
    public let notes: String
}

@MainActor
public enum SeedData {
    public static func seedDatabaseIfNeeded(context: ModelContext) {
        seedEquipmentProfileIfNeeded(context: context)
        seedExercisesIfNeeded(context: context)
        seedDefaultSplitsAndScheduleIfNeeded(context: context)
    }

    public static func seedEquipmentProfileIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<EquipmentProfile>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if existing.isEmpty {
            let defaultProfile = EquipmentProfile()
            context.insert(defaultProfile)
            try? context.save()
        }
    }

    public static func seedExercisesIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Exercise>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        // Attempt reading from bundled JSON
        var dtos: [SeedExerciseDTO] = []
        if let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([SeedExerciseDTO].self, from: data) {
            dtos = decoded
        } else {
            // Fallback hardcoded initial list if bundle URL is inaccessible
            dtos = fallbackExercises
        }

        for dto in dtos {
            let mg = MuscleGroup(rawValue: dto.muscleGroup) ?? .chest
            let eq = EquipmentType(rawValue: dto.equipment) ?? .barbell
            let exercise = Exercise(
                name: dto.name,
                muscleGroup: mg,
                equipment: eq,
                isUnilateral: dto.isUnilateral,
                defaultRepRangeLow: dto.defaultRepRangeLow,
                defaultRepRangeHigh: dto.defaultRepRangeHigh,
                notes: dto.notes
            )
            context.insert(exercise)
        }
        try? context.save()
    }

    public static func seedDefaultSplitsAndScheduleIfNeeded(context: ModelContext) {
        let splitDescriptor = FetchDescriptor<SplitDay>()
        let existingSplits = (try? context.fetch(splitDescriptor)) ?? []
        guard existingSplits.isEmpty else { return }

        // Fetch all seeded exercises to assign to split days
        let exerciseDescriptor = FetchDescriptor<Exercise>()
        let allExercises = (try? context.fetch(exerciseDescriptor)) ?? []
        let exerciseMap = Dictionary(grouping: allExercises, by: { $0.name })

        func findExercise(_ name: String) -> Exercise? {
            exerciseMap[name]?.first
        }

        // 1. Create Default PPL x2 Splits
        let pushA = SplitDay(name: "Push A", colorHex: "#7C5CFF", orderIndex: 0)
        let pullA = SplitDay(name: "Pull A", colorHex: "#38E8FF", orderIndex: 1)
        let legsA = SplitDay(name: "Legs A", colorHex: "#FF6AD5", orderIndex: 2)
        let pushB = SplitDay(name: "Push B", colorHex: "#8B5CF6", orderIndex: 3)
        let pullB = SplitDay(name: "Pull B", colorHex: "#06B6D4", orderIndex: 4)
        let legsB = SplitDay(name: "Legs B", colorHex: "#EC4899", orderIndex: 5)
        let rest = SplitDay(name: "Rest Day", colorHex: "#64748B", orderIndex: 6, isCardioDay: false, notes: "Rest and recovery")

        let splitDays = [pushA, pullA, legsA, pushB, pullB, legsB, rest]
        for split in splitDays {
            context.insert(split)
        }

        // Attach planned exercises to Push A
        let pushAExercises: [(String, Int, Int, Int, Int)] = [
            ("Barbell Bench Press", 4, 6, 8, 150),
            ("Incline Dumbbell Press", 3, 8, 12, 120),
            ("Dumbbell Lateral Raise", 4, 12, 15, 90),
            ("Close-Grip Bench Press", 3, 8, 10, 120),
            ("Tricep Rope Pushdown", 3, 10, 15, 60)
        ]
        for (idx, item) in pushAExercises.enumerated() {
            if let ex = findExercise(item.0) {
                let planned = PlannedExercise(
                    exercise: ex,
                    targetSets: item.1,
                    targetRepLow: item.2,
                    targetRepHigh: item.3,
                    restSeconds: item.4,
                    orderIndex: idx,
                    splitDay: pushA
                )
                context.insert(planned)
            }
        }

        // Attach planned exercises to Pull A
        let pullAExercises: [(String, Int, Int, Int, Int)] = [
            ("Barbell Deadlift", 3, 5, 5, 180),
            ("Lat Pulldown", 4, 8, 12, 120),
            ("Seated Cable Row", 3, 8, 12, 90),
            ("Face Pull", 4, 15, 20, 60),
            ("Barbell Bicep Curl", 3, 8, 12, 90),
            ("Hammer Curl", 3, 10, 12, 60)
        ]
        for (idx, item) in pullAExercises.enumerated() {
            if let ex = findExercise(item.0) {
                let planned = PlannedExercise(
                    exercise: ex,
                    targetSets: item.1,
                    targetRepLow: item.2,
                    targetRepHigh: item.3,
                    restSeconds: item.4,
                    orderIndex: idx,
                    splitDay: pullA
                )
                context.insert(planned)
            }
        }

        // Attach planned exercises to Legs A
        let legsAExercises: [(String, Int, Int, Int, Int)] = [
            ("Barbell Back Squat", 4, 6, 8, 180),
            ("Romanian Deadlift (Barbell)", 3, 8, 10, 120),
            ("Leg Press", 3, 10, 12, 120),
            ("Lying Leg Curl Machine", 3, 10, 15, 90),
            ("Standing Calf Raise Machine", 4, 12, 15, 60)
        ]
        for (idx, item) in legsAExercises.enumerated() {
            if let ex = findExercise(item.0) {
                let planned = PlannedExercise(
                    exercise: ex,
                    targetSets: item.1,
                    targetRepLow: item.2,
                    targetRepHigh: item.3,
                    restSeconds: item.4,
                    orderIndex: idx,
                    splitDay: legsA
                )
                context.insert(planned)
            }
        }

        // Attach planned exercises to Push B
        let pushBExercises: [(String, Int, Int, Int, Int)] = [
            ("Overhead Barbell Press", 4, 6, 8, 150),
            ("Dumbbell Bench Press", 4, 8, 12, 120),
            ("Chest Dips", 3, 8, 12, 90),
            ("Cable Lateral Raise", 4, 12, 15, 60),
            ("Skull Crusher (EZ Bar)", 3, 10, 12, 90)
        ]
        for (idx, item) in pushBExercises.enumerated() {
            if let ex = findExercise(item.0) {
                let planned = PlannedExercise(
                    exercise: ex,
                    targetSets: item.1,
                    targetRepLow: item.2,
                    targetRepHigh: item.3,
                    restSeconds: item.4,
                    orderIndex: idx,
                    splitDay: pushB
                )
                context.insert(planned)
            }
        }

        // Attach planned exercises to Pull B
        let pullBExercises: [(String, Int, Int, Int, Int)] = [
            ("Pull-Up", 4, 6, 10, 150),
            ("Barbell Bent-Over Row", 4, 8, 10, 120),
            ("One-Arm Dumbbell Row", 3, 8, 12, 90),
            ("Reverse Pec Deck Fly", 3, 12, 15, 60),
            ("Incline Dumbbell Curl", 3, 10, 12, 60)
        ]
        for (idx, item) in pullBExercises.enumerated() {
            if let ex = findExercise(item.0) {
                let planned = PlannedExercise(
                    exercise: ex,
                    targetSets: item.1,
                    targetRepLow: item.2,
                    targetRepHigh: item.3,
                    restSeconds: item.4,
                    orderIndex: idx,
                    splitDay: pullB
                )
                context.insert(planned)
            }
        }

        // Attach planned exercises to Legs B
        let legsBExercises: [(String, Int, Int, Int, Int)] = [
            ("Barbell Front Squat", 4, 6, 8, 150),
            ("Barbell Hip Thrust", 4, 8, 12, 120),
            ("Bulgarian Split Squat", 3, 8, 12, 90),
            ("Seated Leg Curl Machine", 3, 10, 15, 90),
            ("Seated Calf Raise Machine", 4, 15, 20, 60)
        ]
        for (idx, item) in legsBExercises.enumerated() {
            if let ex = findExercise(item.0) {
                let planned = PlannedExercise(
                    exercise: ex,
                    targetSets: item.1,
                    targetRepLow: item.2,
                    targetRepHigh: item.3,
                    restSeconds: item.4,
                    orderIndex: idx,
                    splitDay: legsB
                )
                context.insert(planned)
            }
        }

        // 2. Initialize Default 7-day Weekly Schedule (Mon-Sun)
        // Calendar weekday: 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat, 1=Sun
        let scheduleMapping: [(Int, SplitDay)] = [
            (2, pushA),  // Monday
            (3, pullA),  // Tuesday
            (4, legsA),  // Wednesday
            (5, pushB),  // Thursday
            (6, pullB),  // Friday
            (7, legsB),  // Saturday
            (1, rest)    // Sunday
        ]

        for (day, split) in scheduleMapping {
            let sched = WeeklySchedule(
                dayOfWeek: day,
                splitDay: split,
                reminderTimeHour: 8,
                reminderTimeMinute: 0,
                isReminderEnabled: true
            )
            context.insert(sched)
        }

        try? context.save()
    }

    private static var fallbackExercises: [SeedExerciseDTO] {
        [
            SeedExerciseDTO(name: "Barbell Bench Press", muscleGroup: "chest", equipment: "barbell", isUnilateral: false, defaultRepRangeLow: 6, defaultRepRangeHigh: 10, notes: "Retract scapula"),
            SeedExerciseDTO(name: "Incline Dumbbell Press", muscleGroup: "chest", equipment: "dumbbell", isUnilateral: true, defaultRepRangeLow: 8, defaultRepRangeHigh: 12, notes: "30 deg incline"),
            SeedExerciseDTO(name: "Barbell Deadlift", muscleGroup: "back", equipment: "barbell", isUnilateral: false, defaultRepRangeLow: 5, defaultRepRangeHigh: 5, notes: "Neutral spine"),
            SeedExerciseDTO(name: "Lat Pulldown", muscleGroup: "back", equipment: "cable", isUnilateral: false, defaultRepRangeLow: 8, defaultRepRangeHigh: 12, notes: "Drive elbows down"),
            SeedExerciseDTO(name: "Barbell Back Squat", muscleGroup: "quads", equipment: "barbell", isUnilateral: false, defaultRepRangeLow: 6, defaultRepRangeHigh: 8, notes: "Parallel depth"),
            SeedExerciseDTO(name: "Overhead Barbell Press", muscleGroup: "shoulders", equipment: "barbell", isUnilateral: false, defaultRepRangeLow: 6, defaultRepRangeHigh: 10, notes: "Tight glutes")
        ]
    }
}
