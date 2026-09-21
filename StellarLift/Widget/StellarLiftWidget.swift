import WidgetKit
import SwiftUI

public struct WorkoutWidgetEntry: TimelineEntry {
    public let date: Date
    public let todaySplitName: String
    public let plannedExerciseNames: [String]
    public let isRestDay: Bool

    public init(
        date: Date,
        todaySplitName: String = "Push Day",
        plannedExerciseNames: [String] = ["Barbell Bench Press", "Incline DB Press", "Lateral Raise", "Tricep Pushdown"],
        isRestDay: Bool = false
    ) {
        self.date = date
        self.todaySplitName = todaySplitName
        self.plannedExerciseNames = plannedExerciseNames
        self.isRestDay = isRestDay
    }
}

public struct StellarLiftWidgetProvider: TimelineProvider {
    public func placeholder(in context: Context) -> WorkoutWidgetEntry {
        WorkoutWidgetEntry(date: Date())
    }

    public func getSnapshot(in context: Context, completion: @escaping (WorkoutWidgetEntry) -> Void) {
        completion(WorkoutWidgetEntry(date: Date()))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutWidgetEntry>) -> Void) {
        // Timeline refresh daily at midnight
        let entry = WorkoutWidgetEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date().addingTimeInterval(3600)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

public struct StellarLiftWidgetEntryView: View {
    public var entry: StellarLiftWidgetProvider.Entry

    public var body: some View {
        ZStack {
            // Dark galactic background
            Color(hex: "#05060F")
                .ignoresSafeArea()

            // Nebula glow
            RadialGradient(
                gradient: Gradient(colors: [Color(hex: "#7C5CFF").opacity(0.35), Color.clear]),
                center: .topLeading,
                startRadius: 5,
                endRadius: 120
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(hex: "#38E8FF"))
                        Text("STELLAR LIFT")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#38E8FF"))
                            .tracking(1.0)
                    }
                    Spacer()
                    Text(entry.date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#9AA0C8"))
                }

                if entry.isRestDay {
                    Text("Rest & Recovery")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("Protein & joint recovery day.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color(hex: "#9AA0C8"))
                } else {
                    Text(entry.todaySplitName)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(entry.plannedExerciseNames.prefix(3), id: \.self) { ex in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: "#7C5CFF"))
                                    .frame(width: 4, height: 4)
                                Text(ex)
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color(hex: "#EDEFFF"))
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(14)
        }
    }
}

public struct StellarLiftWidget: Widget {
    public let kind: String = "StellarLiftWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StellarLiftWidgetProvider()) { entry in
            StellarLiftWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today's Workout")
        .description("Glance at today's split and planned exercises.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
