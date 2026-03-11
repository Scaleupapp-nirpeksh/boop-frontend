import SwiftUI
import Foundation

struct PersonalityRadarChartView: View {
    let facets: [PersonalityFacet]
    var size: CGFloat = 220

    private var center: CGPoint { CGPoint(x: size / 2, y: size / 2) }
    private var radius: CGFloat { size / 2 - 30 }
    private var count: Int { facets.count }

    var body: some View {
        ZStack {
            // Background rings
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                polygonPath(scale: scale)
                    .stroke(BoopColors.border.opacity(0.4), lineWidth: 0.5)
            }

            // Axis lines
            ForEach(0..<count, id: \.self) { i in
                Path { path in
                    path.move(to: center)
                    path.addLine(to: point(for: i, scale: 1.0))
                }
                .stroke(BoopColors.border.opacity(0.3), lineWidth: 0.5)
            }

            // Filled data area
            dataPath
                .fill(
                    LinearGradient(
                        colors: [BoopColors.primary.opacity(0.25), BoopColors.secondary.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            dataPath
                .stroke(
                    LinearGradient(
                        colors: [BoopColors.primary, BoopColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )

            // Data points
            ForEach(0..<count, id: \.self) { i in
                let pt = point(for: i, scale: Double(facets[i].score) / 100.0)
                Circle()
                    .fill(BoopColors.primary)
                    .frame(width: 6, height: 6)
                    .position(pt)
            }

            // Labels
            ForEach(0..<count, id: \.self) { i in
                let labelPoint = point(for: i, scale: 1.22)
                Text(facets[i].emoji)
                    .font(.system(size: 16))
                    .position(labelPoint)
            }
        }
        .frame(width: size, height: size)
    }

    private var dataPath: Path {
        Path { path in
            guard count > 0 else { return }
            let firstPoint = point(for: 0, scale: Double(facets[0].score) / 100.0)
            path.move(to: firstPoint)
            for i in 1..<count {
                path.addLine(to: point(for: i, scale: Double(facets[i].score) / 100.0))
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
