import XCTest
@testable import StellarLift

final class ProgressionAnalyzerTests: XCTestCase {
    var profile: EquipmentProfile!

    override func setUp() {
        super.setUp()
        profile = EquipmentProfile(
            availableDumbbellsKg: [10, 12.5, 15, 17.5, 20, 22.5, 25, 27.5, 30],
            barbellWeightKg: 20.0,
            availablePlatesKg: [1.25, 2.5, 5, 10, 15, 20, 25],
            machineIncrementKg: 5.0,
            smallestBarbellJumpKg: 2.5
        )
    }

    func testNewExerciseVerdictWithLessThanTwoSessions() {
        let history = [
            ExerciseSessionMetrics(
                date: Date().addingTimeInterval(-86400),
                topSetWeightKg: 20,
                topSetReps: 8,
                bestE1RM: 25.3,
                totalVolumeKg: 480,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            )
        ]

        let insight = ProgressionAnalyzer.evaluate(
            exerciseName: "Incline DB Press",
            equipment: .dumbbell,
            targetRepLow: 8,
            targetRepHigh: 12,
            history: history,
            profile: profile
        )

        XCTAssertEqual(insight.verdict, .newExercise)
        XCTAssertTrue(insight.message.contains("Log a couple more sessions"))
    }

    func testReadyToProgressWhenMaxingRepRangeAcrossWorkingSets() {
        let now = Date()
        let history = [
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 7),
                topSetWeightKg: 20,
                topSetReps: 10,
                bestE1RM: 26.6,
                totalVolumeKg: 600,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            ),
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 3),
                topSetWeightKg: 20,
                topSetReps: 12,
                bestE1RM: 28.0,
                totalVolumeKg: 720,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: true // Hit 12 reps on all sets!
            )
        ]

        let insight = ProgressionAnalyzer.evaluate(
            exerciseName: "Incline DB Press",
            equipment: .dumbbell,
            targetRepLow: 8,
            targetRepHigh: 12,
            history: history,
            profile: profile,
            now: now
        )

        XCTAssertEqual(insight.verdict, .readyToProgress)
        XCTAssertEqual(insight.suggestedWeightKg, 22.5) // Next DB in rack!
        XCTAssertTrue(insight.message.contains("maxed the rep range"))
    }

    func testProgressingVerdictWhenWeightIncreases() {
        let now = Date()
        let history = [
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 5),
                topSetWeightKg: 60,
                topSetReps: 8,
                bestE1RM: 76.0,
                totalVolumeKg: 1440,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            ),
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 1),
                topSetWeightKg: 62.5,
                topSetReps: 8,
                bestE1RM: 79.1,
                totalVolumeKg: 1500,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            )
        ]

        let insight = ProgressionAnalyzer.evaluate(
            exerciseName: "Barbell Bench Press",
            equipment: .barbell,
            targetRepLow: 6,
            targetRepHigh: 10,
            history: history,
            profile: profile,
            now: now
        )

        XCTAssertEqual(insight.verdict, .progressing)
        XCTAssertTrue(insight.message.contains("Up 2.5kg from last time"))
    }

    func testGrindingVerdictWhenRepsAreClimbingInsideRange() {
        let now = Date()
        let history = [
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 8),
                topSetWeightKg: 20,
                topSetReps: 8,
                bestE1RM: 25.3,
                totalVolumeKg: 480,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            ),
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 4),
                topSetWeightKg: 20,
                topSetReps: 9,
                bestE1RM: 26.0,
                totalVolumeKg: 540,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            ),
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 1),
                topSetWeightKg: 20,
                topSetReps: 10,
                bestE1RM: 26.6,
                totalVolumeKg: 600,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            )
        ]

        let insight = ProgressionAnalyzer.evaluate(
            exerciseName: "Incline DB Press",
            equipment: .dumbbell,
            targetRepLow: 8,
            targetRepHigh: 12,
            history: history,
            profile: profile,
            now: now
        )

        XCTAssertEqual(insight.verdict, .grinding)
        XCTAssertTrue(insight.message.contains("8 → 9 → 10"))
    }

    func testStalledVerdictWhenNoImprovementAcrossThreeSessions() {
        let now = Date()
        let history = [
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 10),
                topSetWeightKg: 80,
                topSetReps: 6,
                bestE1RM: 96.0,
                totalVolumeKg: 1440,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            ),
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 6),
                topSetWeightKg: 80,
                topSetReps: 6,
                bestE1RM: 96.0,
                totalVolumeKg: 1440,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            ),
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 2),
                topSetWeightKg: 80,
                topSetReps: 6,
                bestE1RM: 96.0,
                totalVolumeKg: 1440,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            )
        ]

        let insight = ProgressionAnalyzer.evaluate(
            exerciseName: "Barbell Squat",
            equipment: .barbell,
            targetRepLow: 6,
            targetRepHigh: 10,
            history: history,
            profile: profile,
            now: now
        )

        XCTAssertEqual(insight.verdict, .stalled)
        XCTAssertNotNil(insight.stalledOptions)
        XCTAssertEqual(insight.stalledOptions?.count, 4)
    }

    func testStagnantLongVerdictWhenOver21DaysAtSameWeight() {
        let now = Date()
        let history = [
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 25), // 25 days ago
                topSetWeightKg: 20,
                topSetReps: 8,
                bestE1RM: 25.3,
                totalVolumeKg: 480,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            ),
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 2),
                topSetWeightKg: 20,
                topSetReps: 8,
                bestE1RM: 25.3,
                totalVolumeKg: 480,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            )
        ]

        let insight = ProgressionAnalyzer.evaluate(
            exerciseName: "Incline DB Press",
            equipment: .dumbbell,
            targetRepLow: 8,
            targetRepHigh: 12,
            history: history,
            profile: profile,
            now: now
        )

        XCTAssertEqual(insight.verdict, .stagnantLong)
        XCTAssertEqual(insight.suggestedWeightKg, 22.5)
        XCTAssertTrue(insight.message.contains("Incline DB Press has been 20kg"))
    }

    func testRegressingVerdictWhenE1RMDownFivePercent() {
        let now = Date()
        let history = [
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 10),
                topSetWeightKg: 100,
                topSetReps: 8,
                bestE1RM: 126.6, // 100 * (1 + 8/30)
                totalVolumeKg: 2400,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            ),
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 5),
                topSetWeightKg: 95,
                topSetReps: 8,
                bestE1RM: 120.3,
                totalVolumeKg: 2280,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            ),
            ExerciseSessionMetrics(
                date: now.addingTimeInterval(-86400 * 1),
                topSetWeightKg: 90,
                topSetReps: 8,
                bestE1RM: 114.0, // down > 9%
                totalVolumeKg: 2160,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            )
        ]

        let insight = ProgressionAnalyzer.evaluate(
            exerciseName: "Barbell Deadlift",
            equipment: .barbell,
            targetRepLow: 6,
            targetRepHigh: 10,
            history: history,
            profile: profile,
            now: now
        )

        XCTAssertEqual(insight.verdict, .regressing)
        XCTAssertTrue(insight.message.contains("Numbers are sliding"))
    }

    func testDeloadDetectorTriggersAtFortyPercentStalledOrRegressing() {
        let insights = [
            ProgressionInsight(exerciseName: "Squat", verdict: .stalled, message: "", currentWeightKg: 100),
            ProgressionInsight(exerciseName: "Bench", verdict: .stagnantLong, message: "", currentWeightKg: 80),
            ProgressionInsight(exerciseName: "Deadlift", verdict: .progressing, message: "", currentWeightKg: 140),
            ProgressionInsight(exerciseName: "Press", verdict: .progressing, message: "", currentWeightKg: 50),
            ProgressionInsight(exerciseName: "Row", verdict: .grinding, message: "", currentWeightKg: 70)
        ]
        // 2 out of 5 = 40%
        XCTAssertTrue(ProgressionAnalyzer.shouldRecommendDeload(insights: insights))
    }
}
