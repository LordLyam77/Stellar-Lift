import SwiftUI

public struct Star: Identifiable, Sendable {
    public let id: Int
    public let x: CGFloat // 0.0 ... 1.0 normalized
    public let y: CGFloat // 0.0 ... 1.0 normalized
    public let size: CGFloat
    public let layer: Int // 1, 2, or 3
    public let baseOpacity: Double
    public let twinkleSpeed: Double
    public let twinkleOffset: Double
}

public struct StarfieldBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    // Fixed deterministic star distribution across 3 layers
    private let stars: [Star] = {
        var generated: [Star] = []
        // Deterministic pseudo-random seed generator
        var seed: UInt64 = 133742
        func rand() -> Double {
            seed = (seed &* 6364136223846793005 &+ 1)
            return Double((seed >> 32) & 0xFFFFFFFF) / Double(0xFFFFFFFF)
        }

        // Layer 1: 70 micro stars (deep background, slow twinkle)
        for i in 0..<70 {
            generated.append(Star(
                id: i,
                x: rand(),
                y: rand(),
                size: 0.8 + rand() * 0.8,
                layer: 1,
                baseOpacity: 0.15 + rand() * 0.25,
                twinkleSpeed: 0.8 + rand() * 1.2,
                twinkleOffset: rand() * .pi * 2
            ))
        }

        // Layer 2: 45 medium stars (midground)
        for i in 70..<115 {
            generated.append(Star(
                id: i,
                x: rand(),
                y: rand(),
                size: 1.4 + rand() * 1.0,
                layer: 2,
                baseOpacity: 0.25 + rand() * 0.25,
                twinkleSpeed: 1.5 + rand() * 1.5,
                twinkleOffset: rand() * .pi * 2
            ))
        }

        // Layer 3: 20 prominent glowing stars (foreground)
        for i in 115..<135 {
            generated.append(Star(
                id: i,
                x: rand(),
                y: rand(),
                size: 2.2 + rand() * 1.2,
                layer: 3,
                baseOpacity: 0.35 + rand() * 0.20, // capped well below 0.6
                twinkleSpeed: 2.0 + rand() * 2.0,
                twinkleOffset: rand() * .pi * 2
            ))
        }
        return generated
    }()

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                // Base background color
                selectedTheme.backgroundDeep
                    .ignoresSafeArea()

                // Radial nebula blobs
                nebulaBlobs(size: size)

                // 30fps capped TimelineView for parallax & twinkle
                if reduceMotion || scenePhase != .active {
                    staticCanvas(size: size)
                } else {
                    TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
                        let elapsed = context.date.timeIntervalSinceReferenceDate
                        animatedCanvas(size: size, time: elapsed)
                    }
                }
            }
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func nebulaBlobs(size: CGSize) -> some View {
        ZStack {
            // Blob 1: Violet/Primary accent top-left
            RadialGradient(
                gradient: Gradient(colors: [
                    selectedTheme.primaryAccent.opacity(0.18),
                    Color.clear
                ]),
                center: .topLeading,
                startRadius: 20,
                endRadius: size.width * 0.85
            )

            // Blob 2: Cyan/Secondary accent bottom-right
            RadialGradient(
                gradient: Gradient(colors: [
                    selectedTheme.secondaryAccent.opacity(0.12),
                    Color.clear
                ]),
                center: .bottomTrailing,
                startRadius: 30,
                endRadius: size.width * 0.9
            )

            // Blob 3: Tertiary accent subtle mid-center glow
            RadialGradient(
                gradient: Gradient(colors: [
                    selectedTheme.tertiaryAccent.opacity(0.08),
                    Color.clear
                ]),
                center: UnitPoint(x: 0.8, y: 0.35),
                startRadius: 10,
                endRadius: size.width * 0.6
            )
        }
    }

    private func staticCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            for star in stars {
                let rect = CGRect(
                    x: star.x * canvasSize.width,
                    y: star.y * canvasSize.height,
                    width: star.size,
                    height: star.size
                )
                let color = Color.white.opacity(min(star.baseOpacity, 0.55))
                context.fill(Path(ellipseIn: rect), with: .color(color))
            }
        }
    }

    private func animatedCanvas(size: CGSize, time: TimeInterval) -> some View {
        Canvas { context, canvasSize in
            for star in stars {
                // Parallax drift by layer: layer 1 drifts slowest, layer 3 slightly faster
                let driftRate = Double(star.layer) * 0.003
                let rawY = star.y + CGFloat((time * driftRate).truncatingRemainder(dividingBy: 1.0))
                let normalizedY = rawY > 1.0 ? rawY - 1.0 : rawY

                let currentX = star.x * canvasSize.width
                let currentY = normalizedY * canvasSize.height

                // Twinkle oscillation
                let sineVal = sin(time * star.twinkleSpeed + star.twinkleOffset)
                let opacityFactor = 0.65 + 0.35 * sineVal
                let currentOpacity = min(star.baseOpacity * opacityFactor, 0.58)

                let rect = CGRect(
                    x: currentX,
                    y: currentY,
                    width: star.size,
                    height: star.size
                )

                // Soft glow on foreground stars
                if star.layer == 3 {
                    let glowRect = rect.insetBy(dx: -1.5, dy: -1.5)
                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(selectedTheme.primaryAccent.opacity(currentOpacity * 0.4))
                    )
                }

                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color.white.opacity(currentOpacity))
                )
            }
        }
    }
}
