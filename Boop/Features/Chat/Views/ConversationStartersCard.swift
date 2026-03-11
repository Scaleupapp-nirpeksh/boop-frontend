import SwiftUI

struct ConversationStartersCard: View {
    let starters: [ConversationStarter]
    let isLoading: Bool
    let onSelect: (String) -> Void

    @State private var isCollapsed = false

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isCollapsed.toggle() }
            } label: {
                HStack(spacing: BoopSpacing.xs) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BoopColors.secondary)

                    Text("Conversation starters")
                        .font(BoopTypography.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(BoopColors.textPrimary)

                    Spacer()

                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(BoopColors.textMuted)
                }
            }

            if !isCollapsed {
                if isLoading {
                    HStack(spacing: BoopSpacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(BoopColors.secondary)
                        Text("Finding things to talk about...")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                } else {
                    Text("Based on your shared answers")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)

                    VStack(spacing: BoopSpacing.xs) {
                        ForEach(starters) { starter in
                            Button {
                                onSelect(starter.text)
                            } label: {
                                HStack(alignment: .top, spacing: BoopSpacing.sm) {
                                    Image(systemName: starter.categoryIcon)
                                        .font(.system(size: 12))
                                        .foregroundStyle(BoopColors.secondary)
                                        .frame(width: 20, height: 20)
                                        .padding(.top, 2)

                                    Text(starter.text)
                                        .font(BoopTypography.footnote)
                                        .foregroundStyle(BoopColors.textPrimary)
                                        .multilineTextAlignment(.leading)

                                    Spacer()

                                    Image(systemName: "arrow.turn.down.left")
                                        .font(.system(size: 10))
                                        .foregroundStyle(BoopColors.textMuted)
                                }
                                .padding(BoopSpacing.sm)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(BoopSpacing.md)
        .background(BoopColors.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xl, style: .continuous))
    }
}
