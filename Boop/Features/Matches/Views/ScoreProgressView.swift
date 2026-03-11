import SwiftUI

struct ScoreProgressView: View {
    let snapshots: [ScoreSnapshot]
    let currentComfort: Int
    let currentCompatibility: Int?

    var body: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Connection growth")
                            .font(BoopTypography.headline)
                            .foregroundStyle(BoopColors.textPrimary)
                        Text("How your comfort score has evolved")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                    Spacer()
                    if let trend = comfortTrend {
                        trendBadge(trend)
                    }
                }

                if snapshots.count >= 2 {
                    scoreChart
                        .frame(height: 140)
                        .padding(.top, BoopSpacing.xs)
                } else {
                    HStack {
                        Spacer()
                        VStack(spacing: BoopSpacing.sm) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 32))
                                .foregroundStyle(BoopColors.textMuted)
                            Text("Keep chatting and playing games. Your progress chart will appear after more activity.")
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, BoopSpacing.lg)
                        Spacer()
                    }
                }

                if snapshots.count >= 2 {
                    summaryRow
                }
            }
        }
    }

    private var scoreChart: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let points = chartPoints(width: width, height: height)

            ZStack(alignment: .topLeading) {
                // Grid lines
                ForEach([0, 25, 50, 75, 100], id: \.self) { level in
                    let y = height - (CGFloat(level) / 100.0 * height)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(BoopColors.border.opacity(0.3), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                }

                // Threshold line at 70
                let thresholdY = height - (70.0 / 100.0 * height)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: thresholdY))
                    path.addLine(to: CGPoint(x: width, y: thresholdY))
                }
                .stroke(BoopColors.accent.opacity(0.5), lineWidth: 1)

                Text("70")
                    .font(.system(size: 9))
                    .foregroundStyle(BoopColors.accent)
                    .offset(x: width - 16, y: thresholdY - 12)

                // Comfort line
                if points.count >= 2 {
                    // Gradient fill under curve
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: height))
                        for point in points {
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points.last!.x, y: height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [BoopColors.secondary.opacity(0.3), BoopColors.secondary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(BoopColors.secondary, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))

                    // Dots
                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(BoopColors.secondary)
                            .frame(width: 6, height: 6)
                            .position(point)
                    }

                    // Current value label at last point
                    if let last = points.last {
                        Text("\(currentComfort)")
                            .font(BoopTypography.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(BoopColors.secondary)
                            .offset(x: last.x - 8, y: max(last.y - 16, 0))
                    }
                }
            }
        }
    }

    private func chartPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard snapshots.count >= 2 else { return [] }
        let count = snapshots.count
        let spacing = width / CGFloat(count - 1)

        return snapshots.enumerated().map { index, snapshot in
            let x = CGFloat(index) * spacing
            let y = height - (CGFloat(snapshot.comfortScore) / 100.0 * height)
            return CGPoint(x: x, y: y)
        }
    }

    private var comfortTrend: Int? {
        guard snapshots.count >= 2 else { return nil }
        let first = snapshots.first!.comfortScore
        let last = snapshots.last!.comfortScore
        let diff = last - first
        return diff
    }

    private func trendBadge(_ trend: Int) -> some View {
        let isPositive = trend >= 0
        return HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))
            Text(isPositive ? "+\(trend)" : "\(trend)")
                .font(BoopTypography.caption)
                .fontWeight(.semibold)
        }
        .foregroundStyle(isPositive ? BoopColors.success : BoopColors.error)
        .padding(.horizontal, BoopSpacing.sm)
        .padding(.vertical, 4)
        .background((isPositive ? BoopColors.success : BoopColors.error).opacity(0.12))
        .clipShape(Capsule())
    }

    private var summaryRow: some View {
        HStack(spacing: BoopSpacing.md) {
            if let first = snapshots.first, let firstDate = first.createdAt {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Started at")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                    Text("\(first.comfortScore)")
                        .font(BoopTypography.title3)
                        .foregroundStyle(BoopColors.textSecondary)
                    Text(firstDate.formatted(.relative(presentation: .named)))
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Now")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textMuted)
                Text("\(currentComfort)")
                    .font(BoopTypography.title3)
                    .foregroundStyle(BoopColors.secondary)
                Text("out of 100")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textMuted)
            }
        }
        .padding(BoopSpacing.md)
        .background(BoopColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
    }
}
