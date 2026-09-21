import SwiftUI
import SwiftData

public struct ExerciseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup? = nil
    @State private var selectedEquipment: EquipmentType? = nil
    @State private var showingCreateSheet = false
    @State private var newCreatedExercise: Exercise? = nil

    public var filteredExercises: [Exercise] {
        exercises.filter { ex in
            let matchesSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            let matchesGroup = selectedMuscleGroup == nil || ex.muscleGroup == selectedMuscleGroup
            let matchesEq = selectedEquipment == nil || ex.equipment == selectedEquipment
            return matchesSearch && matchesGroup && matchesEq && !ex.isArchived
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                VStack(spacing: 12) {
                    // Search Bar
                    TextField("Search \(exercises.count) exercises...", text: $searchText)
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
                            FilterPill(title: "All Muscles", isSelected: selectedMuscleGroup == nil) {
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

                    // Equipment Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(title: "All Equipment", isSelected: selectedEquipment == nil) {
                                selectedEquipment = nil
                            }

                            ForEach(EquipmentType.allCases) { eq in
                                FilterPill(title: eq.displayName, isSelected: selectedEquipment == eq) {
                                    selectedEquipment = eq
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Exercise List
                    List(filteredExercises) { exercise in
                        NavigationLink {
                            ExerciseDetailView(exercise: exercise)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: exercise.muscleGroup.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedTheme.secondaryAccent)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(exercise.name)
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)

                                    HStack(spacing: 6) {
                                        Text(exercise.muscleGroup.displayName)
                                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                                            .foregroundColor(selectedTheme.secondaryAccent)

                                        Text("•")
                                            .foregroundColor(selectedTheme.textMuted)

                                        Text(exercise.equipment.displayName)
                                            .font(.system(size: 11, weight: .regular, design: .rounded))
                                            .foregroundColor(selectedTheme.textSecondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(selectedTheme.textMuted)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(selectedTheme.surfaceCard.opacity(0.35))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Exercise Library")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        createNewExercise()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(selectedTheme.secondaryAccent)
                    }
                }
            }
            .sheet(item: $newCreatedExercise) { ex in
                ExerciseEditView(exercise: ex)
            }
        }
    }

    private func createNewExercise() {
        let exercise = Exercise(
            name: "New Exercise",
            muscleGroup: selectedMuscleGroup ?? .chest,
            equipment: selectedEquipment ?? .barbell
        )
        modelContext.insert(exercise)
        newCreatedExercise = exercise
    }
}
