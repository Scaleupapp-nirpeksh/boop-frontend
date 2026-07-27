import SwiftUI

struct OnboardingContainerView: View {
    @State private var viewModel = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            topChrome

            TabView(selection: $viewModel.currentStep) {
                BasicInfoView(viewModel: viewModel)
                    .tag(OnboardingStep.basicInfo)

                QuestionsView(onboardingVM: viewModel)
                    .tag(OnboardingStep.questions)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.25), value: viewModel.currentStep)
        }
        .background(BoopColors.ground.ignoresSafeArea())
        .navigationBarHidden(true)
        .overlay {
            if viewModel.showPairFork {
                PairForkView(viewModel: viewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showPairFork)
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


// MARK: - "Us" fork (invited users)

/// Shown once, right after basic info, when this account arrived through an
/// "Us" invite. The pair is already linked — this only asks about dating.
private struct PairForkView: View {
    var viewModel: OnboardingViewModel
    @State private var working = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()

            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                EyebrowLabel(text: "Us", color: BoopColors.accentColor)

                Text("You and \(viewModel.pairPartnerName ?? "your person") are linked ✧")
                    .font(BoopTypography.cineHeadline)
                    .foregroundStyle(BoopColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Your space is ready — chat, games, chemistry. One thing before you head in:")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Also want to meet new people here?")
                    .font(BoopTypography.cineBody)
                    .foregroundStyle(BoopColors.textPrimary)

                BoopButton(title: "Yes, show me around", isLoading: working) {
                    working = true
                    Task {
                        await viewModel.choosePairAndDating()
                        working = false
                    }
                }

                Button {
                    working = true
                    Task {
                        await viewModel.choosePairOnly()
                        working = false
                    }
                } label: {
                    Text("Not now — just Us")
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .disabled(working)
            }
            .padding(BoopSpacing.xl)
            .boopCard()
            .padding(.horizontal, BoopSpacing.xl)
        }
    }
}
