import SwiftUI

struct BoopSegmentedPicker<T: Hashable>: View {
    let label: String
    let options: [(value: T, label: String)]
    @Binding var selected: T?
    var errorMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)

            FlowLayout(spacing: BoopSpacing.xs) {
                ForEach(options, id: \.value) { option in
                    pillButton(option)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.error)
            }
        }
    }

    private func pillButton(_ option: (value: T, label: String)) -> some View {
        let isSelected = selected == option.value

        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            selected = option.value
        } label: {
            Text(option.label)
                .font(BoopTypography.cineBody)
                .foregroundStyle(isSelected ? .white : BoopColors.textSecondary)
                .padding(.horizontal, BoopSpacing.md)
                .padding(.vertical, BoopSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: BoopRadius.chip, style: .continuous)
                        .fill(isSelected ? BoopColors.accentColor : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.chip, style: .continuous)
                        .stroke(isSelected ? Color.clear : BoopColors.hairline, lineWidth: 1)
                )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Simple flow layout for wrapping pills
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = computeLayout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func computeLayout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
