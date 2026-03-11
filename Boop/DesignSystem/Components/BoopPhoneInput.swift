import SwiftUI

struct BoopPhoneInput: View {
    @Binding var phoneNumber: String
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
            Text("Phone Number")
                .font(BoopTypography.subheadline)
                .foregroundStyle(BoopColors.textSecondary)

            HStack(spacing: BoopSpacing.sm) {
                // Country code pill
                HStack(spacing: BoopSpacing.xxs) {
                    Text("🇮🇳")
                        .font(.system(size: 20))
                    Text("+91")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                }
                .padding(.horizontal, BoopSpacing.sm)
                .padding(.vertical, BoopSpacing.xs)
                .background(BoopColors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.sm, style: .continuous))

                // Phone number field
                TextField("98765 43210", text: $phoneNumber)
                    .font(BoopTypography.title3)
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
                RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                    .fill(BoopColors.surfaceElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 6)

            if let errorMessage {
                Text(errorMessage)
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.error)
            }
        }
    }

    private var borderColor: Color {
        if errorMessage != nil { return BoopColors.error }
        if isFocused { return BoopColors.primary }
        return BoopColors.border
    }
}
