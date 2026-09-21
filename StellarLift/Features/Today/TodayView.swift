import SwiftUI
import SwiftData

public struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var weeklySchedules: [WeeklySchedule]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @Query private var allExercises: [Exercise]
    @Query private var equipmentProfiles: [EquipmentProfile]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var activeWorkoutSession: WorkoutSession? = nil
    @State private var selectedExerciseForDetail: Exercise? = nil
    @State private var showingExerciseDetail: Bool = false

    public var profile: EquipmentProfile {
        equipmentProfiles.first ?? EquipmentProfile.defaultProfile
    }

    // Today's weekday index (1=Sun, 2=Mon...7=Sat)
    private var todayWeekday: Int {
        Calendar.current.component(.weekday, from: Date())
    }

    private var todaySchedule: WeeklySchedule? {
        weeklySchedules.first { $0.dayOfWeek == todayWeekday }
    }

    private var todaySplit: SplitDay? {
        todaySchedule?.splitDay
    }

    // Unfinished active session for recovery
    private var inProgressSession: WorkoutSession? {
        if let id = AppState.shared.activeSessionId {
            return allSessions.first { $0.id == id && !$0.isFinished }
        }
        return allSessions.first { !$0.isFinished }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Greeting & Date Header
                        headerView

                        // 2. Resume In-Progress Workout Banner (if app was closed mid-workout)
                        if let inProg = inProgressSession {
                            resumeWorkoutBanner(inProg)
                        }

                        // 3. Deload Detector Alert Banner (if >= 40% stalled/regressing)
                        if shouldShowDeloadBanner {
                            deloadBanner
                        }

                        // 4. 7-Day Split Dot Strip
                        weekDotStrip

                        // 5. Large Glowing Today Card
                        todayWorkoutCard

                        // 6. Coach Insights Row (readyToProgress & stagnantLong)
                        coachCardsSection
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(item: $activeWorkoutSession) { session in
                ActiveWorkoutView(session: session)
            }
            .navigationDestination(isPresented: $showingExerciseDetail) {
                if let ex = selectedExerciseForDetail {
                    ExerciseDetailView(exercise: ex)
                }
            }
        }
    }

    // Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.secondaryAccent)
                    .textCase(.uppercase)
                    .tracking(1.0)

                Text(greetingText)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(selectedTheme.textPrimary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // Resume Workout Banner
    private func resumeWorkoutBanner(_ session: WorkoutSession) -> some View {
        Button {
            activeWorkoutSession = session
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(selectedTheme.successPR)
                    .frame(width: 10, height: 10)
                    .shadow(color: selectedTheme.successPR, radius: 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text("WORKOUT IN PROGRESS")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(selectedTheme.successPR)
                    Text("Resume \(session.splitDayName.isEmpty ? "Active Session" : session.splitDayName)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(selectedTheme.successPR)
            }
            .padding(14)
            .glassCard(cornerRadius: 16, strokeColor: selectedTheme.successPR, glowing: true, glowColor: selectedTheme.successPR.opacity(0.3))
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
    }

    // Deload Banner
    private var deloadBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(selectedTheme.warningStalled)
                Text("DELOAD WEEK RECOMMENDED")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(selectedTheme.warningStalled)
                    .tracking(1.0)
            }
            Text("Over 40% of your tracked lifts are stalled or regressing. Take 1 week at ⅔ volume to allow systemic recovery.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(selectedTheme.textPrimary)
        }
        .padding(14)
        .glassCard(cornerRadius: 16, strokeColor: selectedTheme.warningStalled.opacity(0.5))
        .padding(.horizontal, 20)
    }

    // 7-day dot strip
    private var weekDotStrip: some View {
        HStack(spacing: 8) {
            // Monday first: 2, 3, 4, 5, 6, 7, 1
            let days = [2, 3, 4, 5, 6, 7, 1]
            ForEach(days, id: \.self) { day in
                let sched = weeklySchedules.first { $0.dayOfWeek == day }
                let isToday = day == todayWeekday
                let split = sched?.splitDay

                VStack(spacing: 4) {
                    Text(shortDay(day))
                        .font(.system(size: 10, weight: isToday ? .black : .semibold, design: .rounded))
                        .foregroundColor(isToday ? selectedTheme.primaryAccent : selectedTheme.textSecondary)

                    Circle()
                        .fill(split != nil ? Color(hex: split!.colorHex) : Color.gray.opacity(0.3))
                        .frame(width: isToday ? 10 : 7, height: isToday ? 10 : 7)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: isToday ? 2 : 0)
                        )
                        .shadow(color: isToday && split != nil ? Color(hex: split!.colorHex).opacity(0.8) : Color.clear, radius: 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(isToday ? selectedTheme.surfaceCard : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 16)
        .padding(.horizontal, 20)
    }

    // Large Glowing Today Card
    private var todayWorkoutCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let split = todaySplit {
                // Active Lifting Split
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Circle()
                            .fill(Color(hex: split.colorHex))
                            .frame(width: 10, height: 10)
                        Text(split.isCardioDay ? "TODAY'S CARDIO" : "TODAY'S TARGET")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: split.colorHex))
                            .tracking(1.2)
                        Spacer()
                    }

                    Text(split.name)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)

                    Text(split.isCardioDay ? "Zone 2 aerobic base building" : "\(split.plannedExercises.count) Planned Exercises")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                }

                Divider().background(selectedTheme.stroke)

                // Planned Exercises with Last-Session Weights
                if !split.plannedExercises.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(split.sortedPlannedExercises.prefix(5)) { planned in
                            let lastWeight = findLastWeight(for: planned.exercise)
                            HStack {
                                Text(planned.exercise?.name ?? "Exercise")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)
                                Spacer()
                                if let w = lastWeight {
                                    Text("Last: \(formatKg(w))")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundColor(selectedTheme.secondaryAccent)
                                } else {
                                    Text("\(planned.targetSets) × \(planned.targetRepLow)–\(planned.targetRepHigh)")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Primary Start Workout Button
                StellarPrimaryButton("Start Workout", icon: "play.fill") {
                    startWorkout(with: split)
                }
                .padding(.top, 4)

                // Quick Repeat Button if last week session exists
                if let lastWeek = findPreviousSession(for: split) {
                    Button {
                        quickRepeatSession(lastWeek, split: split)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Repeat Last \(split.name) with Progressions")
                        }
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.secondaryAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                }
            } else {
                // Rest Day State
                VStack(alignment: .leading, spacing: 8) {
                    Text("REST & RECOVERY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.secondaryAccent)
                        .tracking(1.2)

                    Text("Rest Day")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)

                    Text("Muscle protein synthesis happens while you rest. Prioritize sleep, protein intake, and mobility.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                }

                Divider().background(selectedTheme.stroke)

                Button {
                    startBlankWorkout()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Something Anyway")
                    }
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.primaryAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTheme.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedTheme.primaryAccent.opacity(0.4), lineWidth: 1))
                }
            }
        }
        .padding(20)
        .glassCard(
            cornerRadius: 22,
            strokeColor: todaySplit != nil ? Color(hex: todaySplit!.colorHex).opacity(0.6) : selectedTheme.primaryAccent.opacity(0.4),
            glowing: true,
            glowColor: todaySplit != nil ? Color(hex: todaySplit!.colorHex).opacity(0.25) : nil
        )
        .padding(.horizontal, 20)
    }

    // Coach Cards Carousel
    private var coachCardsSection: some View {
        let insights = computeUrgentCoachInsights()

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("COACH INSIGHTS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .tracking(1.2)
                Spacer()
                Text("\(insights.count) updates")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(selectedTheme.secondaryAccent)
            }
            .padding(.horizontal, 20)

            if insights.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(selectedTheme.secondaryAccent)
                    Text("Log your workouts to unlock smart double progression guidance.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                }
                .padding(16)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(insights) { insight in
                            CoachCardView(insight: insight) {
                                if let exId = insight.exerciseId,
                                   let ex = allExercises.first(where: { $0.id == exId }) {
                                    selectedExerciseForDetail = ex
                                    showingExerciseDetail = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good morning." }
        if hour < 17 { return "Good afternoon." }
        return "Good evening."
    }

    private func shortDay(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "SUN"
        case 2: return "MON"
        case 3: return "TUE"
        case 4: return "WED"
        case 5: return "THU"
        case 6: return "FRI"
        case 7: return "SAT"
        default: return ""
        }
    }

    private func findLastWeight(for exercise: Exercise?) -> Double? {
        guard let ex = exercise else { return nil }
        for session in allSessions where session.isFinished {
            if let perf = session.performedExercises.first(where: { $0.exercise?.id == ex.id }) {
                if perf.topSetWeightKg > 0 {
                    return perf.topSetWeightKg
                }
            }
        }
        return nil
    }

    private func findPreviousSession(for split: SplitDay) -> WorkoutSession? {
        allSessions.first { $0.isFinished && $0.splitDay?.id == split.id }
    }

    private func startWorkout(with split: SplitDay) {
        let session = WorkoutSession(
            splitDay: split,
            splitDayName: split.name,
            startedAt: Date()
        )
        modelContext.insert(session)

        for (idx, planned) in split.sortedPlannedExercises.enumerated() {
            guard let ex = planned.exercise else { continue }
            let performed = PerformedExercise(
                exercise: ex,
                exerciseName: ex.name,
                orderIndex: idx,
                session: session
            )
            session.performedExercises.append(performed)
            modelContext.insert(performed)

            // Auto-populate sets matching last session or planned targets
            let lastPerf = findLastSessionPerformed(for: ex)
            for s in 1...planned.targetSets {
                let prevSet = lastPerf?.sortedSets.first { $0.setNumber == s }
                let setEntry = SetEntry(
                    setNumber: s,
                    weightKg: prevSet?.weightKg ?? 0,
                    reps: prevSet?.reps ?? 0,
                    performedExercise: performed
                )
                performed.sets.append(setEntry)
                modelContext.insert(setEntry)
            }
        }

        try? modelContext.save()
        AppState.shared.activeSessionId = session.id
        activeWorkoutSession = session
    }

    private func startBlankWorkout() {
        let session = WorkoutSession(
            splitDayName: "Extra Workout",
            startedAt: Date()
        )
        modelContext.insert(session)
        try? modelContext.save()
        AppState.shared.activeSessionId = session.id
        activeWorkoutSession = session
    }

    private func quickRepeatSession(_ prevSession: WorkoutSession, split: SplitDay) {
        let session = WorkoutSession(
            splitDay: split,
            splitDayName: split.name,
            startedAt: Date()
        )
        modelContext.insert(session)

        for (idx, oldPerf) in prevSession.sortedPerformedExercises.enumerated() {
            guard let ex = oldPerf.exercise else { continue }
            let performed = PerformedExercise(
                exercise: ex,
                exerciseName: ex.name,
                orderIndex: idx,
                session: session
            )
            session.performedExercises.append(performed)
            modelContext.insert(performed)

            // Check if readyToProgress or stagnant
            let insight = computeProgressionInsight(for: ex)
            let suggestedWeight = (insight?.verdict == .readyToProgress || insight?.verdict == .stagnantLong) ? insight?.suggestedWeightKg : nil

            for oldSet in oldPerf.sortedSets {
                let weight = suggestedWeight ?? oldSet.weightKg
                let reps = suggestedWeight != nil ? (insight?.suggestedRepRangeLow ?? 8) : oldSet.reps
                let setEntry = SetEntry(
                    setNumber: oldSet.setNumber,
                    weightKg: weight,
                    reps: reps,
                    isWarmup: oldSet.isWarmup,
                    performedExercise: performed
                )
                performed.sets.append(setEntry)
                modelContext.insert(setEntry)
            }
        }

        try? modelContext.save()
        AppState.shared.activeSessionId = session.id
        activeWorkoutSession = session
    }

    private func findLastSessionPerformed(for exercise: Exercise?) -> PerformedExercise? {
        guard let ex = exercise else { return nil }
        for s in allSessions where s.isFinished {
            if let perf = s.performedExercises.first(where: { $0.exercise?.id == ex.id }) {
                return perf
            }
        }
        return nil
    }

    private func computeProgressionInsight(for exercise: Exercise) -> ProgressionInsight? {
        let finished = allSessions.filter { $0.isFinished }.sorted { $0.date < $1.date }
        var history: [ExerciseSessionMetrics] = []
        for s in finished {
            if let match = s.performedExercises.first(where: { $0.exercise?.id == exercise.id }) {
                let metrics = ProgressionAnalyzer.computeSessionMetrics(
                    performed: match,
                    sessionDate: s.date,
                    targetRepHigh: exercise.defaultRepRangeHigh
                )
                if metrics.workingSetsCount > 0 {
                    history.append(metrics)
                }
            }
        }
        return ProgressionAnalyzer.evaluate(
            exerciseName: exercise.name,
            exerciseId: exercise.id,
            equipment: exercise.equipment,
            targetRepLow: exercise.defaultRepRangeLow,
            targetRepHigh: exercise.defaultRepRangeHigh,
            history: history,
            profile: profile
        )
    }

    private func computeUrgentCoachInsights() -> [ProgressionInsight] {
        var results: [ProgressionInsight] = []
        for ex in allExercises where !ex.isArchived {
            if let insight = computeProgressionInsight(for: ex),
               insight.verdict == .stagnantLong || insight.verdict == .readyToProgress || insight.verdict == .stalled {
                results.append(insight)
            }
        }
        // Most urgent first: stagnantLong > readyToProgress > stalled
        return results.sorted { a, b in
            let scoreA = a.verdict == .stagnantLong ? 3 : (a.verdict == .readyToProgress ? 2 : 1)
            let scoreB = b.verdict == .stagnantLong ? 3 : (b.verdict == .readyToProgress ? 2 : 1)
            return scoreA > scoreB
        }
    }

    private var shouldShowDeloadBanner: Bool {
        var insights: [ProgressionInsight] = []
        for ex in allExercises where !ex.isArchived {
            if let ins = computeProgressionInsight(for: ex), ins.verdict != .newExercise {
                insights.append(ins)
            }
        }
        return ProgressionAnalyzer.shouldRecommendDeload(insights: insights)
    }

    private func formatKg(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(val))kg"
        }
        return String(format: "%.1fkg", val)
    }
}
