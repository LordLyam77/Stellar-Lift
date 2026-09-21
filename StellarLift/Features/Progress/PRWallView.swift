import SwiftUI
import SwiftData

public struct PRWallView: View {
    @Query(sort: \PersonalRecord.date, order: .reverse) private var allPRs: [PersonalRecord]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    @State private var selectedFilter: RecordType? = nil

    public var filteredPRs: [PersonalRecord] {
        if let filter = selectedFilter {
            return allPRs.filter { $0.recordType == filter }
        }
        return allPRs
    }

    public var body: some View {
        ZStack {
            StarfieldBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Header banner
                    VStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 36))
                            .foregroundColor(selectedTheme.successPR)
                            .shadow(color: selectedTheme.successPR.opacity(0.8), radius: 16)

                        Text("HALL OF CONQUEST")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(selectedTheme.secondaryAccent)
                            .tracking(2.0)

                        Text("\(allPRs.count) Personal Records")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)
                    }
                    .padding(.top, 8)

                    // Record Type Filter Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterPill(title: "All PRs", isSelected: selectedFilter == nil) {
                                selectedFilter = nil
                            }
                            ForEach(RecordType.allCases, id: \.self) { type in
                                FilterPill(title: type.displayName, isSelected: selectedFilter == type) {
                                    selectedFilter = type
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // PR Grid
                    if filteredPRs.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 32))
                                .foregroundColor(selectedTheme.textMuted)
                            Text("No PRs recorded yet for this category.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                        }
                        .padding(40)
                        .glassCard(cornerRadius: 18)
                        .padding(.horizontal, 20)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(filteredPRs) { pr in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Image(systemName: pr.recordType.iconName)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(selectedTheme.successPR)
                                        Spacer()
                                        Text(pr.recordType.displayName)
                                            .font(.system(size: 9, weight: .bold, design: .rounded))
                                            .foregroundColor(selectedTheme.textSecondary)
                                    }

                                    Text(pr.exerciseName)
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(selectedTheme.textPrimary)
                                        .lineLimit(1)

                                    Text("\(formatValue(pr.value)) \(pr.recordType.unitSuffix)")
                                        .font(.system(size: 20, weight: .black, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundColor(selectedTheme.successPR)

                                    Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(selectedTheme.textMuted)
                                }
                                .padding(14)
                                .glassCard(cornerRadius: 16, strokeColor: selectedTheme.successPR.opacity(0.35))
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("PR Constellation Wall")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func formatValue(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(val))"
        }
        return String(format: "%.1f", val)
    }
}
