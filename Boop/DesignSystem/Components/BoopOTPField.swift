import SwiftUI

struct BoopOTPField: View {
    @Binding var code: String
    let length: Int = 6
    var onComplete: ((String) -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            // Hidden text field for input
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: code) { _, newValue in
                    let digits = newValue.filter(\.isNumber)
                    if digits.count > length {
                        code = String(digits.prefix(length))
                    } else {
                        code = digits
                    }
                    if code.count == length {
                        onComplete?(code)
                    }
                }

            // Visible digit boxes
            HStack(spacing: BoopSpacing.sm) {
                ForEach(0..<length, id: \.self) { index in
                    digitBox(at: index)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            isFocused = true
        }
    }

    private func digitBox(at index: Int) -> some View {
        let digit = index < code.count
            ? String(code[code.index(code.startIndex, offsetBy: index)])
            : ""
        let isCurrentIndex = index == code.count
        let isFilled = !digit.isEmpty

        return Text(digit)
            .font(BoopTypography.title1)
            .foregroundStyle(BoopColors.textPrimary)
            .frame(width: 48, height: 56)
            .background(isFilled ? BoopColors.surfaceSecondary : BoopColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                    .stroke(
                        isCurrentIndex ? BoopColors.primary : (isFilled ? BoopColors.secondary : BoopColors.border),
                        lineWidth: isCurrentIndex ? 2 : 1
                    )
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
            .scaleEffect(isFilled ? 1.05 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isFilled)
    }
}
