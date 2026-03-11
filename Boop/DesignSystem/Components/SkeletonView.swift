import SwiftUI

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { proxy in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: max(0, phase - 0.3)),
                            .init(color: .white.opacity(0.4), location: phase),
                            .init(color: .clear, location: min(1, phase + 0.3)),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 2
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Shapes

struct SkeletonLine: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
            .fill(BoopColors.surfaceSecondary)
            .frame(width: width, height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var size: CGFloat = 48

    var body: some View {
        Circle()
            .fill(BoopColors.surfaceSecondary)
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - Skeleton Cards

struct SkeletonInboxRow: View {
    var body: some View {
        HStack(spacing: BoopSpacing.md) {
            SkeletonCircle(size: 56)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    SkeletonLine(width: 120, height: 16)
                    Spacer()
                    SkeletonLine(width: 40, height: 12)
                }
                SkeletonLine(height: 12)
                SkeletonLine(width: 80, height: 10)
            }
        }
        .padding(BoopSpacing.md)
        .boopCard(radius: BoopRadius.xl)
    }
}

struct SkeletonNotificationRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: BoopSpacing.sm) {
            SkeletonCircle(size: 42)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    SkeletonLine(width: 140, height: 14)
                    Spacer()
                    SkeletonLine(width: 36, height: 10)
                }
                SkeletonLine(height: 12)
                SkeletonLine(width: 200, height: 12)
            }
        }
        .padding(.vertical, BoopSpacing.sm)
        .padding(.horizontal, BoopSpacing.xs)
    }
}

struct SkeletonCandidateCard: View {
    var body: some View {
        VStack(spacing: BoopSpacing.md) {
            SkeletonCircle(size: 100)
            SkeletonLine(width: 120, height: 18)
            SkeletonLine(width: 80, height: 14)
            SkeletonLine(height: 12)
            SkeletonLine(width: 160, height: 12)
        }
        .padding(.vertical, BoopSpacing.huge)
    }
}
