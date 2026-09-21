import SwiftUI
import SwiftData

public struct ExerciseEditView: View {
    @Bindable var exercise: Exercise
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // Basic Info Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("EXERCISE DETAILS")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                                .tracking(1.2)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Exercise Name")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)

                                TextField("Name (e.g. Incline DB Press)", text: $exercise.name)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)
                                    .padding(10)
                                    .background(selectedTheme.surfaceCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            // Muscle Group Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Primary Muscle Group")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)

                                Picker("Muscle Group", selection: $exercise.muscleGroup) {
                                    ForEach(MuscleGroup.allCases) { mg in
                                        Text(mg.displayName).tag(mg)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(selectedTheme.secondaryAccent)
                                .padding(6)
                                .background(selectedTheme.surfaceCard)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            // Equipment Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Equipment Type")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)

                                Picker("Equipment", selection: $exercise.equipment) {
                                    ForEach(EquipmentType.allCases) { eq in
                                        Text(eq.displayName).tag(eq)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(selectedTheme.primaryAccent)
                                .padding(6)
                                .background(selectedTheme.surfaceCard)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            // Unilateral Toggle
                            Toggle(isOn: $exercise.isUnilateral) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Unilateral Exercise")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)
                                    Text("Weight entered is per-side (e.g. dumbbell)")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondary)
                                }
                            }
                            .tint(selectedTheme.primaryAccent)
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 20)
                        .padding(.horizontal, 20)

                        // Target Rep Range
                        VStack(alignment: .leading, spacing: 14) {
                            Text("PROGRESSION TARGET REP RANGE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                                .tracking(1.2)

                            HStack(spacing: 20) {
                                Stepper("Low: \(exercise.defaultRepRangeLow)", value: $exercise.defaultRepRangeLow, in: 1...exercise.defaultRepRangeHigh)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)

                                Stepper("High: \(exercise.defaultRepRangeHigh)", value: $exercise.defaultRepRangeHigh, in: exercise.defaultRepRangeLow...50)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)
                            }
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 20)
                        .padding(.horizontal, 20)

                        // Archive Toggle
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $exercise.isArchived) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Archive Exercise")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)
                                    Text("Hides from active workout selectors")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondary)
                                }
                            }
                            .tint(selectedTheme.danger)
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 20)
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Edit Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        try? modelContext.save()
                        dismiss()
                    }
                    .foregroundColor(selectedTheme.secondaryAccent)
                }
            }
        }
    }
}
