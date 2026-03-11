import SwiftUI

struct BoopDatePicker: View {
    let label: String
    @Binding var date: Date
    var errorMessage: String? = nil

    private var maxDate: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    private var minDate: Date {
        Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
            Text(label)
                .font(BoopTypography.subheadline)
                .foregroundStyle(BoopColors.textSecondary)

            DatePicker(
                "",
                selection: $date,
                in: minDate...maxDate,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 150)
            .clipped()
            .background(
                RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                    .fill(BoopColors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                    .stroke(BoopColors.border.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 6)

            if let errorMessage {
                Text(errorMessage)
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.error)
            }
        }
    }
}
