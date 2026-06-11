import SwiftUI

/// Focused, 2-step gate that turns a `preview` user into `ready` so they can connect.
/// Reuses the existing voice-recorder (`VoiceIntroView`) and photo-grid (`PhotoUploadView`)
/// by driving their `onComplete` closures instead of the onboarding `advanceStep()`.
/// On completion the backend has already flipped the stage to `ready`; we refresh the
/// current user (`.me` → `AuthManager.updateUser`) and invoke `onComplete`.
struct ConnectSetupView: View {
    /// Called once voice + photos are uploaded and the user has been refreshed to `ready`.
    var onComplete: () -> Void

    // Standalone onboarding VM purely to satisfy the reused views' bindings.
    // We override their completion via `onComplete`, so its step state is never used here.
    @State private var onboardingVM = OnboardingViewModel()
    @State private var step: Step = .voice
    @State private var isFinishing = false

    @Environment(\.dismiss) private var dismiss

    private enum Step: Int {
        case voice = 0
        case photos = 1
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                    intro
                    stepIndicator
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.top, BoopSpacing.lg)

                // Reused views own their internal ScrollView + padding; let them fill.
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .boopBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(BoopColors.textSecondary)
                        .disabled(isFinishing)
                }
            }
        }
        .presentationDetents([.large])
        .interactiveDismissDisabled(isFinishing)
    }

    // MARK: - Intro

    private var intro: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Almost there", color: BoopColors.accentColor)
            AccentRule()
            Text("Add your voice + photos to start connecting")
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text("People connect with the real you — a voice note and a few photos unlock messaging.")
                .font(BoopTypography.cineBodyLight)
                .foregroundStyle(BoopColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Step indicator (hairline ticks)

    private var stepIndicator: some View {
        HStack(spacing: BoopSpacing.xs) {
            stepTick(filled: true, label: "Voice")
            stepTick(filled: step == .photos, label: "Photos")
        }
    }

    private func stepTick(filled: Bool, label: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Rectangle()
                .fill(filled ? BoopColors.accentColor : BoopColors.hairline)
                .frame(height: 2)
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(filled ? BoopColors.textSecondary : BoopColors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Step content (reused subviews)

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .voice:
            VoiceIntroView(onboardingVM: onboardingVM) {
                withAnimation(.easeInOut(duration: 0.3)) { step = .photos }
            }
        case .photos:
            ZStack {
                PhotoUploadView(onboardingVM: onboardingVM) {
                    Task { await finish() }
                }

                if isFinishing {
                    VStack(spacing: BoopSpacing.sm) {
                        ProgressView()
                            .tint(BoopColors.accentColor)
                        Text("Finishing up…")
                            .font(BoopTypography.cineCaption)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(BoopColors.ground.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Finish

    @MainActor
    private func finish() async {
        isFinishing = true
        // Backend has flipped preview → ready on the photo upload; refresh to confirm.
        await AuthManager.shared.fetchCurrentUser()
        isFinishing = false
        onComplete()
        dismiss()
    }
}
