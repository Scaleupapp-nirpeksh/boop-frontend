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
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Form View

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BoopSpacing.xl) {

                // Anonymity notice
                VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                    AccentRule()
                    Text("Your report is anonymous — \(userName) won't know you reported them.")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)
                }
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.top, BoopSpacing.sm)

                // Reason selection
                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                    EyebrowLabel(text: "Reason")
                        .padding(.horizontal, BoopSpacing.xl)

                    VStack(spacing: 0) {
                        ForEach(ReportReason.allCases) { reason in
                            reasonRow(reason)
                        }
                        Rectangle().fill(BoopColors.hairline).frame(height: 1)
                    }
                }

                // Optional details field
                BoopTextField(
                    label: "Additional details (optional)",
                    text: $details,
                    placeholder: "Tell us more about what happened…",
                    isMultiline: true,
                    maxLength: 500
                )
                .padding(.horizontal, BoopSpacing.xl)

                // Error message
                if let errorMessage {
                    Text(errorMessage)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.error)
                        .padding(.horizontal, BoopSpacing.xl)
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
                .padding(.horizontal, BoopSpacing.xl)
                .padding(.bottom, BoopSpacing.xl)
            }
        }
        .boopBackground()
    }

    @ViewBuilder
    private func reasonRow(_ reason: ReportReason) -> some View {
        let isSelected = selectedReason == reason

        Button {
            Haptics.light()
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedReason = reason
            }
        } label: {
            VStack(spacing: 0) {
                Rectangle().fill(BoopColors.hairline).frame(height: 1)

                HStack(spacing: BoopSpacing.sm) {
                    Text(reason.label)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(isSelected ? BoopColors.accentColor : BoopColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Image(systemName: isSelected ? "checkmark" : "circle")
                        .font(.system(size: 14, weight: .thin))
                        .foregroundStyle(isSelected ? BoopColors.accentColor : BoopColors.textMuted)
                }
                .padding(.vertical, BoopSpacing.md)
            }
            .padding(.horizontal, BoopSpacing.xl)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirmation View

    private var confirmationView: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xl) {
            Spacer()

            Image(systemName: "checkmark.shield")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(BoopColors.accentColor)

            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                AccentRule()

                Text("Thanks for letting us know")
                    .font(BoopTypography.cineTitle)
                    .foregroundStyle(BoopColors.textPrimary)

                Text("Our team will review this report. If you'd rather not hear from \(userName) again, you can also block them.")
                    .font(BoopTypography.cineBodyLight)
                    .foregroundStyle(BoopColors.textSecondary)
            }

            Spacer()

            BoopButton(title: "Done", variant: .primary) {
                dismiss()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BoopSpacing.xl)
        .boopBackground()
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
        } catch let error as APIError {
            errorMessage = error.errorDescription ?? "Couldn't submit the report. Please try again."
        } catch {
            errorMessage = "Couldn't submit the report. Please try again."
        }

        isSubmitting = false
    }
}
