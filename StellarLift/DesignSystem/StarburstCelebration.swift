import SwiftUI

public struct Particle: Identifiable {
    public let id: Int
    public let angle: Double
    public let distance: CGFloat
    public let size: CGFloat
    public let color: Color
}

public struct StarburstCelebration: View {
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public let prText: String
    public let onDismiss: () -> Void

    @State private var animateBurst: Bool = false
    @State private var opacity: Double = 1.0

    private let particles: [Particle] = {
        var list: [Particle] = []
        let colors = [
            Color(hex: "#4ADE80"), // Success green
            Color(hex: "#38E8FF"), // Cyan
            Color(hex: "#FF6AD5"), // Nebula pink
            Color(hex: "#FBBF24"), // Gold
            Color.white
        ]
        for i in 0..<36 {
            let angle = Double(i) * (360.0 / 36.0)
            let distance = CGFloat(110 + (i % 5) * 20)
            let size = CGFloat(4 + (i % 3) * 3)
            let color = colors[i % colors.count]
            list.append(Particle(id: i, angle: angle, distance: distance, size: size, color: color))
        }
        return list
    }()

    public var body: some View {
        ZStack {
            // Dark scrim background
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Radial Starburst particles
            if !reduceMotion {
                ZStack {
                    ForEach(particles) { p in
                        let rad = p.angle * .pi / 180
                        let x = animateBurst ? cos(rad) * p.distance : 0
                        let y = animateBurst ? sin(rad) * p.distance : 0

                        Circle()
                            .fill(p.color)
                            .frame(width: p.size, height: p.size)
                            .shadow(color: p.color, radius: 6)
                            .offset(x: x, y: y)
                            .opacity(animateBurst ? 0.0 : 1.0)
                    }
                }
            }

            // Central PR Card
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [selectedTheme.successPR, selectedTheme.secondaryAccent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .shadow(color: selectedTheme.successPR.opacity(0.8), radius: 20)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                }
                .scaleEffect(animateBurst ? 1.0 : 0.4)

                Text("NEW PERSONAL RECORD!")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(selectedTheme.successPR)
                    .tracking(1.5)

                Text(prText)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)

                Text("Tap anywhere to continue")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
                    .padding(.top, 4)
            }
            .padding(28)
            .glassCard(cornerRadius: 24, strokeColor: selectedTheme.successPR, glowing: true, glowColor: selectedTheme.successPR)
            .scaleEffect(animateBurst ? 1.0 : 0.7)
            .opacity(opacity)
        }
        .onAppear {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                animateBurst = true
            }

            // Auto dismiss after 2.8 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onDismiss()
                }
            }
        }
    }
}
