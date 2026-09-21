import SwiftUI

public struct SetRowView: View {
    @Bindable var setEntry: SetEntry
    public let previousText: String?
    public let previousWeight: Double?
    public let previousReps: Int?
    public let equipment: EquipmentType
    public let profile: EquipmentProfile
    public let onCompleteSet: () -> Void
    public let onDeleteSet: () -> Void

    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    @State private var isCompleted: Bool = false
    @State private var showingContextMenu: Bool = false

    public init(
        setEntry: SetEntry,
        previousText: String?,
        previousWeight: Double?,
        previousReps: Int?,
        equipment: EquipmentType,
        profile: EquipmentProfile,
        onCompleteSet: @escaping () -> Void,
        onDeleteSet: @escaping () -> Void
    ) {
        self.setEntry = setEntry
        self.previousText = previousText
        self.previousWeight = previousWeight
        self.previousReps = previousReps
        self.equipment = equipment
        self.profile = profile
        self.onCompleteSet = onCompleteSet
        self.onDeleteSet = onDeleteSet
        _isCompleted = State(initialValue: setEntry.reps > 0 && setEntry.weightKg > 0)
    }

    public var weightStep: Double {
        switch equipment {
        case .dumbbell: return 2.5
        case .barbell: return profile.smallestBarbellJumpKg
        case .machine, .cable: return profile.machineIncrementKg
        default: return 2.5
        }
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Set Number + Type tag
            VStack(spacing: 2) {
                Text("\(setEntry.setNumber)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(badgeColor)

                if setEntry.isWarmup {
                    Text("W")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.warningStalled)
                } else if setEntry.isDropSet {
                    Text("D")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.secondaryAccent)
                } else if setEntry.isFailure {
                    Text("F")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.danger)
                }
            }
            .frame(width: 26)

            // Previous Column (Non-negotiable)
            Button {
                autoFillFromPrevious()
            } label: {
                if let prev = previousText, !prev.isEmpty {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(prev)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(selectedTheme.textMuted)
                        Text("tap to copy")
                            .font(.system(size: 8, weight: .medium, design: .rounded))
                            .foregroundColor(selectedTheme.secondaryAccent.opacity(0.8))
                    }
                    .frame(width: 68, alignment: .leading)
                } else {
                    Text("—")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(selectedTheme.textMuted.opacity(0.5))
                        .frame(width: 68, alignment: .center)
                }
            }
            .buttonStyle(.plain)

            // Weight Column (Stepper + Input)
            HStack(spacing: 2) {
                Button {
                    stepWeight(-weightStep)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(selectedTheme.textSecondary)
                        .frame(width: 20, height: 28)
                        .background(selectedTheme.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                TextField("0", value: $setEntry.weightKg, format: .number)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .frame(width: 44, height: 28)
                    .background(selectedTheme.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .foregroundColor(selectedTheme.textPrimary)

                Button {
                    stepWeight(weightStep)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(selectedTheme.textSecondary)
                        .frame(width: 20, height: 28)
                        .background(selectedTheme.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Reps Column (Stepper + Input)
            HStack(spacing: 2) {
                Button {
                    stepReps(-1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(selectedTheme.textSecondary)
                        .frame(width: 20, height: 28)
                        .background(selectedTheme.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }

                TextField("0", value: $setEntry.reps, format: .number)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(width: 36, height: 28)
                    .background(selectedTheme.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .foregroundColor(selectedTheme.textPrimary)

                Button {
                    stepReps(1)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(selectedTheme.textSecondary)
                        .frame(width: 20, height: 28)
                        .background(selectedTheme.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            Spacer()

            // Completion Checkmark Button
            Button {
                toggleCompletion()
            } label: {
                ZStack {
                    Circle()
                        .fill(isCompleted ? selectedTheme.successPR : selectedTheme.surfaceCard)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(isCompleted ? selectedTheme.successPR : selectedTheme.stroke, lineWidth: 1.5)
                        )

                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(isCompleted ? .black : selectedTheme.textMuted)
                }
                .shadow(color: isCompleted ? selectedTheme.successPR.opacity(0.4) : Color.clear, radius: 6)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCompleted ? selectedTheme.successPR.opacity(0.08) : Color.clear)
        )
        .contextMenu {
            Button {
                setEntry.isWarmup.toggle()
                if setEntry.isWarmup { setEntry.isDropSet = false; setEntry.isFailure = false }
            } label: {
                Label(setEntry.isWarmup ? "Unmark Warm-Up" : "Mark as Warm-Up", systemImage: "flame")
            }

            Button {
                setEntry.isDropSet.toggle()
                if setEntry.isDropSet { setEntry.isWarmup = false }
            } label: {
                Label(setEntry.isDropSet ? "Unmark Drop Set" : "Mark as Drop Set", systemImage: "arrow.down.circle")
            }

            Button {
                setEntry.isFailure.toggle()
                if setEntry.isFailure { setEntry.isWarmup = false }
            } label: {
                Label(setEntry.isFailure ? "Unmark Failure" : "Mark as Taken to Failure", systemImage: "bolt.fill")
            }

            Divider()

            Button(role: .destructive) {
                onDeleteSet()
            } label: {
                Label("Delete Set", systemImage: "trash")
            }
        }
    }

    private var badgeColor: Color {
        if isCompleted { return selectedTheme.successPR }
        if setEntry.isWarmup { return selectedTheme.warningStalled }
        if setEntry.isFailure { return selectedTheme.danger }
        return selectedTheme.textSecondary
    }

    private func autoFillFromPrevious() {
        if let w = previousWeight {
            setEntry.weightKg = w
        }
        if let r = previousReps {
            setEntry.reps = r
        }
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
    }

    private func stepWeight(_ delta: Double) {
        setEntry.weightKg = max(0, setEntry.weightKg + delta)
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    private func stepReps(_ delta: Int) {
        setEntry.reps = max(0, setEntry.reps + delta)
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    private func toggleCompletion() {
        isCompleted.toggle()
        if isCompleted {
            setEntry.completedAt = Date()
            let haptic = UIImpactFeedbackGenerator(style: .heavy)
            haptic.impactOccurred()
            onCompleteSet()
        }
    }
}
