import SwiftUI
import SwiftData
import Charts

public struct MuscleVolumeData: Identifiable {
    public let id = UUID()
    public let muscleGroup: String
    public let sets: Int
    public let color: Color
}

public struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @Query(sort: \BodyMetric.date, order: .reverse) private var bodyMetrics: [BodyMetric]
    @Query private var allExercises: [Exercise]
    @Query private var personalRecords: [PersonalRecord]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var showingAddWeightSheet: Bool = false
    @State private var newWeightKg: Double = 75.0
    @State private var newBodyFatPct: Double = 15.0

    // Calendar Heatmap: Past 60 days
    public var past60Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<56).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
    }

    public var finishedSessions: [WorkoutSession] {
        allSessions.filter { $0.isFinished }
    }

    // Streak calculation
    public var currentStreak: Int {
        let calendar = Calendar.current
        let sessionDays = Set(finishedSessions.map { calendar.startOfDay(for: $0.date) })
        var streak = 0
        var checkDay = calendar.startOfDay(for: Date())

        // If today has no workout, start checking from yesterday
        if !sessionDays.contains(checkDay) {
            if let yesterday = calendar.date(byAdding: .day, value: -1, to: checkDay), sessionDays.contains(yesterday) {
                checkDay = yesterday
            } else {
                return 0
            }
        }

        while sessionDays.contains(checkDay) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
            checkDay = prev
        }
        return streak
    }

    // Sessions per week average (over last 4 weeks)
    public var sessionsPerWeekAverage: Double {
        let fourWeeksAgo = Date().addingTimeInterval(-86400 * 28)
        let recentCount = finishedSessions.filter { $0.date >= fourWeeksAgo }.count
        return Double(recentCount) / 4.0
    }

    // Muscle Volume Data for the current week
    public var currentWeekMuscleVolume: [MuscleVolumeData] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else { return [] }

        let weekSessions = finishedSessions.filter { $0.date >= weekStart }
        var muscleSetCounts: [MuscleGroup: Int] = [:]

        for s in weekSessions {
            for perf in s.performedExercises {
                if let mg = perf.exercise?.muscleGroup {
                    let count = perf.workingSets.count
                    muscleSetCounts[mg, default: 0] += count
                }
            }
        }

        let mainGroups: [MuscleGroup] = [.chest, .back, .shoulders, .biceps, .triceps, .quads, .hamstrings, .glutes, .calves, .abs]
        let colors = [
            selectedTheme.primaryAccent,
            selectedTheme.secondaryAccent,
            selectedTheme.tertiaryAccent,
            Color(hex: "#4ADE80"),
            Color(hex: "#FBBF24"),
            Color(hex: "#FB7185"),
            Color(hex: "#8B5CF6"),
            Color(hex: "#06B6D4"),
            Color(hex: "#EC4899"),
            Color(hex: "#10B981")
        ]

        return mainGroups.enumerated().map { idx, mg in
            MuscleVolumeData(
                muscleGroup: mg.displayName,
                sets: muscleSetCounts[mg] ?? 0,
                color: colors[idx % colors.count]
            )
        }.filter { $0.sets > 0 }
    }

    // Strength Constellation Nodes
    public var constellationNodes: [ConstellationNode] {
        let groups: [(String, MuscleGroup, String)] = [
            ("Chest", .chest, "shield.fill"),
            ("Back", .back, "arrow.triangle.swap"),
            ("Shoulders", .shoulders, "figure.arms.open"),
            ("Arms", .biceps, "figure.strengthtraining.traditional"),
            ("Quads", .quads, "figure.walk"),
            ("Posterior", .hamstrings, "figure.run")
        ]

        return groups.map { label, mg, icon in
            // Compute relative strength based on best e1RM or volume
            let relevantPRs = personalRecords.filter { $0.exercise?.muscleGroup == mg && $0.recordType == .maxWeight }
            let maxWeight = relevantPRs.map(\.value).max() ?? 0.0

            // Baseline normalization (e.g. 100kg benchmark)
            let normalized = min(max(maxWeight / 120.0, 0.25), 1.0)

            return ConstellationNode(
                id: label,
                name: label,
                score: normalized,
                icon: icon
            )
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Quick Stats Header (Streak & Avg)
                        quickStatsBar

                        // Signature Feature: Strength Constellation
                        constellationCard

                        // Star Heatmap Calendar
                        galaxyHeatmapCard

                        // Weekly Volume Stacked Bars
                        weeklyVolumeCard

                        // Bodyweight Line Chart & Logger
                        bodyweightCard

                        // Shortcuts (PR Wall & History Search)
                        shortcutsSection
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Cosmic Progress")
            .sheet(isPresented: $showingAddWeightSheet) {
                addWeightSheet
            }
        }
    }

    // Quick Stats Bar
    private var quickStatsBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundColor(selectedTheme.warningStalled)
                VStack(alignment: .leading, spacing: 1) {
                    Text("\(currentStreak) DAYS")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(selectedTheme.textPrimary)
                    Text("ACTIVE STREAK")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glassCard(cornerRadius: 16)

            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(selectedTheme.secondaryAccent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(String(format: "%.1f / wk", sessionsPerWeekAverage))
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(selectedTheme.textPrimary)
                    Text("4-WK AVERAGE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .glassCard(cornerRadius: 16)
        }
        .padding(.horizontal, 20)
    }

    // Signature Strength Constellation
    private var constellationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("STRENGTH CONSTELLATION")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(selectedTheme.secondaryAccent)
                        .tracking(1.5)
                    Text("Relative Muscle Power")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundColor(selectedTheme.secondaryAccent)
            }

            StrengthConstellationView(nodes: constellationNodes)
                .frame(height: 250)
                .padding(.vertical, 8)
        }
        .padding(20)
        .glassCard(cornerRadius: 22, strokeColor: selectedTheme.primaryAccent.opacity(0.4), glowing: true, glowColor: selectedTheme.primaryAccent.opacity(0.15))
        .padding(.horizontal, 20)
    }

    // Galaxy Heatmap Calendar
    private var galaxyHeatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("STAR MAP ACTIVITY (8 WEEKS)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .tracking(1.2)
                Spacer()
                Text("\(finishedSessions.count) Total Logged")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(selectedTheme.secondaryAccent)
            }

            // Grid of stars (7 rows x 8 columns)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 8)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(past60Days, id: \.self) { date in
                    let dayVolume = volumeForDay(date)
                    let isToday = Calendar.current.isDateInToday(date)

                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(heatmapColor(volume: dayVolume))
                            .frame(height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isToday ? selectedTheme.secondaryAccent : Color.clear, lineWidth: 1.5)
                            )

                        if dayVolume > 0 {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 3, height: 3)
                                .shadow(color: .white, radius: 2)
                        }
                    }
                }
            }
            .padding(.vertical, 4)

            // Heatmap Legend
            HStack(spacing: 8) {
                Text("Less")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)

                ForEach([0, 1500, 3000, 6000, 10000], id: \.self) { v in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatmapColor(volume: Double(v)))
                        .frame(width: 14, height: 10)
                }

                Text("More")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)

                Spacer()
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 20)
    }

    // Weekly Volume Stacked Bars
    private var weeklyVolumeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WEEKLY HARD SETS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                        .tracking(1.2)
                    Text("Volume by Muscle Group")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)
                }
                Spacer()
            }

            if currentWeekMuscleVolume.isEmpty {
                VStack(spacing: 6) {
                    Text("No working sets recorded this week.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(selectedTheme.textMuted)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(currentWeekMuscleVolume) { item in
                    BarMark(
                        x: .value("Muscle", item.muscleGroup),
                        y: .value("Sets", item.sets)
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(6)
                }
                .frame(height: 160)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .foregroundStyle(selectedTheme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(selectedTheme.stroke.opacity(0.5))
                        AxisValueLabel()
                            .foregroundStyle(selectedTheme.textSecondary)
                    }
                }

                // Volume threshold cues (<8 low, >22 excessive)
                HStack(spacing: 6) {
                    Circle().fill(selectedTheme.warningStalled).frame(width: 6, height: 6)
                    Text("Target 8–22 working sets per muscle group weekly.")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 20)
    }

    // Bodyweight Line Chart & Logger
    private var bodyweightCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BODY COMPOSITION")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                        .tracking(1.2)
                    if let latest = bodyMetrics.first {
                        Text("\(String(format: "%.1f", latest.weightKg)) kg")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(selectedTheme.textPrimary)
                    } else {
                        Text("No weigh-ins yet")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                    }
                }
                Spacer()
                Button {
                    showingAddWeightSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Log Weight")
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.secondaryAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(selectedTheme.surfaceCard)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(selectedTheme.stroke, lineWidth: 1))
                }
            }

            if !bodyMetrics.isEmpty {
                Chart(bodyMetrics.prefix(15).reversed()) { metric in
                    LineMark(
                        x: .value("Date", metric.date),
                        y: .value("Weight", metric.weightKg)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(selectedTheme.primaryAccent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Date", metric.date),
                        y: .value("Weight", metric.weightKg)
                    )
                    .foregroundStyle(selectedTheme.secondaryAccent)
                }
                .frame(height: 130)
                .chartYScale(domain: .automatic(includesZero: false))
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 20)
    }

    // Shortcuts Section (PR Wall & History Search)
    private var shortcutsSection: some View {
        VStack(spacing: 12) {
            NavigationLink {
                PRWallView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(selectedTheme.successPR)
                        .frame(width: 28)
                    Text("PR Constellation Wall")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedTheme.textMuted)
                }
                .padding(16)
                .glassCard(cornerRadius: 16)
            }

            NavigationLink {
                HistorySearchView()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(selectedTheme.secondaryAccent)
                        .frame(width: 28)
                    Text("Search Workout History")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedTheme.textMuted)
                }
                .padding(16)
                .glassCard(cornerRadius: 16)
            }
        }
        .padding(.horizontal, 20)
    }

    private var addWeightSheet: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("BODYWEIGHT (KG)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)

                        HStack {
                            TextField("Weight in kg", value: $newWeightKg, format: .number)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .monospacedDigit()
                                .keyboardType(.decimalPad)
                                .foregroundColor(selectedTheme.textPrimary)
                            Text("kg")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.secondaryAccent)
                        }
                    }
                    .padding(20)
                    .glassCard(cornerRadius: 18)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    StellarPrimaryButton("Save Entry", icon: "checkmark") {
                        let metric = BodyMetric(date: Date(), weightKg: newWeightKg, bodyFatPct: newBodyFatPct)
                        modelContext.insert(metric)
                        try? modelContext.save()
                        showingAddWeightSheet = false
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Log Bodyweight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddWeightSheet = false }
                        .foregroundColor(selectedTheme.secondaryAccent)
                }
            }
        }
    }

    private func volumeForDay(_ date: Date) -> Double {
        let calendar = Calendar.current
        let matching = finishedSessions.filter { calendar.isDate($0.date, inSameDayAs: date) }
        return matching.reduce(0) { $0 + $1.totalVolumeKg }
    }

    private func heatmapColor(volume: Double) -> Color {
        if volume == 0 {
            return selectedTheme.surfaceCard.opacity(0.3)
        } else if volume < 2000 {
            return selectedTheme.primaryAccent.opacity(0.35)
        } else if volume < 4500 {
            return selectedTheme.primaryAccent.opacity(0.65)
        } else if volume < 7500 {
            return selectedTheme.secondaryAccent.opacity(0.8)
        } else {
            return selectedTheme.tertiaryAccent
        }
    }
}
