import SwiftUI
import SwiftData

public struct UnplannedExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    public let onSelect: (Exercise) -> Void
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup? = nil

    public var filteredExercises: [Exercise] {
        allExercises.filter { ex in
            let matchesSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesGroup = selectedMuscleGroup == nil || ex.muscleGroup == selectedMuscleGroup
            return matchesSearch && matchesGroup && !ex.isArchived
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                VStack(spacing: 12) {
                    // Search Bar
                    TextField("Search exercise library...", text: $searchText)
                        .padding(10)
                        .background(selectedTheme.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedTheme.stroke, lineWidth: 1))
                        .foregroundColor(selectedTheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Muscle Group Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(title: "All", isSelected: selectedMuscleGroup == nil) {
                                selectedMuscleGroup = nil
                            }

                            ForEach(MuscleGroup.allCases) { group in
                                FilterPill(title: group.displayName, isSelected: selectedMuscleGroup == group) {
                                    selectedMuscleGroup = group
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Exercise Results List
                    List(filteredExercises) { exercise in
                        Button {
                            onSelect(exercise)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: exercise.muscleGroup.iconName)
                                    .foregroundColor(selectedTheme.secondaryAccent)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)

                                    Text("\(exercise.muscleGroup.displayName) • \(exercise.equipment.displayName)")
                                        .font(.system(size: 11, weight: .medium, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(selectedTheme.primaryAccent)
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

public struct FilterPill: View {
    public let title: String
    public let isSelected: Bool
    public let action: () -> Void
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? selectedTheme.primaryAccent : selectedTheme.surfaceCard)
                .foregroundColor(isSelected ? .white : selectedTheme.textSecondary)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? selectedTheme.primaryAccent : selectedTheme.stroke, lineWidth: 1))
        }
    }
}
