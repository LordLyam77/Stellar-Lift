import SwiftUI
import SwiftData
import Charts

public struct ExerciseHistoryPoint: Identifiable {
    public let id = UUID()
    public let date: Date
    public let topWeightKg: Double
    public let e1RM: Double
    public let volumeKg: Double
    public let topReps: Int
}

public struct ExerciseDetailView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @Query private var equipmentProfiles: [EquipmentProfile]
    @Query private var personalRecords: [PersonalRecord]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var selectedMetricTab: Int = 0 // 0: e1RM, 1: Top Weight, 2: Volume
    @State private var showingEditSheet: Bool = false

    public var profile: EquipmentProfile {
        equipmentProfiles.first ?? EquipmentProfile.defaultProfile
    }

    public var historyPoints: [ExerciseHistoryPoint] {
        var points: [ExerciseHistoryPoint] = []
        let finished = allSessions.filter { $0.isFinished }.sorted { $0.date < $1.date }

        for session in finished {
            if let match = session.performedExercises.first(where: { $0.exercise?.id == exercise.id }) {
                let workingSets = match.sets.filter { !$0.isWarmup }
                if !workingSets.isEmpty {
                    let maxWeight = workingSets.map(\.weightKg).max() ?? 0
                    let bestReps = workingSets.filter { $0.weightKg == maxWeight }.map(\.reps).max() ?? 0
                    let bestE1RM = workingSets.map(\.e1RM).max() ?? 0
                    let vol = workingSets.reduce(0) { $0 + $1.volumeKg }

                    points.append(ExerciseHistoryPoint(
                        date: session.date,
                        topWeightKg: maxWeight,
                        e1RM: bestE1RM,
                        volumeKg: vol,
                        topReps: bestReps
                    ))
                }
            }
        }
        return points
    }

    public var exercisePRs: [PersonalRecord] {
        personalRecords.filter {
            if let recEx = $0.exercise {
                return recEx.id == exercise.id
            }
            return $0.exerciseName.lowercased() == exercise.name.lowercased()
        }
    }

    public var progressionInsight: ProgressionInsight {
        let metrics = historyPoints.map {
            ExerciseSessionMetrics(
                date: $0.date,
                topSetWeightKg: $0.topWeightKg,
                topSetReps: $0.topReps,
                bestE1RM: $0.e1RM,
                totalVolumeKg: $0.volumeKg,
                workingSetsCount: 3,
                allWorkingSetsHitRepHigh: false
            )
        }
        return ProgressionAnalyzer.evaluate(
            exerciseName: exercise.name,
            exerciseId: exercise.id,
            equipment: exercise.equipment,
            targetRepLow: exercise.defaultRepRangeLow,
            targetRepHigh: exercise.defaultRepRangeHigh,
            history: metrics,
            profile: profile
        )
    }

    public var body: some View {
        ZStack {
            StarfieldBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header & Tags
                    headerSection

                    // Progression Verdict Card
                    verdictCard

                    // Interactive Progression Chart (Swift Charts)
                    chartsSection

                    // All-Time Personal Records
                    personalRecordsSection

                    // Training Cues & Form Notes
                    cuesSection

                    // Session History Log
                    historySection
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
                .foregroundColor(selectedTheme.secondaryAccent)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            ExerciseEditView(exercise: exercise)
        }
    }

    // Header & Tags
    private var headerSection: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: exercise.muscleGroup.iconName)
                Text(exercise.muscleGroup.displayName)
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(selectedTheme.secondaryAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(selectedTheme.secondaryAccent.opacity(0.15))
            .clipShape(Capsule())

            HStack(spacing: 6) {
                Image(systemName: exercise.equipment.iconName)
                Text(exercise.equipment.displayName)
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(selectedTheme.primaryAccent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(selectedTheme.primaryAccent.opacity(0.15))
            .clipShape(Capsule())

            Spacer()

            Text("Rep Range: \(exercise.defaultRepRangeLow)–\(exercise.defaultRepRangeHigh)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
        }
        .padding(.horizontal, 20)
    }

    // Verdict Card
    private var verdictCard: some View {
        let insight = progressionInsight
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: insight.verdict.badgeColorHex))
                        .frame(width: 8, height: 8)
                    Text(insight.verdict.title.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: insight.verdict.badgeColorHex))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(hex: insight.verdict.badgeColorHex).opacity(0.15))
                .clipShape(Capsule())

                Spacer()

                if let days = insight.daysAtCurrentWeight, days > 0 {
                    Text("\(days) days at weight")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedTheme.textMuted)
                }
            }

            Text(insight.message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(selectedTheme.textPrimary)

            if let options = insight.stalledOptions {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BREAKTHROUGH TACTICS:")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.warningStalled)
                        .padding(.top, 4)

                    ForEach(options, id: \.self) { opt in
                        HStack(alignment: .top, spacing: 6) {
                            Text("•").foregroundColor(selectedTheme.warningStalled)
                            Text(opt)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .glassCard(
            cornerRadius: 18,
            strokeColor: Color(hex: insight.verdict.badgeColorHex).opacity(0.5),
            glowing: insight.verdict == .stagnantLong,
            glowColor: Color(hex: insight.verdict.badgeColorHex).opacity(0.3)
        )
        .padding(.horizontal, 20)
    }

    // Charts Section (Swift Charts)
    private var chartsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Segmented Picker
            Picker("", selection: $selectedMetricTab) {
                Text("Estimated 1RM").tag(0)
                Text("Top Weight").tag(1)
                Text("Volume").tag(2)
            }
            .pickerStyle(.segmented)

            // Chart Container
            if historyPoints.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28))
                        .foregroundColor(selectedTheme.textMuted)
                    Text("No session history logged yet.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                Chart {
                    ForEach(historyPoints) { point in
                        let value = selectedMetricTab == 0 ? point.e1RM : (selectedMetricTab == 1 ? point.topWeightKg : point.volumeKg)

                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", value)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(selectedMetricTab == 0 ? selectedTheme.secondaryAccent : (selectedMetricTab == 1 ? selectedTheme.primaryAccent : selectedTheme.tertiaryAccent))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(Color.white)
                        .symbolSize(30)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    (selectedMetricTab == 0 ? selectedTheme.secondaryAccent : selectedTheme.primaryAccent).opacity(0.25),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(selectedTheme.stroke.opacity(0.6))
                        AxisTick()
                            .foregroundStyle(selectedTheme.stroke)
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .foregroundStyle(selectedTheme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(selectedTheme.stroke.opacity(0.6))
                        AxisValueLabel()
                            .foregroundStyle(selectedTheme.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 20)
    }

    // Personal Records Section
    private var personalRecordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ALL-TIME PERSONAL RECORDS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                prTile(type: .maxWeight)
                prTile(type: .maxE1RM)
                prTile(type: .maxReps)
                prTile(type: .maxVolume)
            }
        }
        .padding(.horizontal, 20)
    }

    private func prTile(type: RecordType) -> some View {
        let matching = exercisePRs.filter { $0.recordType == type }.sorted { $0.value > $1.value }.first

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: type.iconName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(selectedTheme.successPR)
                Text(type.displayName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
            }

            if let pr = matching {
                Text("\(formatNumber(pr.value)) \(type.unitSuffix)")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(selectedTheme.textPrimary)
                Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)
            } else {
                Text("—")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)
                Text("Not yet set")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 14)
    }

    // Form Cues Section
    private var cuesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TECHNIQUE CUES & SETUP")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            TextField("Add cues (e.g. elbows tucked 45°, seat on notch 3)...", text: $exercise.notes, axis: .vertical)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(selectedTheme.textPrimary)
                .padding(14)
                .glassCard(cornerRadius: 16)
                .onChange(of: exercise.notes) { _, _ in
                    try? modelContext.save()
                }
        }
        .padding(.horizontal, 20)
    }

    // Session History
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SESSION LOGS (\(historyPoints.count))")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
                .tracking(1.2)
                .padding(.horizontal, 4)

            if historyPoints.isEmpty {
                Text("No past logs for this lift.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: 14)
            } else {
                ForEach(historyPoints.reversed()) { pt in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pt.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textPrimary)
                            Text("e1RM: \(formatNumber(pt.e1RM))kg • Vol: \(Int(pt.volumeKg))kg")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                        }
                        Spacer()
                        Text("\(formatNumber(pt.topWeightKg))kg × \(pt.topReps)")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(selectedTheme.secondaryAccent)
                    }
                    .padding(14)
                    .glassCard(cornerRadius: 14)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func formatNumber(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(val))"
        }
        return String(format: "%.1f", val)
    }
}
