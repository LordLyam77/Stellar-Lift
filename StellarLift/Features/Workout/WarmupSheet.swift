import SwiftUI

public struct WarmupSheet: View {
    public let exerciseName: String
    public let workingWeightKg: Double
    public let equipment: EquipmentType
    public let profile: EquipmentProfile
    public let onAddWarmups: ([WarmupStep]) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    public var warmupSteps: [WarmupStep] {
        WarmupCalculator.generateRampSets(
            targetWorkingWeightKg: workingWeightKg,
            barbellWeightKg: profile.barbellWeightKg,
            equipment: equipment
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WARM-UP PROTOCOL")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)

                        Text(exerciseName)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)

                        Text("Working weight target: \(formatWeight(workingWeightKg))")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedTheme.secondaryAccent)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    if warmupSteps.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "flame")
                                .font(.system(size: 32))
                                .foregroundColor(selectedTheme.textMuted)
                            Text("No warm-up needed for this weight.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                        .glassCard(cornerRadius: 18)
                        .padding(.horizontal, 20)
                    } else {
                        List(warmupSteps) { step in
                            HStack(spacing: 14) {
                                Text("\(step.percentage)%")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.secondaryAccent)
                                    .frame(width: 44, alignment: .leading)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(formatWeight(step.weightKg)) × \(step.reps) reps")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)
                                    Text(step.instruction)
                                        .font(.system(size: 11, weight: .regular, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondary)
                                }

                                Spacer()
                            }
                            .listRowBackground(selectedTheme.surfaceCard.opacity(0.4))
                        }
                        .scrollContentBackground(.hidden)

                        StellarPrimaryButton("Add Warm-Up Sets to Workout", icon: "plus.circle.fill") {
                            onAddWarmups(warmupSteps)
                            dismiss()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Warm-up Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(selectedTheme.secondaryAccent)
                }
            }
        }
    }

    private func formatWeight(_ kg: Double) -> String {
        if kg.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(kg))kg"
        }
        return String(format: "%.1fkg", kg)
    }
}
