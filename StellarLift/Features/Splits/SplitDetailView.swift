import SwiftUI
import SwiftData

public struct SplitDetailView: View {
    @Bindable var splitDay: SplitDay
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var showingAddExerciseSheet = false
    @State private var selectedColorHex: String = "#7C5CFF"

    let availableColors = [
        "#7C5CFF", "#38E8FF", "#FF6AD5", "#4ADE80",
        "#FBBF24", "#FB7185", "#06B6D4", "#8B5CF6", "#64748B"
    ]

    public var body: some View {
        ZStack {
            StarfieldBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Split Info Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("SPLIT CONFIGURATION")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)

                        TextField("Split Name (e.g. Push A)", text: $splitDay.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(selectedTheme.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedTheme.stroke, lineWidth: 1))

                        // Cardio Day Toggle
                        Toggle(isOn: $splitDay.isCardioDay) {
                            HStack(spacing: 10) {
                                Image(systemName: "figure.run")
                                    .foregroundColor(selectedTheme.secondaryAccent)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Cardio Day")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)
                                    Text("Logs duration, distance, and zone instead of heavy sets")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondary)
                                }
                            }
                        }
                        .tint(selectedTheme.primaryAccent)

                        // Color Picker Row
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Theme Color")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)

                            HStack(spacing: 12) {
                                ForEach(availableColors, id: \.self) { hex in
                                    Circle()
                                        .fill(Color(hex: hex))
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: splitDay.colorHex == hex ? 3 : 0)
                                        )
                                        .shadow(color: Color(hex: hex).opacity(0.5), radius: 6)
                                        .onTapGesture {
                                            splitDay.colorHex = hex
                                        }
                                }
                            }
                        }
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20, strokeColor: Color(hex: splitDay.colorHex).opacity(0.4))
                    .padding(.horizontal, 20)

                    // Planned Exercises List
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("PLANNED EXERCISES (\(splitDay.plannedExercises.count))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                                .tracking(1.2)
                            Spacer()
                            Button {
                                showingAddExerciseSheet = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                }
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.secondaryAccent)
                            }
                        }
                        .padding(.horizontal, 4)

                        if splitDay.plannedExercises.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "dumbbell")
                                    .font(.system(size: 32))
                                    .foregroundColor(selectedTheme.textMuted)
                                Text("No exercises planned for this day")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .glassCard(cornerRadius: 18)
                        } else {
                            ForEach(splitDay.sortedPlannedExercises) { planned in
                                PlannedExerciseRow(planned: planned) {
                                    deletePlanned(planned)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(splitDay.name.isEmpty ? "Edit Split" : splitDay.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddExerciseSheet) {
            AddExerciseToSplitSheet(allExercises: allExercises) { selectedExercise in
                let newPlanned = PlannedExercise(
                    exercise: selectedExercise,
                    targetSets: 3,
                    targetRepLow: selectedExercise.defaultRepRangeLow,
                    targetRepHigh: selectedExercise.defaultRepRangeHigh,
                    restSeconds: 90,
                    orderIndex: splitDay.plannedExercises.count,
                    splitDay: splitDay
                )
                splitDay.plannedExercises.append(newPlanned)
                modelContext.insert(newPlanned)
                try? modelContext.save()
            }
        }
    }

    private func deletePlanned(_ planned: PlannedExercise) {
        if let idx = splitDay.plannedExercises.firstIndex(where: { $0.id == planned.id }) {
            splitDay.plannedExercises.remove(at: idx)
            modelContext.delete(planned)
            try? modelContext.save()
        }
    }
}

public struct PlannedExerciseRow: View {
    @Bindable var planned: PlannedExercise
    public let onDelete: () -> Void
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(planned.exercise?.name ?? "Custom Exercise")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)

                    if let group = planned.exercise?.muscleGroup {
                        Text(group.displayName)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedTheme.secondaryAccent)
                    }
                }
                Spacer()

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(selectedTheme.danger.opacity(0.8))
                }
            }

            Divider()
                .background(selectedTheme.stroke)

            // Targets Editor (Sets, Reps, Rest)
            HStack(spacing: 12) {
                // Target Sets
                VStack(alignment: .leading, spacing: 4) {
                    Text("SETS")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)

                    Stepper(value: $planned.targetSets, in: 1...10) {
                        Text("\(planned.targetSets)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(selectedTheme.textPrimary)
                    }
                }

                // Rep Range
                VStack(alignment: .leading, spacing: 4) {
                    Text("REPS")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)

                    HStack(spacing: 4) {
                        TextField("Low", value: $planned.targetRepLow, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 32)
                            .padding(.vertical, 2)
                            .background(selectedTheme.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("–")
                            .foregroundColor(selectedTheme.textSecondary)
                        TextField("High", value: $planned.targetRepHigh, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 32)
                            .padding(.vertical, 2)
                            .background(selectedTheme.surfaceCard)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(selectedTheme.textPrimary)
                }

                // Rest Seconds
                VStack(alignment: .leading, spacing: 4) {
                    Text("REST")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)

                    Menu {
                        Button("60s") { planned.restSeconds = 60 }
                        Button("90s") { planned.restSeconds = 90 }
                        Button("120s") { planned.restSeconds = 120 }
                        Button("150s") { planned.restSeconds = 150 }
                        Button("180s") { planned.restSeconds = 180 }
                    } label: {
                        HStack(spacing: 2) {
                            Text("\(planned.restSeconds)s")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(selectedTheme.secondaryAccent)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(selectedTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 16, strokeColor: selectedTheme.stroke.opacity(0.8))
    }
}

public struct AddExerciseToSplitSheet: View {
    public let allExercises: [Exercise]
    public let onSelect: (Exercise) -> Void
    @Environment(\.dismiss) private var dismiss
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    @State private var searchText = ""

    public var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return allExercises
        }
        return allExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                VStack {
                    TextField("Search exercise library...", text: $searchText)
                        .padding(10)
                        .background(selectedTheme.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedTheme.stroke, lineWidth: 1))
                        .foregroundColor(selectedTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    List(filteredExercises) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)
                                    Text(exercise.muscleGroup.displayName + " • " + exercise.equipment.displayName)
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(selectedTheme.secondaryAccent)
                            }
                        }
                        .listRowBackground(selectedTheme.surfaceCard.opacity(0.4))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(selectedTheme.secondaryAccent)
                }
            }
        }
    }
}
