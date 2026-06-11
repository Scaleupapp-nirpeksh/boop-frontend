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
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)

            DatePicker(
                "",
                selection: $date,
                in: minDate...maxDate,
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(BoopColors.accentColor)
            .frame(maxHeight: 150)
            .clipped()
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .stroke(BoopColors.hairline, lineWidth: 1)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.error)
            }
        }
    }
}
