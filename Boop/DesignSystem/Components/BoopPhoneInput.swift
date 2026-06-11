import SwiftUI

struct BoopPhoneInput: View {
    @Binding var phoneNumber: String
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xs) {
            EyebrowLabel(text: "Phone Number")

            HStack(spacing: BoopSpacing.sm) {
                // Country code — tracked text, no emoji
                Text("+91")
                    .font(BoopTypography.cineHeadline)
                    .tracking(1)
                    .foregroundStyle(BoopColors.textPrimary)
                    .padding(.trailing, BoopSpacing.sm)
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(BoopColors.hairline)
                            .frame(width: 1, height: 24)
                    }

                // Phone number field
                TextField("98765 43210", text: $phoneNumber)
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.textPrimary)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .focused($isFocused)
                    .onChange(of: phoneNumber) { _, newValue in
                        let digits = newValue.filter(\.isNumber)
                        if digits.count > 10 {
                            phoneNumber = String(digits.prefix(10))
                        } else {
                            phoneNumber = digits
                        }
                    }
            }
            .padding(.horizontal, BoopSpacing.md)
            .padding(.vertical, BoopSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .fill(BoopColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )

            if let errorMessage {
                Text(errorMessage)
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.error)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return BoopColors.error }
        if isFocused { return BoopColors.accentColor }
        return BoopColors.hairline
    }
}
