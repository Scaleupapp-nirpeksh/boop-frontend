import SwiftUI

struct BoopLogo: View {
    var size: CGFloat = 120
    var showText: Bool = true
    var animated: Bool = false

    @State private var leftAppeared = false
    @State private var rightAppeared = false
    @State private var heartAppeared = false

    private var circleSize: CGFloat { size * 0.55 }
    private var overlap: CGFloat { size * 0.15 }
    private var heartSize: CGFloat { size * 0.22 }

    var body: some View {
        VStack(spacing: size * 0.1) {
            ZStack {
                // Left circle (Coral)
                Circle()
                    .fill(BoopColors.primary)
                    .frame(width: circleSize, height: circleSize)
                    .offset(x: -(circleSize / 2 - overlap))
                    .opacity(animated ? (leftAppeared ? 1 : 0) : 1)
                    .offset(x: animated ? (leftAppeared ? 0 : -20) : 0)

                // Right circle (Teal)
                Circle()
                    .fill(BoopColors.secondary)
                    .frame(width: circleSize, height: circleSize)
                    .offset(x: circleSize / 2 - overlap)
                    .opacity(animated ? (rightAppeared ? 1 : 0) : 1)
                    .offset(x: animated ? (rightAppeared ? 0 : 20) : 0)

                // Overlap blend
                Circle()
                    .fill(BoopColors.primary)
                    .frame(width: circleSize, height: circleSize)
                    .offset(x: -(circleSize / 2 - overlap))
                    .blendMode(.multiply)

                // Heart at intersection
                HeartShape()
                    .fill(.white)
                    .frame(width: heartSize, height: heartSize)
                    .opacity(animated ? (heartAppeared ? 1 : 0) : 1)
                    .scaleEffect(animated ? (heartAppeared ? 1 : 0.3) : 1)
            }
            .frame(width: size, height: circleSize)

            if showText {
                Text("boop")
                    .font(.nunito(.extraBold, size: size * 0.25))
                    .foregroundStyle(BoopColors.primary)
            }
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                leftAppeared = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                rightAppeared = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.6)) {
                heartAppeared = true
            }
        }
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width * 0.5, y: height))
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.3),
            control1: CGPoint(x: width * 0.1, y: height * 0.8),
            control2: CGPoint(x: 0, y: height * 0.55)
        )
        path.addArc(
            center: CGPoint(x: width * 0.25, y: height * 0.25),
            radius: width * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: width * 0.75, y: height * 0.25),
            radius: width * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control1: CGPoint(x: width, y: height * 0.55),
            control2: CGPoint(x: width * 0.9, y: height * 0.8)
        )

        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        BoopLogo(size: 120, animated: true)
        BoopLogo(size: 60, showText: false)
    }
    .boopBackground()
}
