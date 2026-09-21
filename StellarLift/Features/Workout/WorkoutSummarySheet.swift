import SwiftUI
import SwiftData

public struct WorkoutSummarySheet: View {
    @Bindable var session: WorkoutSession
    public let prCount: Int
    public let onDismiss: () -> Void

    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var sessionRpe: Double = 8.0
    @State private var energyRating: Int = 4
    @State private var sessionNotes: String = ""
    @State private var templateName: String = ""
    @State private var isTemplateSaved: Bool = false

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 6) {
                            Text("MISSION COMPLETE")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundColor(selectedTheme.secondaryAccent)
                                .tracking(2.0)

                            Text(session.splitDayName.isEmpty ? "Workout Session" : session.splitDayName)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(selectedTheme.textPrimary)

                            Text("Logged and synced to local SwiftData")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                        }
                        .padding(.top, 12)

                        // Big Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            statCard(title: "TOTAL VOLUME", value: formatVolume(session.totalVolumeKg), icon: "scalemass.fill", color: selectedTheme.primaryAccent)
                            statCard(title: "DURATION", value: formatDuration(session.durationSeconds), icon: "clock.fill", color: selectedTheme.secondaryAccent)
                            statCard(title: "HARD SETS", value: "\(session.totalWorkingSetsCount)", icon: "flame.fill", color: selectedTheme.tertiaryAccent)
                            statCard(title: "NEW PRs", value: "\(prCount)", icon: "trophy.fill", color: selectedTheme.successPR)
                        }
                        .padding(.horizontal, 20)

                        // Session RPE & Energy Rating
                        VStack(alignment: .leading, spacing: 14) {
                            Text("HOW DID IT FEEL?")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                                .tracking(1.2)

                            // RPE Stepper
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Session RPE: \(String(format: "%.1f", sessionRpe))")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)
                                    Text(rpeDescription(sessionRpe))
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(selectedTheme.secondaryAccent)
                                }
                                Spacer()
                                Stepper("", value: $sessionRpe, in: 6.0...10.0, step: 0.5)
                                    .labelsHidden()
                            }

                            Divider().background(selectedTheme.stroke)

                            // Energy / Mood Stars
                            HStack {
                                Text("Energy Level:")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)

                                Spacer()

                                HStack(spacing: 6) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= energyRating ? "star.fill" : "star")
                                            .font(.system(size: 20))
                                            .foregroundColor(star <= energyRating ? selectedTheme.warningStalled : selectedTheme.textMuted)
                                            .onTapGesture {
                                                energyRating = star
                                            }
                                    }
                                }
                            }

                            Divider().background(selectedTheme.stroke)

                            // Notes Field
                            TextField("Optional notes (e.g. sleep, pre-workout, joint cues)...", text: $sessionNotes)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(selectedTheme.textPrimary)
                                .padding(10)
                                .background(selectedTheme.surfaceCard)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 20)
                        .padding(.horizontal, 20)

                        // Save as Template Button
                        if !isTemplateSaved {
                            Button {
                                saveAsTemplate()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.down")
                                    Text("Save Workout as Reusable Template")
                                }
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedTheme.secondaryAccent)
                                .padding(.vertical, 8)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Saved to Templates")
                            }
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.successPR)
                        }

                        // Complete Button
                        StellarPrimaryButton("Done", icon: "checkmark.circle.fill") {
                            session.sessionRpe = sessionRpe
                            session.moodEnergy = energyRating
                            session.notes = sessionNotes
                            session.isFinished = true
                            session.endedAt = Date()
                            try? modelContext.save()
                            onDismiss()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        session.sessionRpe = sessionRpe
                        session.moodEnergy = energyRating
                        session.notes = sessionNotes
                        session.isFinished = true
                        session.endedAt = Date()
                        try? modelContext.save()
                        onDismiss()
                    }
                    .foregroundColor(selectedTheme.secondaryAccent)
                }
            }
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundColor(selectedTheme.textPrimary)
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
                .tracking(1.0)
        }
        .padding(14)
        .glassCard(cornerRadius: 16, strokeColor: color.opacity(0.3))
    }

    private func formatVolume(_ kg: Double) -> String {
        if kg >= 1000 {
            return String(format: "%.1ft", kg / 1000.0)
        }
        return "\(Int(kg))kg"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let hrs = mins / 60
        if hrs > 0 {
            return "\(hrs)h \(mins % 60)m"
        }
        return "\(mins) min"
    }

    private func rpeDescription(_ rpe: Double) -> String {
        switch rpe {
        case 6.0: return "Warmup / light speed work"
        case 7.0: return "3+ reps left in reserve"
        case 8.0: return "2 reps in reserve (solid hypertrophy)"
        case 9.0: return "1 rep in reserve (very heavy)"
        case 9.5: return "Maybe 1 rep, grind"
        case 10.0: return "Absolute maximum effort / failure"
        default: return ""
        }
    }

    private func saveAsTemplate() {
        var items: [TemplateExerciseItem] = []
        for (idx, perf) in session.sortedPerformedExercises.enumerated() {
            if let ex = perf.exercise {
                let item = TemplateExerciseItem(
                    exerciseId: ex.id,
                    exerciseName: ex.name,
                    targetSets: max(perf.sets.count, 3),
                    targetRepLow: ex.defaultRepRangeLow,
                    targetRepHigh: ex.defaultRepRangeHigh,
                    orderIndex: idx
                )
                items.append(item)
            }
        }
        let template = WorkoutTemplate(
            name: session.splitDayName.isEmpty ? "Custom Workout" : session.splitDayName,
            notes: "Saved from session on \(Date().formatted(date: .abbreviated, time: .omitted))",
            items: items
        )
        modelContext.insert(template)
        try? modelContext.save()
        isTemplateSaved = true
    }
}
