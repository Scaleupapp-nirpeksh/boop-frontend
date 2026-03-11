import SwiftUI

struct BoopTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var errorMessage: String? = nil
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var isMultiline: Bool = false
    var maxLength: Int? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
            Text(label)
                .font(BoopTypography.subheadline)
                .foregroundStyle(BoopColors.textSecondary)

            Group {
                if isMultiline {
                    TextEditor(text: $text)
                        .font(BoopTypography.body)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                } else {
                    TextField(placeholder, text: $text)
                        .font(BoopTypography.body)
                        .keyboardType(keyboardType)
                        .textContentType(textContentType)
                }
            }
            .focused($isFocused)
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
            .onChange(of: text) { _, newValue in
                if let maxLength, newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }

            if let maxLength {
                HStack {
                    if let errorMessage {
                        Text(errorMessage)
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.error)
                    }
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                }
            } else if let errorMessage {
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
