import SwiftUI

enum ToastType {
    case success, error, info

    var color: Color {
        switch self {
        case .success: return BoopColors.success
        case .error: return BoopColors.error
        case .info: return BoopColors.secondary
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

struct BoopToast: View {
    let message: String
    var type: ToastType = .info

    var body: some View {
        HStack(spacing: BoopSpacing.sm) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)
                .font(.system(size: 20))

            Text(message)
                .font(BoopTypography.callout)
                .foregroundStyle(BoopColors.textPrimary)
                .lineLimit(2)
        }
        .padding(.horizontal, BoopSpacing.md)
        .padding(.vertical, BoopSpacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    var type: ToastType = .info
    var duration: TimeInterval = 3

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isPresented {
                BoopToast(message: message, type: type)
                    .padding(.top, BoopSpacing.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation { isPresented = false }
                        }
                    }
                    .zIndex(999)
            }
        }
        .animation(.spring(response: 0.3), value: isPresented)
    }
}

extension View {
    func boopToast(isPresented: Binding<Bool>, message: String, type: ToastType = .info) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, type: type))
    }
}
