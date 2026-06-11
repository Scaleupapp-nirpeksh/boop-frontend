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
        .background(BoopColors.ground.ignoresSafeArea())
        .navigationBarHidden(true)
    }

    private var topChrome: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(
                    text: "Step \(String(format: "%02d", viewModel.currentStepNumber)) of \(String(format: "%02d", viewModel.totalSteps))",
                    color: BoopColors.accentColor
                )
                Spacer()
                EyebrowLabel(text: viewModel.currentStep.title, color: BoopColors.textMuted)
            }

            Text("Build your profile")
                .font(BoopTypography.cineHeadline)
                .foregroundStyle(BoopColors.textPrimary)

            HairlineProgress(
                progress: Double(viewModel.currentStepNumber) / Double(viewModel.totalSteps)
            )
            .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
        }
        .padding(.horizontal, BoopSpacing.xl)
        .padding(.top, BoopSpacing.md)
        .padding(.bottom, BoopSpacing.md)
    }
}
