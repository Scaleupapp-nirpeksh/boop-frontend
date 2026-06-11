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
        let isCurrentIndex = index == code.count && isFocused
        let isFilled = !digit.isEmpty

        return Text(digit)
            .font(BoopTypography.cineTitle)
            .foregroundStyle(BoopColors.textPrimary)
            .frame(width: 48, height: 56)
            .background(
                RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                    .fill(BoopColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.soft, style: .continuous)
                    .stroke(
                        isCurrentIndex ? BoopColors.accentColor : (isFilled ? BoopColors.textMuted : BoopColors.hairline),
                        lineWidth: isCurrentIndex ? 1.5 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFilled)
            .animation(.easeInOut(duration: 0.2), value: isCurrentIndex)
    }
}
