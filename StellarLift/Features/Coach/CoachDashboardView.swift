import SwiftUI
import SwiftData

public struct ChatMessage: Identifiable {
    public let id = UUID()
    public let isUser: Bool
    public let text: String
    public let timestamp: Date = Date()
}

public struct CoachDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @Query private var allExercises: [Exercise]
    @Query private var personalRecords: [PersonalRecord]
    @Query private var equipmentProfiles: [EquipmentProfile]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var chatInputText: String = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            isUser: false,
            text: "Welcome to your AI Coach. I continuously analyze your working sets, monitor for plateaus, and recommend double-progression weight increases. Ask me anything about your training data."
        )
    ]
    @State private var isThinking: Bool = false

    private let coach = LLMCoach()

    public var profile: EquipmentProfile {
        equipmentProfiles.first ?? EquipmentProfile.defaultProfile
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 1. Ready to Progress Group
                            readyToProgressSection

                            // 2. Stalled & Stagnant Group
                            stalledSection

                            // 3. Volume Warnings (<8 or >22 sets)
                            volumeWarningsSection

                            // 4. Wins This Month (PRs & Progressions)
                            winsSection

                            // 5. Chat History
                            chatHistorySection
                        }
                        .padding(.vertical, 16)
                    }

                    // Chat Input Bar Sticky at Bottom
                    chatInputBar
                }
            }
            .navigationTitle("AI Coach")
        }
    }

    // Ready to Progress Section
    private var readyToProgressSection: some View {
        let insights = allInsights.filter { $0.verdict == .readyToProgress }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(selectedTheme.successPR).frame(width: 8, height: 8)
                Text("READY TO PROGRESS (\(insights.count))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.successPR)
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 20)

            if insights.isEmpty {
                Text("No exercises currently maxing their rep range. Keep lifting!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 16)
                    .padding(.horizontal, 20)
            } else {
                ForEach(insights) { ins in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ins.exerciseName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)
                        Text(ins.message)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 16, strokeColor: selectedTheme.successPR.opacity(0.4))
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // Stalled & Stagnant Section
    private var stalledSection: some View {
        let insights = allInsights.filter { $0.verdict == .stalled || $0.verdict == .stagnantLong }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(selectedTheme.warningStalled).frame(width: 8, height: 8)
                Text("PLATEAUS & STAGNATION (\(insights.count))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.warningStalled)
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 20)

            if insights.isEmpty {
                Text("Zero plateaus detected. All tracked lifts are moving forward.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 16)
                    .padding(.horizontal, 20)
            } else {
                ForEach(insights) { ins in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(ins.exerciseName)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textPrimary)
                            Spacer()
                            Text(ins.verdict == .stagnantLong ? "> 21 DAYS" : "STALLED")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(Color(hex: ins.verdict.badgeColorHex))
                        }
                        Text(ins.message)
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 16, strokeColor: Color(hex: ins.verdict.badgeColorHex).opacity(0.4))
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // Volume Warnings
    private var volumeWarningsSection: some View {
        let warnings = computeVolumeWarnings()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle().fill(selectedTheme.secondaryAccent).frame(width: 8, height: 8)
                Text("VOLUME CALIBRATION")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.secondaryAccent)
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 20)

            if warnings.isEmpty {
                Text("Weekly sets across all muscle groups are within optimal range (8–22 sets).")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 16)
                    .padding(.horizontal, 20)
            } else {
                ForEach(warnings, id: \.0) { group, count, msg in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(group)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textPrimary)
                            Text(msg)
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                        }
                        Spacer()
                        Text("\(count) sets")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(selectedTheme.secondaryAccent)
                    }
                    .padding(14)
                    .glassCard(cornerRadius: 16)
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // Wins This Month
    private var winsSection: some View {
        let monthPRs = personalRecords.filter { $0.date > Date().addingTimeInterval(-86400 * 30) }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundColor(selectedTheme.successPR)
                Text("WINS THIS MONTH (\(monthPRs.count) PRS)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.successPR)
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 20)

            if monthPRs.isEmpty {
                Text("Conquer sets this week to log your first records.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 16)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(monthPRs.prefix(6)) { pr in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pr.exerciseName)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)
                                    .lineLimit(1)
                                Text("\(formatNumber(pr.value)) \(pr.recordType.unitSuffix)")
                                    .font(.system(size: 16, weight: .black, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(selectedTheme.successPR)
                                Text(pr.recordType.displayName)
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)
                            }
                            .padding(12)
                            .frame(width: 140)
                            .glassCard(cornerRadius: 14, strokeColor: selectedTheme.successPR.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // Chat History
    private var chatHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 12))
                    .foregroundColor(selectedTheme.primaryAccent)
                Text("COACH CONVERSATION")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .tracking(1.2)
                Spacer()
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(messages) { msg in
                    HStack {
                        if msg.isUser { Spacer() }
                        Text(msg.text)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(msg.isUser ? .white : selectedTheme.textPrimary)
                            .padding(12)
                            .background(msg.isUser ? selectedTheme.primaryAccent : selectedTheme.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(msg.isUser ? selectedTheme.primaryAccent : selectedTheme.stroke, lineWidth: 1)
                            )
                        if !msg.isUser { Spacer() }
                    }
                    .padding(.horizontal, 20)
                }

                if isThinking {
                    HStack {
                        ProgressView()
                            .tint(selectedTheme.secondaryAccent)
                        Text("Coach is analyzing your data...")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // Chat Input Bar
    private var chatInputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask Coach (e.g. why has my bench stalled?)...", text: $chatInputText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(selectedTheme.textPrimary)
                .padding(10)
                .background(selectedTheme.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedTheme.stroke, lineWidth: 1))

            Button {
                sendUserQuestion()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(chatInputText.isEmpty ? selectedTheme.textMuted : selectedTheme.secondaryAccent)
            }
            .disabled(chatInputText.isEmpty || isThinking)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(selectedTheme.backgroundRaised)
        .overlay(
            Rectangle().frame(height: 1).foregroundColor(selectedTheme.stroke),
            alignment: .top
        )
    }

    private func sendUserQuestion() {
        let question = chatInputText.trimmingCharacters(in: .whitespaces)
        guard !question.isEmpty else { return }

        messages.append(ChatMessage(isUser: true, text: question))
        chatInputText = ""
        isThinking = true

        let context = buildTrainingContext()

        Task {
            let answer = (try? await coach.answer(question: question, context: context)) ?? "Keep following double progression: hold weight until top of rep range is reached on every set."
            await MainActor.run {
                messages.append(ChatMessage(isUser: false, text: answer))
                isThinking = false
            }
        }
    }

    private func buildTrainingContext() -> TrainingContext {
        var topSets: [String: String] = [:]
        var verdicts: [String: String] = [:]
        var weeklyVol: [String: Int] = [:]

        for ins in allInsights {
            verdicts[ins.exerciseName] = ins.verdict.title
            if ins.currentWeightKg > 0 {
                topSets[ins.exerciseName] = "\(formatNumber(ins.currentWeightKg))kg"
            }
        }

        let calendar = Calendar.current
        let weekAgo = Date().addingTimeInterval(-86400 * 7)
        for s in allSessions where s.isFinished && s.date >= weekAgo {
            for p in s.performedExercises {
                if let mg = p.exercise?.muscleGroup {
                    weeklyVol[mg.displayName, default: 0] += p.workingSets.count
                }
            }
        }

        return TrainingContext(
            topSetsPerExercise: topSets,
            currentVerdicts: verdicts,
            weeklyVolumePerMuscle: weeklyVol
        )
    }

    private var allInsights: [ProgressionInsight] {
        var list: [ProgressionInsight] = []
        let finished = allSessions.filter { $0.isFinished }.sorted { $0.date < $1.date }

        for ex in allExercises where !ex.isArchived {
            var history: [ExerciseSessionMetrics] = []
            for s in finished {
                if let match = s.performedExercises.first(where: { $0.exercise?.id == ex.id }) {
                    let m = ProgressionAnalyzer.computeSessionMetrics(
                        performed: match,
                        sessionDate: s.date,
                        targetRepHigh: ex.defaultRepRangeHigh
                    )
                    if m.workingSetsCount > 0 { history.append(m) }
                }
            }

            let ins = ProgressionAnalyzer.evaluate(
                exerciseName: ex.name,
                exerciseId: ex.id,
                equipment: ex.equipment,
                targetRepLow: ex.defaultRepRangeLow,
                targetRepHigh: ex.defaultRepRangeHigh,
                history: history,
                profile: profile
            )
            list.append(ins)
        }
        return list
    }

    private func computeVolumeWarnings() -> [(String, Int, String)] {
        let calendar = Calendar.current
        let weekAgo = Date().addingTimeInterval(-86400 * 7)
        var counts: [MuscleGroup: Int] = [:]

        for s in allSessions where s.isFinished && s.date >= weekAgo {
            for p in s.performedExercises {
                if let mg = p.exercise?.muscleGroup {
                    counts[mg, default: 0] += p.workingSets.count
                }
            }
        }

        var warnings: [(String, Int, String)] = []
        for (mg, count) in counts {
            if count < 8 {
                warnings.append((mg.displayName, count, "Under-trained (<8 sets/week). Consider adding a set."))
            } else if count > 22 {
                warnings.append((mg.displayName, count, "Excessive fatigue (>22 sets/week). Risk of overtraining."))
            }
        }
        return warnings
    }

    private func formatNumber(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(val))"
        }
        return String(format: "%.1f", val)
    }
}
