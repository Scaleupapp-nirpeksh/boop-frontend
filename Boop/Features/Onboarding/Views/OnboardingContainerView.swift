import SwiftUI

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            topChrome

            TabView(selection: $viewModel.currentStep) {
                BasicInfoView(viewModel: viewModel)
                    .tag(OnboardingStep.basicInfo)

                LocationView(viewModel: viewModel)
                    .tag(OnboardingStep.location)

                BioView(viewModel: viewModel)
                    .tag(OnboardingStep.bio)

                VoiceIntroView(onboardingVM: viewModel)
                    .tag(OnboardingStep.voiceIntro)

                PhotoUploadView(onboardingVM: viewModel)
                    .tag(OnboardingStep.photos)

                QuestionsView(onboardingVM: viewModel)
                    .tag(OnboardingStep.questions)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
        }
        .boopBackground()
        .navigationBarHidden(true)
    }

    private var topChrome: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Build your profile")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)

                    Text("Step \(viewModel.currentStepNumber) of \(viewModel.totalSteps)")
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textMuted)
                }

                Spacer()

                BoopStatPill(
                    icon: "sparkles",
                    value: viewModel.currentStep.title,
                    label: "Current focus",
                    tint: BoopColors.primary
                )
            }

            BoopProgressBar(
                currentStep: viewModel.currentStepNumber,
                totalSteps: viewModel.totalSteps
            )
        }
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.top, BoopSpacing.md)
        .padding(.bottom, BoopSpacing.sm)
    }
}
