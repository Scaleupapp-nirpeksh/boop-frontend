import SwiftUI
import Foundation

struct PersonalityRadarChartView: View {
    let facets: [PersonalityFacet]
    var size: CGFloat = 260
    var animated: Bool = true

    @State private var appear = false

    private var center: CGPoint { CGPoint(x: size / 2, y: size / 2) }
    private var radius: CGFloat { size / 2 - 36 }
    private var count: Int { facets.count }

    var body: some View {
        ZStack {
            // Subtle radial glow behind chart
            RadialGradient(
                colors: [BoopColors.secondary.opacity(0.08), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: radius * 1.2
            )

            // Background rings with subtle fill
            ForEach(Array([0.25, 0.5, 0.75, 1.0].enumerated()), id: \.offset) { idx, scale in
                polygonPath(scale: scale)
                    .stroke(
                        BoopColors.border.opacity(idx == 3 ? 0.5 : 0.25),
                        style: StrokeStyle(lineWidth: idx == 3 ? 1 : 0.5, dash: idx < 3 ? [4, 4] : [])
                    )
            }

            // Axis lines
            ForEach(0..<count, id: \.self) { i in
                Path { path in
                    path.move(to: center)
                    path.addLine(to: point(for: i, scale: 1.0))
                }
                .stroke(BoopColors.border.opacity(0.2), lineWidth: 0.5)
            }

            // Filled data area with animation
            dataPath(scale: appear ? 1.0 : 0.0)
                .fill(
                    LinearGradient(
                        colors: [
                            BoopColors.primary.opacity(0.20),
                            BoopColors.secondary.opacity(0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Stroke with glow
            dataPath(scale: appear ? 1.0 : 0.0)
                .stroke(
                    LinearGradient(
                        colors: [BoopColors.primary, BoopColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .shadow(color: BoopColors.primary.opacity(0.3), radius: 4, x: 0, y: 0)

            // Data points with pulse effect
            ForEach(0..<count, id: \.self) { i in
                let scale = appear ? Double(facets[i].score) / 100.0 : 0.0
                let pt = point(for: i, scale: scale)

                ZStack {
                    Circle()
                        .fill(facetColor(for: i).opacity(0.2))
                        .frame(width: 14, height: 14)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)

                    Circle()
                        .fill(facetColor(for: i))
                        .frame(width: 6, height: 6)
                }
                .position(pt)
            }

            // Emoji labels with score underneath
            ForEach(0..<count, id: \.self) { i in
                let labelPoint = point(for: i, scale: 1.30)
                VStack(spacing: 1) {
                    Text(facets[i].emoji)
                        .font(.system(size: 20))
                    Text("\(facets[i].score)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(BoopColors.textMuted)
                }
                .position(labelPoint)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                    appear = true
                }
            } else {
                appear = true
            }
        }
    }

    private func dataPath(scale animScale: Double) -> Path {
        Path { path in
            guard count > 0 else { return }
            let firstPoint = point(for: 0, scale: Double(facets[0].score) / 100.0 * animScale)
            path.move(to: firstPoint)
            for i in 1..<count {
                path.addLine(to: point(for: i, scale: Double(facets[i].score) / 100.0 * animScale))
            }
            path.closeSubpath()
        }
    }

    private func polygonPath(scale: Double) -> Path {
        Path { path in
            guard count > 0 else { return }
            path.move(to: point(for: 0, scale: scale))
            for i in 1..<count {
                path.addLine(to: point(for: i, scale: scale))
            }
            path.closeSubpath()
        }
    }

    private func point(for index: Int, scale: Double) -> CGPoint {
        let angle = (2.0 * .pi / Double(count)) * Double(index) - .pi / 2.0
        return CGPoint(
            x: center.x + radius * scale * Foundation.cos(angle),
            y: center.y + radius * scale * Foundation.sin(angle)
        )
    }

    private func facetColor(for index: Int) -> Color {
        let colors: [Color] = [
            BoopColors.primary,
            Color(hex: "9B5DE5"),
            BoopColors.secondary,
            Color(hex: "2ECC71"),
            Color(hex: "FF8C42"),
            Color(hex: "00BBF9"),
            BoopColors.accent
        ]
        return colors[index % colors.count]
    }
}
