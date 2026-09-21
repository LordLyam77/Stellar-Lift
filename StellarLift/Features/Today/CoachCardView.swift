import SwiftUI

public struct CoachCardView: View {
    public let insight: ProgressionInsight
    public let onTap: () -> Void

    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    @State private var isPulsing: Bool = false

    public var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                // Header badge
                HStack {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color(hex: insight.verdict.badgeColorHex))
                            .frame(width: 7, height: 7)
                        Text(insight.verdict.title.uppercased())
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: insight.verdict.badgeColorHex))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: insight.verdict.badgeColorHex).opacity(0.18))
                    .clipShape(Capsule())

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(selectedTheme.textMuted)
                }

                // Exercise Name
                Text(insight.exerciseName)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(selectedTheme.textPrimary)

                // Insight Message
                Text(insight.message)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                // Current vs Suggested
                if let suggested = insight.suggestedWeightKg {
                    HStack(spacing: 6) {
                        Text("\(format(insight.currentWeightKg))kg")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textMuted)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(selectedTheme.secondaryAccent)
                        Text("\(format(suggested))kg")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: insight.verdict.badgeColorHex))
                    }
                }
            }
            .padding(14)
            .frame(width: 260, height: 165)
            .glassCard(
                cornerRadius: 18,
                strokeColor: Color(hex: insight.verdict.badgeColorHex).opacity(insight.verdict == .stagnantLong ? 0.8 : 0.4),
                glowing: insight.verdict == .stagnantLong,
                glowColor: Color(hex: insight.verdict.badgeColorHex).opacity(isPulsing ? 0.5 : 0.2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .onAppear {
            if insight.verdict == .stagnantLong {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }

    private func format(_ val: Double) -> String {
        if val.truncatingRemainder(dividingBy: 1.0) == 0 {
            return "\(Int(val))"
        }
        return String(format: "%.1f", val)
    }
}
