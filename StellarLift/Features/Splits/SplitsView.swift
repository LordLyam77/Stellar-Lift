import SwiftUI
import SwiftData

public struct SplitsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SplitDay.orderIndex) private var splitDays: [SplitDay]
    @Query(sort: \WeeklySchedule.dayOfWeek) private var weeklySchedules: [WeeklySchedule]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var showingTemplatesSheet = false
    @State private var showingCreateSplitAlert = false
    @State private var newSplitName = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Weekly Schedule Grid (Mon - Sun)
                        weeklyScheduleSection

                        // 2. Split Routines List
                        splitDaysSection
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Splits & Schedule")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingTemplatesSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                            Text("Templates")
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.secondaryAccent)
                    }
                }
            }
            .sheet(isPresented: $showingTemplatesSheet) {
                TemplatesSheet()
            }
            .alert("New Split Day", isPresented: $showingCreateSplitAlert) {
                TextField("Split Name (e.g. Upper Body)", text: $newSplitName)
                Button("Cancel", role: .cancel) { newSplitName = "" }
                Button("Create") {
                    createNewSplit()
                }
            }
        }
    }

    // Weekly Schedule Grid
    private var weeklyScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("WEEKLY SCHEDULE (7 DAYS)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .tracking(1.2)
                Spacer()
                Text("Tap day to assign")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textMuted)
            }
            .padding(.horizontal, 20)

            // Mon - Sun ordering
            let mondayFirstDays = [2, 3, 4, 5, 6, 7, 1]
            VStack(spacing: 8) {
                ForEach(mondayFirstDays, id: \.self) { day in
                    let schedule = weeklySchedules.first { $0.dayOfWeek == day }
                    let split = schedule?.splitDay

                    HStack {
                        Text(schedule?.weekdayName ?? weekdayName(for: day))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)
                            .frame(width: 95, alignment: .leading)

                        Spacer()

                        Menu {
                            Button("Rest Day") {
                                assignSplit(nil, to: day)
                            }
                            Divider()
                            ForEach(splitDays) { s in
                                Button(s.name) {
                                    assignSplit(s, to: day)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if let split = split {
                                    Circle()
                                        .fill(Color(hex: split.colorHex))
                                        .frame(width: 8, height: 8)
                                    Text(split.name)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)
                                } else {
                                    Circle()
                                        .fill(Color.gray.opacity(0.4))
                                        .frame(width: 8, height: 8)
                                    Text("Rest Day")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(selectedTheme.textSecondary)
                                }
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundColor(selectedTheme.textSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(selectedTheme.surfaceCard)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selectedTheme.stroke, lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .glassCard(cornerRadius: 14)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // Split Days Section
    private var splitDaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("YOUR SPLIT ROUTINES (\(splitDays.count))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .tracking(1.2)
                Spacer()
                Button {
                    showingCreateSplitAlert = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("New Split")
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.secondaryAccent)
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 10) {
                ForEach(splitDays) { split in
                    NavigationLink {
                        SplitDetailView(splitDay: split)
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(Color(hex: split.colorHex))
                                .frame(width: 14, height: 14)
                                .shadow(color: Color(hex: split.colorHex).opacity(0.8), radius: 6)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(split.name)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)

                                Text(split.isCardioDay ? "Cardio Focus" : "\(split.plannedExercises.count) Planned Exercises")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(selectedTheme.textMuted)
                        }
                        .padding(16)
                        .glassCard(cornerRadius: 18, strokeColor: Color(hex: split.colorHex).opacity(0.35))
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func weekdayName(for day: Int) -> String {
        switch day {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return ""
        }
    }

    private func assignSplit(_ split: SplitDay?, to day: Int) {
        if let schedule = weeklySchedules.first(where: { $0.dayOfWeek == day }) {
            schedule.splitDay = split
        } else {
            let newSched = WeeklySchedule(dayOfWeek: day, splitDay: split)
            modelContext.insert(newSched)
        }
        try? modelContext.save()
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
    }

    private func createNewSplit() {
        guard !newSplitName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let split = SplitDay(
            name: newSplitName,
            colorHex: "#7C5CFF",
            orderIndex: splitDays.count
        )
        modelContext.insert(split)
        try? modelContext.save()
        newSplitName = ""
    }
}
