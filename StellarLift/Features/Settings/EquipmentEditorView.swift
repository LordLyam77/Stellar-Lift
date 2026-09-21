import SwiftUI
import SwiftData

public struct EquipmentEditorView: View {
    @Bindable var profile: EquipmentProfile
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    public var body: some View {
        ZStack {
            StarfieldBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Barbell Configuration
                    VStack(alignment: .leading, spacing: 14) {
                        Text("BARBELL SETUP")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)

                        HStack {
                            Text("Bar Weight")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textPrimary)
                            Spacer()
                            Stepper("\(formatKg(profile.barbellWeightKg))", value: $profile.barbellWeightKg, in: 5...30, step: 2.5)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(selectedTheme.secondaryAccent)
                        }

                        Divider().background(selectedTheme.stroke)

                        HStack {
                            Text("Smallest Jump")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textPrimary)
                            Spacer()
                            Stepper("\(formatKg(profile.smallestBarbellJumpKg))", value: $profile.smallestBarbellJumpKg, in: 0.5...5.0, step: 0.5)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(selectedTheme.secondaryAccent)
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)
                    .padding(.horizontal, 20)

                    // Machine Increment
                    VStack(alignment: .leading, spacing: 14) {
                        Text("MACHINES & CABLES")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)

                        HStack {
                            Text("Pin Stack Increment")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textPrimary)
                            Spacer()
                            Stepper("\(formatKg(profile.machineIncrementKg))", value: $profile.machineIncrementKg, in: 1...10, step: 0.5)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(selectedTheme.secondaryAccent)
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)
                    .padding(.horizontal, 20)

                    // Available Plates Breakdown
                    VStack(alignment: .leading, spacing: 14) {
                        Text("AVAILABLE BARBELL PLATES (KG)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)

                        let standardPlates = [1.25, 2.5, 5.0, 10.0, 15.0, 20.0, 25.0]
                        ForEach(standardPlates, id: \.self) { plate in
                            let hasPlate = profile.availablePlatesKg.contains(plate)
                            Toggle("\(formatKg(plate)) plate pair", isOn: Binding(
                                get: { hasPlate },
                                set: { isOn in
                                    if isOn {
                                        if !profile.availablePlatesKg.contains(plate) {
                                            profile.availablePlatesKg.append(plate)
                                            profile.availablePlatesKg.sort()
                                        }
                                    } else {
                                        profile.availablePlatesKg.removeAll(where: { $0 == plate })
                                    }
                                    try? modelContext.save()
                                }
                            ))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)
                            .tint(selectedTheme.primaryAccent)
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)
                    .padding(.horizontal, 20)

                    // Dumbbell Rack
                    VStack(alignment: .leading, spacing: 14) {
                        Text("DUMBBELL RACK (2.5KG STEPS)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)

                        Text("Stellar Lift uses your actual rack when recommending progressive jumps.")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)

                        let range = stride(from: 2.5, through: 50.0, by: 2.5).map { $0 }
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                            ForEach(range, id: \.self) { db in
                                let exists = profile.availableDumbbellsKg.contains(db)
                                Button {
                                    if exists {
                                        profile.availableDumbbellsKg.removeAll(where: { $0 == db })
                                    } else {
                                        profile.availableDumbbellsKg.append(db)
                                        profile.availableDumbbellsKg.sort()
                                    }
                                    try? modelContext.save()
                                } label: {
                                    Text("\(formatKg(db))")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .monospacedDigit()
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(exists ? selectedTheme.primaryAccent : selectedTheme.surfaceCard)
                                        .foregroundColor(exists ? .white : selectedTheme.textSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Equipment Rack")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatKg(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(val))kg"
        }
        return String(format: "%.1fkg", val)
    }
}
