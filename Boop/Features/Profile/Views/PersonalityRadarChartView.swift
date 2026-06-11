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
            // Concentric grid rings (white hairlines on near-black)
            ForEach(Array([0.25, 0.5, 0.75, 1.0].enumerated()), id: \.offset) { idx, scale in
                polygonPath(scale: scale)
                    .stroke(
                        Color.white.opacity(idx == 3 ? 0.16 : 0.08),
                        style: StrokeStyle(lineWidth: idx == 3 ? 1 : 0.5, dash: idx < 3 ? [4, 4] : [])
                    )
            }

            // Axis spokes
            ForEach(0..<count, id: \.self) { i in
                Path { path in
                    path.move(to: center)
                    path.addLine(to: point(for: i, scale: 1.0))
                }
                .stroke(Color.white.opacity(0.07), lineWidth: 0.5)
            }

            // Filled data area — tonal coral at low opacity
            dataPath(scale: appear ? 1.0 : 0.0)
                .fill(BoopColors.accentColor.opacity(0.14))

            // Data outline — thin coral stroke
            dataPath(scale: appear ? 1.0 : 0.0)
                .stroke(BoopColors.accentColor, lineWidth: 1.5)

            // Vertices — small coral nodes on a faint halo
            ForEach(0..<count, id: \.self) { i in
                let scale = appear ? Double(facets[i].score) / 100.0 : 0.0
                let pt = point(for: i, scale: scale)

                ZStack {
                    Circle()
                        .fill(BoopColors.accentColor.opacity(0.18))
                        .frame(width: 12, height: 12)
                    Circle()
                        .fill(BoopColors.accentColor)
                        .frame(width: 4, height: 4)
                }
                .position(pt)
            }

            // Axis labels — typeset facet title + score, no emoji
            ForEach(0..<count, id: \.self) { i in
                let labelPoint = point(for: i, scale: 1.34)
                VStack(spacing: 1) {
                    Text(facets[i].title)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineLimit(1)
                    Text("\(facets[i].score)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BoopColors.textPrimary)
                }
                .frame(width: 72)
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
}
