import SwiftUI

struct PersonalityReportView: View {
    @State private var viewModel = PersonalityReportViewModel()
    @State private var headerAppeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(BoopColors.primary)
                        .frame(maxWidth: .infinity, minHeight: 400)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if let analysis = viewModel.analysis {
                    reportContent(analysis)
                } else {
                    noAnalysisView
                }
            }
        }
        .boopBackground()
        .navigationTitle("Personality Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
    }

    // MARK: - Report Content

    @ViewBuilder
    private func reportContent(_ analysis: PersonalityAnalysis) -> some View {
        // Full-bleed hero at top
        heroSection(analysis)

        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            // Preliminary banner
            if viewModel.isPreliminary {
                preliminaryBanner
            }

            // Radar chart
            if !analysis.facets.isEmpty {
                radarSection(analysis.facets)
            }

            // Summary
            summaryCard(analysis.summary)

            // Facet breakdown
            if !analysis.facets.isEmpty {
                facetBreakdownSection(analysis.facets)
            }

            // Numerology section
            if let numerology = analysis.numerology {
                numerologySection(numerology)
            }

            // Next milestone footer
            milestoneFooter

            Spacer(minLength: BoopSpacing.xxl)
        }
        .padding(.horizontal, BoopSpacing.lg)
        .padding(.top, BoopSpacing.lg)
    }

    // MARK: - Hero Section (full-bleed gradient header)

    private func heroSection(_ analysis: PersonalityAnalysis) -> some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(hex: "FFF4ED"),
                    Color(hex: "FFF0F0"),
                    Color(hex: "F0FBF9")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Decorative circles
            Circle()
                .fill(BoopColors.primary.opacity(0.06))
                .frame(width: 200, height: 200)
                .offset(x: -100, y: -40)

            Circle()
                .fill(BoopColors.secondary.opacity(0.06))
                .frame(width: 160, height: 160)
                .offset(x: 110, y: 30)

            Circle()
                .fill(BoopColors.accent.opacity(0.05))
                .frame(width: 100, height: 100)
                .offset(x: 60, y: -60)

            VStack(spacing: BoopSpacing.sm) {
                // Personality icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [BoopColors.primary.opacity(0.15), BoopColors.secondary.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [BoopColors.primary, BoopColors.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(headerAppeared ? 1.0 : 0.5)
                .opacity(headerAppeared ? 1.0 : 0.0)

                // Type name
                Text(analysis.personalityType)
                    .font(.nunito(.extraBold, size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BoopColors.primary, Color(hex: "E056A0"), BoopColors.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                    .opacity(headerAppeared ? 1.0 : 0.0)
                    .offset(y: headerAppeared ? 0 : 10)

                // Subtitle
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(BoopColors.secondary)

                    Text("Based on \(analysis.questionsAnalyzed) answers")
                        .font(.nunito(.semiBold, size: 13))
                        .foregroundStyle(BoopColors.textSecondary)
                }
                .opacity(headerAppeared ? 1.0 : 0.0)

                if viewModel.isPreliminary {
                    Text("Preliminary")
                        .font(.nunito(.bold, size: 11))
                        .foregroundStyle(BoopColors.accent.opacity(0.9))
                        .padding(.horizontal, BoopSpacing.sm)
                        .padding(.vertical, BoopSpacing.xxxs)
                        .background(BoopColors.accent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, BoopSpacing.xxl)
        }
        .clipShape(
            RoundedCornerShape(radius: 32, corners: [.bottomLeft, .bottomRight])
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                headerAppeared = true
            }
        }
    }

    // MARK: - Radar Section

    private func radarSection(_ facets: [PersonalityFacet]) -> some View {
        VStack(spacing: BoopSpacing.md) {
            sectionHeader(icon: "chart.pie.fill", title: "Your Profile Shape")

            ZStack {
                RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: BoopColors.primary.opacity(0.04), radius: 16, x: 0, y: 4)

                VStack(spacing: BoopSpacing.md) {
                    PersonalityRadarChartView(facets: facets, size: 270)
                        .frame(maxWidth: .infinity)
                        .padding(.top, BoopSpacing.md)

                    // Compact legend in 2 columns
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: BoopSpacing.xs),
                        GridItem(.flexible(), spacing: BoopSpacing.xs)
                    ], spacing: BoopSpacing.xs) {
                        ForEach(facets) { facet in
                            HStack(spacing: 6) {
                                Text(facet.emoji)
                                    .font(.system(size: 14))
                                Text(facet.title)
                                    .font(.nunito(.medium, size: 12))
                                    .foregroundStyle(BoopColors.textSecondary)
                                    .lineLimit(1)
                                Spacer()
                                Text("\(facet.score)")
                                    .font(.nunito(.bold, size: 12))
                                    .foregroundStyle(BoopColors.textPrimary)
                            }
                        }
                    }
                    .padding(.horizontal, BoopSpacing.md)
                    .padding(.bottom, BoopSpacing.md)
                }
            }
        }
    }

    // MARK: - Summary Card

    private func summaryCard(_ summary: String) -> some View {
        VStack(spacing: BoopSpacing.md) {
            sectionHeader(icon: "text.quote", title: "About You")

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FFF9F5"), Color(hex: "FFF4EE")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Large decorative quote mark
                Text("\u{201C}")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(BoopColors.primary.opacity(0.08))
                    .offset(x: 12, y: -8)

                VStack(alignment: .leading, spacing: 0) {
                    Text(summary)
                        .font(.nunito(.regular, size: 15))
                        .foregroundStyle(BoopColors.textSecondary)
                        .lineSpacing(6)
                }
                .padding(BoopSpacing.lg)
                .padding(.top, BoopSpacing.sm)
            }
        }
    }

    // MARK: - Facet Breakdown

    private func facetBreakdownSection(_ facets: [PersonalityFacet]) -> some View {
        let sortedFacets = facets.sorted { $0.score > $1.score }
        let facetColors: [Color] = [
            BoopColors.primary,
            Color(hex: "9B5DE5"),
            BoopColors.secondary,
            Color(hex: "2ECC71"),
            Color(hex: "FF8C42"),
            Color(hex: "00BBF9"),
            BoopColors.accent
        ]

        return VStack(spacing: BoopSpacing.md) {
            sectionHeader(icon: "list.bullet.below.rectangle", title: "Trait Breakdown")

            VStack(spacing: BoopSpacing.sm) {
                ForEach(Array(sortedFacets.enumerated()), id: \.element.id) { idx, facet in
                    let color = facetColors[facets.firstIndex(where: { $0.id == facet.id }) ?? idx % facetColors.count]
                    facetRow(facet, color: color, rank: idx + 1)
                }
            }
        }
    }

    private func facetRow(_ facet: PersonalityFacet, color: Color, rank: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                .fill(Color.white)
                .shadow(color: color.opacity(0.06), radius: 8, x: 0, y: 2)

            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                HStack(spacing: BoopSpacing.sm) {
                    // Emoji with colored background
                    ZStack {
                        RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                            .fill(color.opacity(0.12))
                            .frame(width: 40, height: 40)

                        Text(facet.emoji)
                            .font(.system(size: 20))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(facet.title)
                            .font(.nunito(.bold, size: 15))
                            .foregroundStyle(BoopColors.textPrimary)

                        // Score bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(color.opacity(0.1))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [color, color.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(facet.score) / 100.0, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }

                    Spacer()

                    // Score circle
                    ZStack {
                        Circle()
                            .stroke(color.opacity(0.2), lineWidth: 3)
                            .frame(width: 44, height: 44)

                        Circle()
                            .trim(from: 0, to: CGFloat(facet.score) / 100.0)
                            .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))

                        Text("\(facet.score)")
                            .font(.nunito(.extraBold, size: 14))
                            .foregroundStyle(color)
                    }
                }

                Text(facet.description)
                    .font(.nunito(.regular, size: 13))
                    .foregroundStyle(BoopColors.textSecondary)
                    .lineSpacing(3)
            }
            .padding(BoopSpacing.md)
        }
    }

    // MARK: - Numerology Section

    private func numerologySection(_ numerology: NumerologyData) -> some View {
        VStack(spacing: BoopSpacing.md) {
            sectionHeader(icon: "star.circle.fill", title: "Numerology")

            ZStack {
                RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "1C2332"),
                                Color(hex: "253452")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Decorative stars
                ZStack {
                    ForEach(0..<12, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(Double.random(in: 0.03...0.1)))
                            .frame(width: CGFloat.random(in: 2...5), height: CGFloat.random(in: 2...5))
                            .offset(
                                x: CGFloat.random(in: -140...140),
                                y: CGFloat.random(in: -80...80)
                            )
                    }
                }

                VStack(spacing: BoopSpacing.lg) {
                    // Number circles
                    HStack(spacing: BoopSpacing.xxl) {
                        numerologyCircle(
                            value: numerology.lifePathNumber,
                            label: "Life Path",
                            gradient: [BoopColors.primary, Color(hex: "FF9A9E")]
                        )

                        if let expr = numerology.expressionNumber {
                            numerologyCircle(
                                value: expr,
                                label: "Expression",
                                gradient: [BoopColors.secondary, Color(hex: "A8EDEA")]
                            )
                        }
                    }

                    // Master number badge
                    if [11, 22, 33].contains(numerology.lifePathNumber) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("Master Number")
                                .font(.nunito(.bold, size: 12))
                        }
                        .foregroundStyle(BoopColors.accent)
                        .padding(.horizontal, BoopSpacing.sm)
                        .padding(.vertical, BoopSpacing.xxs)
                        .background(BoopColors.accent.opacity(0.15))
                        .clipShape(Capsule())
                    }

                    // Description
                    if !numerology.description.isEmpty {
                        Text(numerology.description)
                            .font(.nunito(.regular, size: 13))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .lineSpacing(4)
                            .multilineTextAlignment(.center)
                    }

                    // Trait chips
                    if !numerology.traits.isEmpty {
                        FlowLayoutNumerology(spacing: BoopSpacing.xs) {
                            ForEach(numerology.traits, id: \.self) { trait in
                                Text(trait)
                                    .font(.nunito(.semiBold, size: 12))
                                    .foregroundStyle(Color.white)
                                    .padding(.horizontal, BoopSpacing.sm)
                                    .padding(.vertical, BoopSpacing.xxs)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                                    )
                            }
                        }
                    }
                }
                .padding(BoopSpacing.xl)
            }
        }
    }

    private func numerologyCircle(value: Int, label: String, gradient: [Color]) -> some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [gradient[0].opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 28,
                            endRadius: 46
                        )
                    )
                    .frame(width: 76, height: 76)

                // Ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.5
                    )
                    .frame(width: 60, height: 60)

                // Inner fill
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [gradient[0].opacity(0.2), gradient[1].opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Text("\(value)")
                    .font(.nunito(.extraBold, size: 26))
                    .foregroundStyle(Color.white)
            }

            Text(label)
                .font(.nunito(.medium, size: 12))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: BoopSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [BoopColors.primary, BoopColors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(title)
                .font(.nunito(.bold, size: 17))
                .foregroundStyle(BoopColors.textPrimary)
        }
    }

    // MARK: - Preliminary Banner

    private var preliminaryBanner: some View {
        HStack(spacing: BoopSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: BoopRadius.sm, style: .continuous)
                    .fill(BoopColors.accent.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: "sparkle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(BoopColors.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Growing your profile")
                    .font(.nunito(.bold, size: 14))
                    .foregroundStyle(BoopColors.textPrimary)

                Text("Answer \(viewModel.questionsUntilNext) more for deeper insights")
                    .font(.nunito(.regular, size: 12))
                    .foregroundStyle(BoopColors.textSecondary)
            }

            Spacer()

            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(BoopColors.accent.opacity(0.15), lineWidth: 3)
                    .frame(width: 32, height: 32)

                let progress = 1.0 - (Double(viewModel.questionsUntilNext) / Double(max(viewModel.nextMilestone, 1)))
                Circle()
                    .trim(from: 0, to: max(0.05, progress))
                    .stroke(BoopColors.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(BoopSpacing.md)
        .background(BoopColors.surfaceGoldenLight)
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous)
                .stroke(BoopColors.accent.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - No Analysis View

    private var noAnalysisView: some View {
        VStack(spacing: BoopSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [BoopColors.primary.opacity(0.08), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Circle()
                    .fill(BoopColors.primary.opacity(0.06))
                    .frame(width: 120, height: 120)

                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [BoopColors.primary.opacity(0.6), BoopColors.secondary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: BoopSpacing.sm) {
                Text("Your personality profile\nis being crafted")
                    .font(.nunito(.bold, size: 22))
                    .foregroundStyle(BoopColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Answer \(viewModel.questionsUntilNext) more questions to unlock\nyour unique personality insights")
                    .font(.nunito(.regular, size: 15))
                    .foregroundStyle(BoopColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    // MARK: - Milestone Footer

    private var milestoneFooter: some View {
        Group {
            if viewModel.questionsUntilNext > 0 {
                HStack(spacing: BoopSpacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13))
                        .foregroundStyle(BoopColors.secondary)

                    Text("Next update at \(viewModel.nextMilestone) answers")
                        .font(.nunito(.medium, size: 13))
                        .foregroundStyle(BoopColors.textSecondary)

                    Text("(\(viewModel.questionsUntilNext) to go)")
                        .font(.nunito(.bold, size: 13))
                        .foregroundStyle(BoopColors.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, BoopSpacing.md)
                .background(BoopColors.surfaceMintLight)
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
            }
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: BoopSpacing.md) {
            Spacer()
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 36))
                .foregroundStyle(BoopColors.error)
            Text(message)
                .font(BoopTypography.body)
                .foregroundStyle(BoopColors.error)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

// MARK: - Custom bottom-rounded shape

private struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Simple flow layout for numerology traits
private struct FlowLayoutNumerology: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (CGSize(width: maxX, height: y + rowHeight), positions)
    }
}
