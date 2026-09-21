import SwiftUI

public struct ConstellationNode: Identifiable {
    public let id: String
    public let name: String
    public let score: Double // 0.0 ... 1.0
    public let icon: String
}

public struct StrengthConstellationView: View {
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    public let nodes: [ConstellationNode]

    @State private var animatedScores: [Double] = []

    public init(nodes: [ConstellationNode]) {
        self.nodes = nodes
    }

    public var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) * 0.36
            let count = max(nodes.count, 3)

            ZStack {
                // Background concentric orbit rings (spider/radar grid)
                ForEach([0.25, 0.50, 0.75, 1.0], id: \.self) { level in
                    polygonPath(center: center, radius: radius * level, count: count)
                        .stroke(selectedTheme.stroke.opacity(level == 1.0 ? 0.6 : 0.25), lineWidth: 1)
                }

                // Radial spoke lines from center to outer vertices
                ForEach(0..<count, id: \.self) { i in
                    let angle = angleForIndex(i, total: count)
                    let outerPoint = pointOnCircle(center: center, radius: radius, angle: angle)
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: outerPoint)
                    }
                    .stroke(selectedTheme.stroke.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }

                // Constellation polygon fill
                constellationPolygonPath(center: center, radius: radius)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                selectedTheme.primaryAccent.opacity(0.45),
                                selectedTheme.secondaryAccent.opacity(0.18),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: radius
                        )
                    )

                // Constellation polygon border
                constellationPolygonPath(center: center, radius: radius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                selectedTheme.secondaryAccent,
                                selectedTheme.primaryAccent,
                                selectedTheme.tertiaryAccent
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )

                // Star nodes on vertices & Labels
                ForEach(0..<nodes.count, id: \.self) { i in
                    let angle = angleForIndex(i, total: count)
                    let score = i < animatedScores.count ? animatedScores[i] : 0.0
                    let nodeRadius = radius * CGFloat(max(score, 0.15))
                    let vertex = pointOnCircle(center: center, radius: nodeRadius, angle: angle)

                    // Glowing Star Vertex
                    ZStack {
                        Circle()
                            .fill(selectedTheme.secondaryAccent.opacity(0.4))
                            .frame(width: 14, height: 14)
                            .blur(radius: 4)

                        Circle()
                            .fill(selectedTheme.secondaryAccent)
                            .frame(width: 7, height: 7)
                            .shadow(color: .white, radius: 2)
                    }
                    .position(vertex)

                    // Node Label positioned just outside outer radius
                    let labelRadius = radius + 28
                    let labelPoint = pointOnCircle(center: center, radius: labelRadius, angle: angle)

                    VStack(spacing: 2) {
                        Image(systemName: nodes[i].icon)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(selectedTheme.secondaryAccent)

                        Text(nodes[i].name)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)

                        Text("\(Int(score * 100))%")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(selectedTheme.textSecondary)
                    }
                    .position(labelPoint)
                }
            }
        }
        .onAppear {
            animatedScores = nodes.map { _ in 0.1 }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedScores = nodes.map { $0.score }
            }
        }
        .onChange(of: nodes.map(\.score)) { newScores in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedScores = newScores
            }
        }
    }

    private func angleForIndex(_ index: Int, total: Int) -> Double {
        return (Double(index) / Double(total)) * 2 * .pi - (.pi / 2)
    }

    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(cos(angle)),
            y: center.y + radius * CGFloat(sin(angle))
        )
    }

    private func polygonPath(center: CGPoint, radius: CGFloat, count: Int) -> Path {
        var path = Path()
        guard count > 0 else { return path }
        for i in 0..<count {
            let angle = angleForIndex(i, total: count)
            let pt = pointOnCircle(center: center, radius: radius, angle: angle)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        return path
    }

    private func constellationPolygonPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        let count = nodes.count
        guard count > 0 else { return path }

        for i in 0..<count {
            let angle = angleForIndex(i, total: count)
            let score = i < animatedScores.count ? animatedScores[i] : 0.0
            let pt = pointOnCircle(center: center, radius: radius * CGFloat(max(score, 0.15)), angle: angle)
            if i == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        return path
    }
}
