import SwiftUI
import SwiftData

public struct HistorySearchResult: Identifiable {
    public let id = UUID()
    public let sessionDate: Date
    public let splitName: String
    public let exerciseName: String
    public let sets: [SetEntry]
    public let topWeight: Double
    public let topReps: Int
}

public struct HistorySearchView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var queryText: String = ""

    public var searchResults: [HistorySearchResult] {
        guard !queryText.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let cleanQuery = queryText.lowercased()

        // Check if query specifies weight like "100kg" or "100"
        var targetWeight: Double? = nil
        let numbers = cleanQuery.components(separatedBy: CharacterSet.decimalDigits.inverted).filter { !$0.isEmpty }
        if let firstNum = numbers.first, let val = Double(firstNum) {
            targetWeight = val
        }

        var results: [HistorySearchResult] = []

        for session in allSessions where session.isFinished {
            for perf in session.performedExercises {
                let nameMatches = perf.exerciseName.lowercased().contains(cleanQuery)
                let weightMatches = targetWeight != nil ? perf.sets.contains(where: { abs($0.weightKg - targetWeight!) < 0.5 }) : false

                if nameMatches || weightMatches {
                    let maxW = perf.sets.map(\.weightKg).max() ?? 0
                    let bestR = perf.sets.filter { $0.weightKg == maxW }.map(\.reps).max() ?? 0

                    results.append(HistorySearchResult(
                        sessionDate: session.date,
                        splitName: session.splitDayName,
                        exerciseName: perf.exerciseName,
                        sets: perf.sortedSets,
                        topWeight: maxW,
                        topReps: bestR
                    ))
                }
            }
        }
        return results
    }

    public var body: some View {
        ZStack {
            StarfieldBackground()

            VStack(spacing: 12) {
                // Search Input Field
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(selectedTheme.textSecondary)

                    TextField("Search history (e.g. Deadlift, 100kg)...", text: $queryText)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)

                    if !queryText.isEmpty {
                        Button {
                            queryText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(selectedTheme.textMuted)
                        }
                    }
                }
                .padding(12)
                .background(selectedTheme.surfaceCard)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedTheme.stroke, lineWidth: 1))
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Results List
                if searchResults.isEmpty {
                    VStack(spacing: 10) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 36))
                            .foregroundColor(selectedTheme.textMuted)
                        Text(queryText.isEmpty ? "Type an exercise name or weight to search previous logs." : "No matching sessions found.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer()
                    }
                } else {
                    List(searchResults) { res in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(res.exerciseName)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)
                                Spacer()
                                Text(res.sessionDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedTheme.secondaryAccent)
                            }

                            HStack {
                                Text(res.splitName)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)
                                Spacer()
                                Text("Top: \(formatWeight(res.topWeight)) × \(res.topReps)")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(selectedTheme.primaryAccent)
                            }

                            // Sets chips
                            HStack(spacing: 6) {
                                ForEach(res.sets) { s in
                                    Text("\(formatWeight(s.weightKg))×\(s.reps)")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .monospacedDigit()
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(selectedTheme.surfaceCard)
                                        .foregroundColor(selectedTheme.textSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(.top, 2)
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(selectedTheme.surfaceCard.opacity(0.35))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("History Search")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatWeight(_ kg: Double) -> String {
        if kg.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(kg))kg"
        }
        return String(format: "%.1fkg", kg)
    }
}
