import SwiftUI

struct ScoreProgressView: View {
    let snapshots: [ScoreSnapshot]
    let currentComfort: Int
    let currentCompatibility: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                    EyebrowLabel(text: "Connection growth", color: BoopColors.accentColor)
                    Text("How your comfort score has evolved")
                        .font(BoopTypography.cineCaption)
                        .tracking(1)
                        .foregroundStyle(BoopColors.textSecondary)
                }
                Spacer()
                if let trend = comfortTrend {
                    trendBadge(trend)
                }
            }

            AccentRule()

            if snapshots.count >= 2 {
                scoreChart
                    .frame(height: 160)
                    .padding(BoopSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                            .fill(BoopColors.ground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                            .stroke(BoopColors.hairline, lineWidth: 1)
                    )
            } else {
                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                    Text("Keep chatting and playing games.")
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("Your progress chart will appear after more activity.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, BoopSpacing.lg)
            }

            if snapshots.count >= 2 {
                summaryRow
            }
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xl, shadow: false)
    }

    private var scoreChart: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let points = chartPoints(width: width, height: height)

            ZStack(alignment: .topLeading) {
                // Grid lines (hairline)
                ForEach([0, 25, 50, 75, 100], id: \.self) { level in
                    let y = height - (CGFloat(level) / 100.0 * height)
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.white.opacity(0.06), style: StrokeStyle(lineWidth: 0.5))
                }

                // Threshold line at 70 (thin coral)
                let thresholdY = height - (70.0 / 100.0 * height)
                Path { path in
                    path.move(to: CGPoint(x: 0, y: thresholdY))
                    path.addLine(to: CGPoint(x: width, y: thresholdY))
                }
                .stroke(BoopColors.accentColor.opacity(0.4), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))

                Text("70")
                    .font(.system(size: 9, weight: .light))
                    .foregroundStyle(BoopColors.accentColor.opacity(0.7))
                    .offset(x: width - 16, y: thresholdY - 12)

                // Comfort line (thin coral, no fill)
                if points.count >= 2 {
                    Path { path in
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    .stroke(BoopColors.accentColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                    // Point markers (thin coral dots)
                    ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                        Circle()
                            .fill(BoopColors.ground)
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(BoopColors.accentColor, lineWidth: 1))
                            .position(point)
                    }

                    // Current value label at last point
                    if let last = points.last {
                        Text("\(currentComfort)")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(BoopColors.textPrimary)
                            .offset(x: last.x - 8, y: max(last.y - 18, 0))
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
        return HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .light))
            Text(isPositive ? "+\(trend)" : "\(trend)")
                .font(.system(size: 13, weight: .light))
        }
        .foregroundStyle(isPositive ? BoopColors.success : BoopColors.error)
    }

    private var summaryRow: some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(alignment: .top, spacing: BoopSpacing.md) {
                if let first = snapshots.first, let firstDate = first.createdAt {
                    VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                        EyebrowLabel(text: "Started at")
                        Text("\(first.comfortScore)")
                            .font(BoopTypography.cineTitle)
                            .foregroundStyle(BoopColors.textSecondary)
                        Text(firstDate.formatted(.relative(presentation: .named)))
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textMuted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: BoopSpacing.xxs) {
                    EyebrowLabel(text: "Now")
                    Text("\(currentComfort)")
                        .font(BoopTypography.cineTitle)
                        .foregroundStyle(BoopColors.textPrimary)
                    Text("out of 100")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }
}
