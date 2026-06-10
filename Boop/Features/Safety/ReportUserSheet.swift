import SwiftUI

/// Reusable report flow: pick a reason, add optional details, submit.
/// Presented from chat and match detail.
struct ReportUserSheet: View {
    let userId: String
    let userName: String
    var contentType: String = "profile"

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var details = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var submitted = false

    var body: some View {
        NavigationStack {
            Group {
                if submitted {
                    confirmationView
                } else {
                    formView
                }
            }
            .navigationTitle("Report \(userName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(BoopTypography.callout)
                        .foregroundStyle(BoopColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Form View

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {

                // Anonymity notice
                Text("Your report is anonymous — \(userName) won't know you reported them.")
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textSecondary)
                    .padding(.horizontal, BoopSpacing.md)
                    .padding(.top, BoopSpacing.xs)

                // Reason selection
                VStack(spacing: BoopSpacing.xs) {
                    ForEach(ReportReason.allCases) { reason in
                        reasonRow(reason)
                    }
                }
                .padding(.horizontal, BoopSpacing.md)

                // Optional details field
                VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                    BoopTextField(
                        label: "Additional details (optional)",
                        text: $details,
                        placeholder: "Tell us more about what happened…",
                        isMultiline: true,
                        maxLength: 500
                    )
                }
                .padding(.horizontal, BoopSpacing.md)

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
                        .padding(.horizontal, BoopSpacing.md)
                }

                // Submit button
                BoopButton(
                    title: "Submit Report",
                    variant: .primary,
                    isLoading: isSubmitting,
                    isDisabled: selectedReason == nil || isSubmitting
                ) {
                    Task { await submit() }
                }
                .padding(.horizontal, BoopSpacing.md)
                .padding(.bottom, BoopSpacing.xl)
            }
            .padding(.top, BoopSpacing.sm)
        }
        .background(BoopColors.background.ignoresSafeArea())
    }

    @ViewBuilder
    private func reasonRow(_ reason: ReportReason) -> some View {
        let isSelected = selectedReason == reason

        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedReason = reason
            }
        } label: {
            HStack(spacing: BoopSpacing.sm) {
                Text(reason.label)
                    .font(BoopTypography.callout)
                    .foregroundStyle(isSelected ? BoopColors.primary : BoopColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(isSelected ? BoopColors.primary : BoopColors.textMuted)
            }
            .padding(.horizontal, BoopSpacing.md)
            .padding(.vertical, BoopSpacing.sm)
            .boopCard(radius: BoopRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.md, style: .continuous)
                    .stroke(
                        isSelected ? BoopColors.primary.opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirmation View

    private var confirmationView: some View {
        VStack(spacing: BoopSpacing.xl) {
            Spacer()

            // Shield icon
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64, weight: .regular))
                .foregroundStyle(BoopColors.success)

            VStack(spacing: BoopSpacing.sm) {
                Text("Thanks for letting us know")
                    .font(BoopTypography.title2)
                    .foregroundStyle(BoopColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Our team will review this report. If you'd rather not hear from \(userName) again, you can also block them.")
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BoopSpacing.xl)
            }

            Spacer()

            BoopButton(title: "Done", variant: .primary) {
                dismiss()
            }
            .padding(.horizontal, BoopSpacing.md)
            .padding(.bottom, BoopSpacing.xl)
        }
        .background(BoopColors.background.ignoresSafeArea())
    }

    // MARK: - Submit

    private func submit() async {
        guard let reason = selectedReason else { return }
        isSubmitting = true
        errorMessage = nil

        do {
            try await APIClient.shared.requestVoid(
                .reportUser(
                    ReportUserRequest(
                        userId: userId,
                        reason: reason.rawValue,
                        details: details.isEmpty ? nil : details,
                        contentType: contentType
                    )
                )
            )
            submitted = true
        } catch {
            errorMessage = "Couldn't submit the report. Please try again."
        }

        isSubmitting = false
    }
}
