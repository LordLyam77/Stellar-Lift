import SwiftUI

public struct OrbitRestTimerView: View {
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    public let totalSeconds: Int
    public let remainingSeconds: Int
    public let onAdd30s: () -> Void
    public let onSkip: () -> Void

    public var body: some View {
        let progress = totalSeconds > 0 ? (1.0 - Double(remainingSeconds) / Double(totalSeconds)) : 1.0

        HStack(spacing: 16) {
            // Orbit ring with planet
            ZStack {
                // Background orbit path
                Circle()
                    .stroke(selectedTheme.stroke.opacity(0.6), lineWidth: 3)
                    .frame(width: 52, height: 52)

                // Active progress arc
                Circle()
                    .trim(from: 0, to: CGFloat(min(max(progress, 0), 1.0)))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                selectedTheme.secondaryAccent,
                                selectedTheme.primaryAccent,
                                selectedTheme.tertiaryAccent
                            ]),
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 52, height: 52)
                    .animation(.linear(duration: 1.0), value: progress)

                // Orbiting Planet
                let angle = (progress * 360.0) - 90.0
                let radius: CGFloat = 26.0
                let planetX = radius * cos(CGFloat(angle * .pi / 180))
                let planetY = radius * sin(CGFloat(angle * .pi / 180))

                Circle()
                    .fill(selectedTheme.secondaryAccent)
                    .frame(width: 7, height: 7)
                    .shadow(color: selectedTheme.secondaryAccent, radius: 5)
                    .offset(x: planetX, y: planetY)
                    .animation(.linear(duration: 1.0), value: progress)

                // Center Icon or Seconds
                Image(systemName: "timer")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.secondaryAccent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("REST TIMER")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .tracking(1.2)

                Text(formatTime(remainingSeconds))
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(selectedTheme.textPrimary)
            }

            Spacer()

            // +30s Button
            Button(action: onAdd30s) {
                Text("+30s")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(selectedTheme.surfaceCard)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(selectedTheme.stroke, lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())

            // Skip Button
            Button(action: onSkip) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .padding(8)
                    .background(selectedTheme.surfaceCard)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(selectedTheme.stroke, lineWidth: 1))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 18, strokeColor: selectedTheme.primaryAccent.opacity(0.4), glowing: true, glowColor: selectedTheme.primaryAccent.opacity(0.2))
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        let s = max(0, seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
