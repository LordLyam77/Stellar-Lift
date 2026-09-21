import SwiftUI

public struct PlateCalculatorSheet: View {
    public let initialWeightKg: Double
    public let profile: EquipmentProfile
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var targetWeightKg: Double

    public init(initialWeightKg: Double, profile: EquipmentProfile) {
        self.initialWeightKg = initialWeightKg
        self.profile = profile
        _targetWeightKg = State(initialValue: max(initialWeightKg, profile.barbellWeightKg))
    }

    public var plateResult: PlateLoadingResult {
        EquipmentMath.calculatePlates(
            targetWeightKg: targetWeightKg,
            barWeightKg: profile.barbellWeightKg,
            availablePlatesKg: profile.availablePlatesKg
        )
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // Target Weight Stepper
                        VStack(spacing: 8) {
                            Text("TARGET BARBELL WEIGHT")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                                .tracking(1.2)

                            HStack(spacing: 20) {
                                Button {
                                    adjustWeight(-profile.smallestBarbellJumpKg)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(selectedTheme.primaryAccent)
                                }

                                Text("\(formatKg(targetWeightKg))")
                                    .font(.system(size: 40, weight: .black, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(selectedTheme.textPrimary)

                                Button {
                                    adjustWeight(profile.smallestBarbellJumpKg)
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(selectedTheme.primaryAccent)
                                }
                            }

                            Text("Bar Weight: \(formatKg(profile.barbellWeightKg)) • Per Side: \(formatKg(plateResult.weightPerSideKg))")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedTheme.secondaryAccent)
                        }
                        .padding(20)
                        .glassCard(cornerRadius: 20)
                        .padding(.horizontal, 20)

                        // Barbell Sleeve Graphic
                        VStack(spacing: 12) {
                            Text("BARBELL SLEEVE (ONE SIDE)")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                                .tracking(1.2)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            ZStack(alignment: .leading) {
                                // Collar & Bar
                                HStack(spacing: 0) {
                                    // Collar
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color.gray.opacity(0.8))
                                        .frame(width: 14, height: 75)

                                    // Sleeve Bar
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.3)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: 22)
                                }

                                // Loaded Plates on Sleeve
                                HStack(spacing: 3) {
                                    Spacer().frame(width: 16)
                                    ForEach(Array(plateResult.platesPerSide.enumerated()), id: \.offset) { _, plate in
                                        PlateView(weight: plate)
                                    }
                                }
                            }
                            .frame(height: 120)
                            .padding(.vertical, 8)

                            if !plateResult.isExact {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(selectedTheme.warningStalled)
                                    Text("Cannot load exact weight. Short by \(formatKg(plateResult.remainderKg))")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(selectedTheme.warningStalled)
                                }
                            }
                        }
                        .padding(20)
                        .glassCard(cornerRadius: 20, strokeColor: selectedTheme.secondaryAccent.opacity(0.4))
                        .padding(.horizontal, 20)

                        // Plates Breakdown List
                        VStack(alignment: .leading, spacing: 10) {
                            Text("PLATES REQUIRED PER SIDE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                                .tracking(1.2)

                            let plateCounts = Dictionary(grouping: plateResult.platesPerSide, by: { $0 })
                                .mapValues { $0.count }
                                .sorted { $0.key > $1.key }

                            if plateCounts.isEmpty {
                                Text("Empty bar — no plates needed.")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(plateCounts, id: \.key) { plate, count in
                                    HStack {
                                        Circle()
                                            .fill(plateColor(plate))
                                            .frame(width: 14, height: 14)
                                        Text("\(formatKg(plate)) plate")
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(selectedTheme.textPrimary)
                                        Spacer()
                                        Text("× \(count)")
                                            .font(.system(size: 16, weight: .black, design: .rounded))
                                            .monospacedDigit()
                                            .foregroundColor(selectedTheme.secondaryAccent)
                                    }
                                    .padding(.vertical, 4)
                                    Divider().background(selectedTheme.stroke.opacity(0.5))
                                }
                            }
                        }
                        .padding(20)
                        .glassCard(cornerRadius: 20)
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Plate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(selectedTheme.secondaryAccent)
                }
            }
        }
    }

    private func adjustWeight(_ delta: Double) {
        let newWeight = max(profile.barbellWeightKg, targetWeightKg + delta)
        targetWeightKg = newWeight
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    private func formatKg(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(val))kg"
        }
        return String(format: "%.1fkg", val)
    }

    private func plateColor(_ weight: Double) -> Color {
        switch weight {
        case 25: return Color(hex: "#EF4444") // Red
        case 20: return Color(hex: "#3B82F6") // Blue
        case 15: return Color(hex: "#EAB308") // Yellow
        case 10: return Color(hex: "#22C55E") // Green
        case 5:  return Color(hex: "#F8FAFC") // White
        case 2.5: return Color(hex: "#1E293B") // Black
        case 1.25: return Color(hex: "#94A3B8") // Silver
        default: return Color(hex: "#8B5CF6")
        }
    }
}

public struct PlateView: View {
    public let weight: Double

    private var height: CGFloat {
        switch weight {
        case 25: return 100
        case 20: return 92
        case 15: return 84
        case 10: return 72
        case 5:  return 58
        case 2.5: return 48
        default: return 40
        }
    }

    private var width: CGFloat {
        switch weight {
        case 25, 20: return 18
        case 15, 10: return 14
        default: return 10
        }
    }

    private var color: Color {
        switch weight {
        case 25: return Color(hex: "#EF4444")
        case 20: return Color(hex: "#3B82F6")
        case 15: return Color(hex: "#EAB308")
        case 10: return Color(hex: "#22C55E")
        case 5:  return Color(hex: "#F8FAFC")
        case 2.5: return Color(hex: "#334155")
        default: return Color(hex: "#94A3B8")
        }
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: width, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.black.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.4), radius: 3)
    }
}
