import SwiftUI
import SwiftData

public struct BuiltInTemplate: Identifiable {
    public let id = UUID()
    public let name: String
    public let description: String
    public let daysCount: String
    public let splits: [TemplateSplitDay]
}

public struct TemplateSplitDay {
    public let name: String
    public let colorHex: String
    public let isCardio: Bool
    public let exerciseNames: [String]
}

public struct TemplatesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [Exercise]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    public let templates: [BuiltInTemplate] = [
        BuiltInTemplate(
            name: "Push / Pull / Legs (PPL ×2)",
            description: "The classic 6-day hypertrophy powerhouse with 1 dedicated rest day.",
            daysCount: "6 Lifting Days + 1 Rest Day",
            splits: [
                TemplateSplitDay(name: "Push A", colorHex: "#7C5CFF", isCardio: false, exerciseNames: ["Barbell Bench Press", "Incline Dumbbell Press", "Dumbbell Lateral Raise", "Close-Grip Bench Press", "Tricep Rope Pushdown"]),
                TemplateSplitDay(name: "Pull A", colorHex: "#38E8FF", isCardio: false, exerciseNames: ["Barbell Deadlift", "Lat Pulldown", "Seated Cable Row", "Face Pull", "Barbell Bicep Curl"]),
                TemplateSplitDay(name: "Legs A", colorHex: "#FF6AD5", isCardio: false, exerciseNames: ["Barbell Back Squat", "Romanian Deadlift (Barbell)", "Leg Press", "Lying Leg Curl Machine", "Standing Calf Raise Machine"]),
                TemplateSplitDay(name: "Push B", colorHex: "#8B5CF6", isCardio: false, exerciseNames: ["Overhead Barbell Press", "Dumbbell Bench Press", "Chest Dips", "Cable Lateral Raise", "Skull Crusher (EZ Bar)"]),
                TemplateSplitDay(name: "Pull B", colorHex: "#06B6D4", isCardio: false, exerciseNames: ["Pull-Up", "Barbell Bent-Over Row", "One-Arm Dumbbell Row", "Reverse Pec Deck Fly", "Incline Dumbbell Curl"]),
                TemplateSplitDay(name: "Legs B", colorHex: "#EC4899", isCardio: false, exerciseNames: ["Barbell Front Squat", "Barbell Hip Thrust", "Bulgarian Split Squat", "Seated Leg Curl Machine", "Seated Calf Raise Machine"]),
                TemplateSplitDay(name: "Rest Day", colorHex: "#64748B", isCardio: false, exerciseNames: [])
            ]
        ),
        BuiltInTemplate(
            name: "Arnold Split (Antagonist ×2)",
            description: "Chest & Back, Shoulders & Arms, Legs twice a week for maximum volume and pump.",
            daysCount: "6 Lifting Days + 1 Rest Day",
            splits: [
                TemplateSplitDay(name: "Chest & Back A", colorHex: "#7C5CFF", isCardio: false, exerciseNames: ["Barbell Bench Press", "Barbell Bent-Over Row", "Incline Dumbbell Press", "Lat Pulldown", "Dumbbell Pullover"]),
                TemplateSplitDay(name: "Shoulders & Arms A", colorHex: "#38E8FF", isCardio: false, exerciseNames: ["Overhead Barbell Press", "Dumbbell Lateral Raise", "Barbell Bicep Curl", "Skull Crusher (EZ Bar)", "Hammer Curl", "Tricep Rope Pushdown"]),
                TemplateSplitDay(name: "Legs A", colorHex: "#FF6AD5", isCardio: false, exerciseNames: ["Barbell Back Squat", "Romanian Deadlift (Barbell)", "Leg Extension Machine", "Lying Leg Curl Machine", "Standing Calf Raise Machine"]),
                TemplateSplitDay(name: "Chest & Back B", colorHex: "#8B5CF6", isCardio: false, exerciseNames: ["Incline Barbell Bench Press", "Pull-Up", "Dumbbell Bench Press", "Seated Cable Row", "Cable Chest Fly"]),
                TemplateSplitDay(name: "Shoulders & Arms B", colorHex: "#06B6D4", isCardio: false, exerciseNames: ["Seated Dumbbell Shoulder Press", "Face Pull", "Preacher Curl (EZ Bar)", "Close-Grip Bench Press", "Incline Dumbbell Curl"]),
                TemplateSplitDay(name: "Legs B", colorHex: "#EC4899", isCardio: false, exerciseNames: ["Barbell Front Squat", "Barbell Hip Thrust", "Leg Press", "Seated Leg Curl Machine", "Seated Calf Raise Machine"]),
                TemplateSplitDay(name: "Rest Day", colorHex: "#64748B", isCardio: false, exerciseNames: [])
            ]
        ),
        BuiltInTemplate(
            name: "Upper / Lower (×3)",
            description: "High frequency alternating upper and lower sessions for steady strength progression.",
            daysCount: "6 Days (3 Upper + 3 Lower)",
            splits: [
                TemplateSplitDay(name: "Upper A", colorHex: "#7C5CFF", isCardio: false, exerciseNames: ["Barbell Bench Press", "Barbell Bent-Over Row", "Overhead Barbell Press", "Lat Pulldown", "Tricep Rope Pushdown"]),
                TemplateSplitDay(name: "Lower A", colorHex: "#38E8FF", isCardio: false, exerciseNames: ["Barbell Back Squat", "Romanian Deadlift (Barbell)", "Leg Press", "Standing Calf Raise Machine", "Hanging Leg Raise"]),
                TemplateSplitDay(name: "Upper B", colorHex: "#8B5CF6", isCardio: false, exerciseNames: ["Incline Dumbbell Press", "Pull-Up", "Dumbbell Lateral Raise", "Seated Cable Row", "Barbell Bicep Curl"]),
                TemplateSplitDay(name: "Lower B", colorHex: "#06B6D4", isCardio: false, exerciseNames: ["Barbell Front Squat", "Barbell Hip Thrust", "Lying Leg Curl Machine", "Seated Calf Raise Machine", "Ab Wheel Rollout"]),
                TemplateSplitDay(name: "Upper C", colorHex: "#FF6AD5", isCardio: false, exerciseNames: ["Chest Dips", "Chest-Supported T-Bar Row", "Arnold Press", "Hammer Curl", "Cable Chest Fly"]),
                TemplateSplitDay(name: "Lower C", colorHex: "#EC4899", isCardio: false, exerciseNames: ["Hack Squat", "Dumbbell Romanian Deadlift", "Bulgarian Split Squat", "Leg Extension Machine", "Plank"]),
                TemplateSplitDay(name: "Rest Day", colorHex: "#64748B", isCardio: false, exerciseNames: [])
            ]
        ),
        BuiltInTemplate(
            name: "Bro Split + Cardio",
            description: "Chest, Back, Shoulders, Arms, Legs, and dedicated Zone 2 cardio.",
            daysCount: "5 Lifting + 1 Cardio + 1 Rest",
            splits: [
                TemplateSplitDay(name: "Chest Day", colorHex: "#7C5CFF", isCardio: false, exerciseNames: ["Barbell Bench Press", "Incline Dumbbell Press", "Cable Chest Fly", "Pec Deck Machine", "Chest Dips"]),
                TemplateSplitDay(name: "Back Day", colorHex: "#38E8FF", isCardio: false, exerciseNames: ["Barbell Deadlift", "Barbell Bent-Over Row", "Lat Pulldown", "Seated Cable Row", "Face Pull"]),
                TemplateSplitDay(name: "Shoulders Day", colorHex: "#8B5CF6", isCardio: false, exerciseNames: ["Overhead Barbell Press", "Dumbbell Lateral Raise", "Arnold Press", "Cable Lateral Raise", "Reverse Pec Deck Fly"]),
                TemplateSplitDay(name: "Legs Day", colorHex: "#FF6AD5", isCardio: false, exerciseNames: ["Barbell Back Squat", "Leg Press", "Romanian Deadlift (Barbell)", "Lying Leg Curl Machine", "Standing Calf Raise Machine"]),
                TemplateSplitDay(name: "Arms Day", colorHex: "#EC4899", isCardio: false, exerciseNames: ["Barbell Bicep Curl", "Close-Grip Bench Press", "Hammer Curl", "Tricep Rope Pushdown", "Incline Dumbbell Curl", "Skull Crusher (EZ Bar)"]),
                TemplateSplitDay(name: "Cardio Day", colorHex: "#10B981", isCardio: true, exerciseNames: ["Incline Treadmill Walk", "Rowing Machine"]),
                TemplateSplitDay(name: "Rest Day", colorHex: "#64748B", isCardio: false, exerciseNames: [])
            ]
        )
    ]

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        Text("Select a proven routine to import into your splits and weekly schedule.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        ForEach(templates) { template in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name)
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(selectedTheme.textPrimary)

                                        Text(template.daysCount)
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundColor(selectedTheme.secondaryAccent)
                                    }
                                    Spacer()
                                }

                                Text(template.description)
                                    .font(.system(size: 13, weight: .regular, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)

                                // Mini preview badges
                                FlowLayout(spacing: 6) {
                                    ForEach(template.splits, id: \.name) { split in
                                        Text(split.name)
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(hex: split.colorHex).opacity(0.2))
                                            .foregroundColor(Color(hex: split.colorHex))
                                            .clipShape(Capsule())
                                    }
                                }

                                Button {
                                    applyTemplate(template)
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.down.fill")
                                        Text("Import Template")
                                    }
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(selectedTheme.primaryAccent)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                                .padding(.top, 4)
                            }
                            .padding(18)
                            .glassCard(cornerRadius: 20, strokeColor: selectedTheme.primaryAccent.opacity(0.3))
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Routine Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(selectedTheme.secondaryAccent)
                }
            }
        }
    }

    private func applyTemplate(_ template: BuiltInTemplate) {
        let exerciseMap = Dictionary(grouping: allExercises, by: { $0.name.lowercased() })

        // Clear existing planned exercises and split days
        let splitFetch = FetchDescriptor<SplitDay>()
        if let existingSplits = try? modelContext.fetch(splitFetch) {
            for split in existingSplits {
                modelContext.delete(split)
            }
        }

        var createdSplits: [SplitDay] = []
        for (index, splitData) in template.splits.enumerated() {
            let splitDay = SplitDay(
                name: splitData.name,
                colorHex: splitData.colorHex,
                orderIndex: index,
                isCardioDay: splitData.isCardio
            )
            modelContext.insert(splitDay)
            createdSplits.append(splitDay)

            for (exIndex, exName) in splitData.exerciseNames.enumerated() {
                let matchedEx = exerciseMap[exName.lowercased()]?.first
                let planned = PlannedExercise(
                    exercise: matchedEx,
                    targetSets: 3,
                    targetRepLow: matchedEx?.defaultRepRangeLow ?? 8,
                    targetRepHigh: matchedEx?.defaultRepRangeHigh ?? 12,
                    restSeconds: 90,
                    orderIndex: exIndex,
                    splitDay: splitDay
                )
                modelContext.insert(planned)
            }
        }

        // Map onto WeeklySchedule Mon-Sun
        let schedFetch = FetchDescriptor<WeeklySchedule>()
        let existingSchedules = (try? modelContext.fetch(schedFetch)) ?? []
        // Calendar days: 2=Mon, 3=Tue, 4=Wed, 5=Thu, 6=Fri, 7=Sat, 1=Sun
        let weekdayKeys = [2, 3, 4, 5, 6, 7, 1]

        for (idx, weekday) in weekdayKeys.enumerated() {
            let assignedSplit = idx < createdSplits.count ? createdSplits[idx] : nil
            if let existing = existingSchedules.first(where: { $0.dayOfWeek == weekday }) {
                existing.splitDay = assignedSplit
            } else {
                let newSched = WeeklySchedule(dayOfWeek: weekday, splitDay: assignedSplit)
                modelContext.insert(newSched)
            }
        }

        try? modelContext.save()
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)
        dismiss()
    }
}

public struct FlowLayout: Layout {
    public var spacing: CGFloat = 8

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeightInRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            x += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
        height = y + maxHeightInRow
        return CGSize(width: width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeightInRow: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += maxHeightInRow + spacing
                maxHeightInRow = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            maxHeightInRow = max(maxHeightInRow, size.height)
        }
    }
}
