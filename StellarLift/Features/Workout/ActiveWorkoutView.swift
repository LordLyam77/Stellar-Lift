import SwiftUI
import SwiftData

public struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var equipmentProfiles: [EquipmentProfile]
    @Query private var personalRecords: [PersonalRecord]
    @Query private var allSessions: [WorkoutSession]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var elapsedSeconds: Int = 0
    @State private var timer: Timer?
    @State private var showingUnplannedSheet = false
    @State private var showingPlateCalcSheet = false
    @State private var plateCalcWeight: Double = 60.0
    @State private var showingWarmupSheet = false
    @State private var warmupExercise: PerformedExercise? = nil
    @State private var showingSummarySheet = false
    @State private var newPRsAchieved: Int = 0

    // Expanded states for exercise cards
    @State private var expandedExerciseIds: Set<UUID> = []

    public var profile: EquipmentProfile {
        equipmentProfiles.first ?? EquipmentProfile.defaultProfile
    }

    public var body: some View {
        ZStack {
            StarfieldBackground()

            VStack(spacing: 0) {
                // Sticky Header
                stickyHeader

                // Main Workout Exercise Cards List
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(session.sortedPerformedExercises) { performed in
                            exerciseCard(performed)
                        }

                        // Add Unplanned Exercise Button
                        Button {
                            showingUnplannedSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Unplanned Exercise")
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.secondaryAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .glassCard(cornerRadius: 16, strokeColor: selectedTheme.secondaryAccent.opacity(0.4))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 90) // clearance for rest timer
                    }
                    .padding(.vertical, 12)
                }
            }

            // Floating Orbit Rest Timer if active
            if AppState.shared.isRestTimerActive {
                VStack {
                    Spacer()
                    OrbitRestTimerView(
                        totalSeconds: AppState.shared.restTimerTotalSeconds,
                        remainingSeconds: AppState.shared.restTimerRemainingSeconds,
                        onAdd30s: { AppState.shared.add30SecondsToRest() },
                        onSkip: { AppState.shared.skipRestTimer() }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // PR Celebration Starburst overlay
            if AppState.shared.showPRCelebration, let prText = AppState.shared.currentPRText {
                StarburstCelebration(prText: prText) {
                    AppState.shared.dismissPRCelebration()
                }
                .transition(.opacity)
                .zIndex(999)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            startTimer()
            AppState.shared.activeSessionId = session.id
            // Expand all cards initially
            for ex in session.performedExercises {
                expandedExerciseIds.insert(ex.id)
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
        .sheet(isPresented: $showingUnplannedSheet) {
            UnplannedExerciseSheet { selected in
                addUnplannedExercise(selected)
            }
        }
        .sheet(isPresented: $showingPlateCalcSheet) {
            PlateCalculatorSheet(initialWeightKg: plateCalcWeight, profile: profile)
        }
        .sheet(isPresented: $showingSummarySheet) {
            WorkoutSummarySheet(session: session, prCount: newPRsAchieved) {
                AppState.shared.activeSessionId = nil
                AppState.shared.skipRestTimer()
                dismiss()
            }
        }
        .sheet(item: $warmupExercise) { perf in
            WarmupSheet(
                exerciseName: perf.exerciseName,
                workingWeightKg: perf.topSetWeightKg > 0 ? perf.topSetWeightKg : 40.0,
                equipment: perf.exercise?.equipment ?? .barbell,
                profile: profile
            ) { warmupSteps in
                addWarmupSets(to: perf, steps: warmupSteps)
            }
        }
    }

    // Sticky Header
    private var stickyHeader: some View {
        HStack {
            // Elapsed Timer
            VStack(alignment: .leading, spacing: 2) {
                Text("ELAPSED")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .tracking(1.0)
                Text(formatElapsed(elapsedSeconds))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(selectedTheme.textPrimary)
            }

            Spacer()

            // Session Volume
            VStack(alignment: .center, spacing: 2) {
                Text("TOTAL VOLUME")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .tracking(1.0)
                Text(formatVolume(session.totalVolumeKg))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(selectedTheme.secondaryAccent)
            }

            Spacer()

            // Finish Button
            Button {
                showingSummarySheet = true
            } label: {
                Text("Finish")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedTheme.successPR)
                    .clipShape(Capsule())
                    .shadow(color: selectedTheme.successPR.opacity(0.4), radius: 6)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(selectedTheme.backgroundRaised.opacity(0.95))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(selectedTheme.stroke),
            alignment: .bottom
        )
    }

    // Exercise Card
    @ViewBuilder
    private func exerciseCard(_ performed: PerformedExercise) -> some View {
        let isExpanded = expandedExerciseIds.contains(performed.id)
        let lastSessionMatching = findLastSessionPerformed(for: performed.exercise)
        let progression = computeProgressionInsight(for: performed)

        VStack(alignment: .leading, spacing: 10) {
            // Card Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(performed.exerciseName)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)

                    if let group = performed.exercise?.muscleGroup {
                        Text(group.displayName + " • " + (performed.exercise?.equipment.displayName ?? "Other"))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedTheme.secondaryAccent)
                    }
                }

                Spacer()

                // Plate calc shortcut for barbell
                if performed.exercise?.equipment == .barbell || performed.exercise?.equipment == .smith {
                    Button {
                        plateCalcWeight = performed.topSetWeightKg > 0 ? performed.topSetWeightKg : 60.0
                        showingPlateCalcSheet = true
                    } label: {
                        Image(systemName: "circle.grid.cross.fill")
                            .font(.system(size: 14))
                            .foregroundColor(selectedTheme.secondaryAccent)
                            .padding(6)
                            .background(selectedTheme.surfaceCard)
                            .clipShape(Circle())
                    }
                }

                // Warmup shortcut
                Button {
                    warmupExercise = performed
                } label: {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundColor(selectedTheme.warningStalled)
                        .padding(6)
                        .background(selectedTheme.surfaceCard)
                        .clipShape(Circle())
                }

                // Expand/Collapse Chevron
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if isExpanded {
                            expandedExerciseIds.remove(performed.id)
                        } else {
                            expandedExerciseIds.insert(performed.id)
                        }
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(selectedTheme.textSecondary)
                        .padding(6)
                }
            }

            // Inline Progression Hint Card with One-Tap "Apply"
            if let insight = progression, insight.verdict != .newExercise {
                HStack(spacing: 8) {
                    Image(systemName: insight.verdict == .readyToProgress ? "arrow.up.circle.fill" : "sparkles")
                        .foregroundColor(Color(hex: insight.verdict.badgeColorHex))

                    Text(insight.message)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)
                        .lineLimit(2)

                    Spacer()

                    if let suggested = insight.suggestedWeightKg, insight.verdict == .readyToProgress || insight.verdict == .stagnantLong {
                        Button {
                            applySuggestedWeight(suggested, to: performed)
                        } label: {
                            Text("Apply")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: insight.verdict.badgeColorHex))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(10)
                .background(Color(hex: insight.verdict.badgeColorHex).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: insight.verdict.badgeColorHex).opacity(0.35), lineWidth: 1))
            }

            // Expandable Set Table
            if isExpanded {
                VStack(spacing: 6) {
                    // Set Table Column Headers
                    HStack(spacing: 8) {
                        Text("SET")
                            .frame(width: 26)
                        Text("PREVIOUS")
                            .frame(width: 68, alignment: .leading)
                        Text("KG")
                            .frame(width: 90)
                        Text("REPS")
                            .frame(width: 82)
                        Spacer()
                        Image(systemName: "checkmark")
                            .frame(width: 32)
                    }
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .padding(.horizontal, 10)

                    Divider().background(selectedTheme.stroke)

                    // Set Rows
                    ForEach(performed.sortedSets) { setEntry in
                        let prevSet = lastSessionMatching?.sortedSets.first { $0.setNumber == setEntry.setNumber }
                        let prevText = prevSet != nil ? "\(formatKg(prevSet!.weightKg)) × \(prevSet!.reps)" : nil

                        SetRowView(
                            setEntry: setEntry,
                            previousText: prevText,
                            previousWeight: prevSet?.weightKg,
                            previousReps: prevSet?.reps,
                            equipment: performed.exercise?.equipment ?? .other,
                            profile: profile,
                            onCompleteSet: {
                                handleSetCompleted(setEntry, performed: performed)
                            },
                            onDeleteSet: {
                                deleteSet(setEntry, from: performed)
                            }
                        )
                    }

                    // Add Set Button
                    Button {
                        addNewSet(to: performed)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text("Add Set")
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.secondaryAccent)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background(selectedTheme.surfaceCard.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 18, strokeColor: selectedTheme.primaryAccent.opacity(0.35))
        .padding(.horizontal, 16)
    }

    // Set Completion Handler: Haptic, Timer, and PR Check
    private func handleSetCompleted(_ set: SetEntry, performed: PerformedExercise) {
        // 1. Check for PRs
        let hits = PRDetector.checkForPR(
            exercise: performed.exercise,
            exerciseName: performed.exerciseName,
            set: set,
            existingRecords: personalRecords
        )

        if let topHit = hits.first {
            newPRsAchieved += 1
            // Save to PersonalRecord table
            let record = PersonalRecord(
                exercise: performed.exercise,
                exerciseName: performed.exerciseName,
                type: topHit.recordType,
                value: topHit.newValue,
                date: Date(),
                sessionId: session.id,
                repsAtWeight: set.reps,
                weightAtReps: set.weightKg
            )
            modelContext.insert(record)
            try? modelContext.save()

            // Trigger celebration
            AppState.shared.triggerPRCelebration(text: topHit.displayText)
        }

        // 2. Start Rest Timer
        let restSec = 90
        AppState.shared.startRestTimer(seconds: restSec)

        // 3. Autosave session state
        try? modelContext.save()
    }

    private func addNewSet(to performed: PerformedExercise) {
        let lastSet = performed.sortedSets.last
        let newSetNumber = (lastSet?.setNumber ?? 0) + 1
        let newSet = SetEntry(
            setNumber: newSetNumber,
            weightKg: lastSet?.weightKg ?? 0.0,
            reps: lastSet?.reps ?? 0,
            performedExercise: performed
        )
        performed.sets.append(newSet)
        modelContext.insert(newSet)
        try? modelContext.save()
    }

    private func deleteSet(_ set: SetEntry, from performed: PerformedExercise) {
        if let idx = performed.sets.firstIndex(where: { $0.id == set.id }) {
            performed.sets.remove(at: idx)
            modelContext.delete(set)
            try? modelContext.save()
        }
    }

    private func applySuggestedWeight(_ weight: Double, to performed: PerformedExercise) {
        for set in performed.sets {
            if set.weightKg == 0 || !set.isWarmup {
                set.weightKg = weight
            }
        }
        try? modelContext.save()
        let haptic = UINotificationFeedbackGenerator()
        haptic.notificationOccurred(.success)
    }

    private func addWarmupSets(to performed: PerformedExercise, steps: [WarmupStep]) {
        // Shift existing sets
        let offset = steps.count
        for s in performed.sets {
            s.setNumber += offset
        }

        for (idx, step) in steps.enumerated() {
            let warmupSet = SetEntry(
                setNumber: idx + 1,
                weightKg: step.weightKg,
                reps: step.reps,
                isWarmup: true,
                performedExercise: performed
            )
            performed.sets.append(warmupSet)
            modelContext.insert(warmupSet)
        }
        try? modelContext.save()
    }

    private func addUnplannedExercise(_ exercise: Exercise) {
        let performed = PerformedExercise(
            exercise: exercise,
            exerciseName: exercise.name,
            orderIndex: session.performedExercises.count,
            session: session
        )
        session.performedExercises.append(performed)
        modelContext.insert(performed)

        // Add 3 default sets
        for i in 1...3 {
            let set = SetEntry(setNumber: i, weightKg: 0, reps: 0, performedExercise: performed)
            performed.sets.append(set)
            modelContext.insert(set)
        }
        expandedExerciseIds.insert(performed.id)
        try? modelContext.save()
    }

    private func findLastSessionPerformed(for exercise: Exercise?) -> PerformedExercise? {
        guard let ex = exercise else { return nil }
        let finishedSessions = allSessions
            .filter { $0.isFinished && $0.id != session.id }
            .sorted { $0.date > $1.date }

        for s in finishedSessions {
            if let match = s.performedExercises.first(where: { $0.exercise?.id == ex.id }) {
                return match
            }
        }
        return nil
    }

    private func computeProgressionInsight(for performed: PerformedExercise) -> ProgressionInsight? {
        guard let ex = performed.exercise else { return nil }
        let finished = allSessions
            .filter { $0.isFinished && $0.id != session.id }
            .sorted { $0.date < $1.date }

        var history: [ExerciseSessionMetrics] = []
        for s in finished {
            if let match = s.performedExercises.first(where: { $0.exercise?.id == ex.id }) {
                let metrics = ProgressionAnalyzer.computeSessionMetrics(
                    performed: match,
                    sessionDate: s.date,
                    targetRepHigh: ex.defaultRepRangeHigh
                )
                if metrics.workingSetsCount > 0 {
                    history.append(metrics)
                }
            }
        }

        return ProgressionAnalyzer.evaluate(
            exerciseName: ex.name,
            exerciseId: ex.id,
            equipment: ex.equipment,
            targetRepLow: ex.defaultRepRangeLow,
            targetRepHigh: ex.defaultRepRangeHigh,
            history: history,
            profile: profile
        )
    }

    private func startTimer() {
        let initialElapsed = Int(session.durationSeconds)
        elapsedSeconds = initialElapsed
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func formatElapsed(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func formatVolume(_ kg: Double) -> String {
        if kg >= 1000 {
            return String(format: "%.1ft", kg / 1000.0)
        }
        return "\(Int(kg))kg"
    }

    private func formatKg(_ kg: Double) -> String {
        if kg.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(kg))"
        }
        return String(format: "%.1f", kg)
    }
}
