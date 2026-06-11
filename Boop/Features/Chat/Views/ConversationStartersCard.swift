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
                HStack(spacing: BoopSpacing.sm) {
                    EyebrowLabel(text: "Conversation starters", color: BoopColors.textSecondary)

                    Spacer()

                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.system(size: 11, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                }
            }

            if !isCollapsed {
                if isLoading {
                    HStack(spacing: BoopSpacing.sm) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(BoopColors.textMuted)
                        Text("Finding things to talk about...")
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                } else {
                    AccentRule()

                    Text("Based on your shared answers")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textMuted)

                    VStack(spacing: 0) {
                        ForEach(starters) { starter in
                            Button {
                                onSelect(starter.text)
                            } label: {
                                VStack(spacing: 0) {
                                    Rectangle().fill(BoopColors.hairline).frame(height: 1)

                                    HStack(alignment: .top, spacing: BoopSpacing.sm) {
                                        Image(systemName: starter.categoryIcon)
                                            .font(.system(size: 12, weight: .thin))
                                            .foregroundStyle(BoopColors.accentColor)
                                            .frame(width: 18)
                                            .padding(.top, 2)

                                        Text(starter.text)
                                            .font(BoopTypography.cineBody)
                                            .foregroundStyle(BoopColors.textPrimary)
                                            .multilineTextAlignment(.leading)

                                        Spacer(minLength: BoopSpacing.sm)

                                        Image(systemName: "arrow.turn.down.left")
                                            .font(.system(size: 11, weight: .thin))
                                            .foregroundStyle(BoopColors.textMuted)
                                            .padding(.top, 2)
                                    }
                                    .padding(.vertical, BoopSpacing.sm)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(BoopSpacing.md)
        .boopCard(radius: BoopRadius.sharp, shadow: false)
    }
}
