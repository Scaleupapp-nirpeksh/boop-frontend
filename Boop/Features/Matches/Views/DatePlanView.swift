import SwiftUI

struct DatePlanView: View {
    @State var viewModel: DatePlanViewModel

    init(matchId: String) {
        _viewModel = State(initialValue: DatePlanViewModel(matchId: matchId))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
                // Pending plan from other user
                if let pending = viewModel.pendingPlanForMe {
                    incomingPlanSection(pending)
                }

                // Active confirmed plan
                if let active = viewModel.activePlan, active.status == "accepted" {
                    confirmedPlanSection(active)
                }

                // Propose new plan
                if viewModel.activePlan == nil {
                    proposalSection
                }

                // Past plans
                if !viewModel.pastPlans.isEmpty {
                    pastPlansSection
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(BoopTypography.cineCaption)
                        .tracking(0.5)
                        .foregroundStyle(BoopColors.error)
                }

                if let success = viewModel.successMessage {
                    Text(success)
                        .font(BoopTypography.cineCaption)
                        .tracking(0.5)
                        .foregroundStyle(BoopColors.success)
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.xl)
        }
        .boopBackground()
        .navigationTitle("Date Plans")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPlans()
        }
    }

    // MARK: - Incoming Plan (needs response)

    private func incomingPlanSection(_ plan: DatePlanItem) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            EyebrowLabel(text: "Date invitation", color: BoopColors.accentColor)
            AccentRule()

            Text("You've been asked on a date")
                .font(BoopTypography.cineTitle)
                .foregroundStyle(BoopColors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            planDetailRows(plan)

            HStack(spacing: BoopSpacing.sm) {
                BoopButton(title: "Accept", isLoading: viewModel.isSubmitting) {
                    Task { await viewModel.respondToPlan(plan._id, accept: true) }
                }

                BoopButton(title: "Decline", variant: .outline) {
                    Task { await viewModel.respondToPlan(plan._id, accept: false) }
                }
            }
            .padding(.top, BoopSpacing.xs)
        }
    }

    // MARK: - Confirmed Plan (with safety features)

    private func confirmedPlanSection(_ plan: DatePlanItem) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack(alignment: .firstTextBaseline) {
                    EyebrowLabel(text: "Date confirmed", color: BoopColors.success)
                    Spacer()
                    Button("Cancel") {
                        Task { await viewModel.cancelPlan(plan._id) }
                    }
                    .font(BoopTypography.cineLabel)
                    .tracking(2)
                    .foregroundStyle(BoopColors.error)
                }

                AccentRule()

                planDetailRows(plan)

                Button {
                    Task { await viewModel.completePlan(plan._id) }
                } label: {
                    HStack(spacing: BoopSpacing.xs) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .light))
                        Text("Mark as completed")
                            .font(BoopTypography.cineBody)
                    }
                    .foregroundStyle(BoopColors.accentColor)
                }
                .padding(.top, BoopSpacing.xxs)
            }

            // Safety section
            safetySection(plan)
        }
    }

    // MARK: - Safety Section

    private func safetySection(_ plan: DatePlanItem) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            EyebrowLabel(text: "Safety", color: BoopColors.accentColor)
            AccentRule()

            // Safety contact
            if let contact = plan.safetyContact, contact.name != nil {
                HStack(spacing: BoopSpacing.sm) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(BoopColors.success)
                    Text("\(contact.name ?? "") will be notified if needed")
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textSecondary)
                }
            } else {
                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                    Text("Share with a trusted friend")
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)

                    BoopTextField(
                        label: "Contact name",
                        text: $viewModel.safetyContactName,
                        placeholder: "Friend's name"
                    )

                    BoopTextField(
                        label: "Phone number",
                        text: $viewModel.safetyContactPhone,
                        placeholder: "+91..."
                    )

                    BoopButton(title: "Set Safety Contact", variant: .secondary) {
                        Task { await viewModel.setSafetyContact(planId: plan._id) }
                    }
                }
            }

            // Check-in
            VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                EyebrowLabel(text: "During your date")

                HStack(spacing: BoopSpacing.sm) {
                    checkInButton(
                        title: "I'm good",
                        icon: "checkmark",
                        tint: BoopColors.success
                    ) {
                        Task { await viewModel.checkIn(planId: plan._id, status: "ok") }
                    }

                    checkInButton(
                        title: "Need help",
                        icon: "exclamationmark.triangle",
                        tint: BoopColors.error
                    ) {
                        Task { await viewModel.checkIn(planId: plan._id, status: "help") }
                    }
                }
            }

            // Recent check-ins
            if let checkIns = plan.checkIns, !checkIns.isEmpty {
                VStack(spacing: 0) {
                    ForEach(checkIns.suffix(3)) { checkIn in
                        VStack(spacing: 0) {
                            Rectangle().fill(BoopColors.hairline).frame(height: 1)
                            HStack(spacing: BoopSpacing.sm) {
                                Image(systemName: checkIn.status == "ok" ? "checkmark" : "exclamationmark.triangle")
                                    .font(.system(size: 11, weight: .light))
                                    .foregroundStyle(checkIn.status == "ok" ? BoopColors.success : BoopColors.error)
                                Text(checkIn.status == "ok" ? "Checked in OK" : "Help requested")
                                    .font(BoopTypography.cineCaption)
                                    .foregroundStyle(BoopColors.textSecondary)
                                Spacer()
                                if let ts = checkIn.timestamp {
                                    Text(ts.formatted(.dateTime.hour().minute()))
                                        .font(BoopTypography.cineCaption)
                                        .foregroundStyle(BoopColors.textMuted)
                                }
                            }
                            .padding(.vertical, BoopSpacing.sm)
                        }
                    }
                    Rectangle().fill(BoopColors.hairline).frame(height: 1)
                }
            }
        }
    }

    private func checkInButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: BoopSpacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .regular))
                Text(title)
                    .font(BoopTypography.cineBody)
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, BoopSpacing.sm)
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                    .stroke(tint, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Proposal Section

    private var proposalSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.md) {
            if !viewModel.showProposalForm {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    EyebrowLabel(text: "Plan a date", color: BoopColors.accentColor)
                    AccentRule()
                    Text("Suggest a time and place to meet")
                        .font(BoopTypography.cineBodyLight)
                        .foregroundStyle(BoopColors.textSecondary)

                    BoopButton(title: "Propose a Date") {
                        withAnimation { viewModel.showProposalForm = true }
                        Task { await viewModel.loadSuggestions() }
                    }
                    .padding(.top, BoopSpacing.xs)
                }
            } else {
                proposalForm
            }
        }
    }

    private var proposalForm: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.lg) {
            HStack(alignment: .firstTextBaseline) {
                EyebrowLabel(text: "Plan a date", color: BoopColors.accentColor)
                Spacer()
                Button("Cancel") {
                    withAnimation { viewModel.showProposalForm = false }
                }
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(BoopColors.textMuted)
            }

            AccentRule()

            // AI venue suggestions
            if viewModel.isLoadingSuggestions {
                HStack(spacing: BoopSpacing.sm) {
                    ProgressView()
                        .tint(BoopColors.accentColor)
                    Text("Getting venue ideas")
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textSecondary)
                }
            } else if !viewModel.venueSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                    EyebrowLabel(text: "Suggestions")

                    VStack(spacing: 0) {
                        ForEach(viewModel.venueSuggestions) { suggestion in
                            Button {
                                viewModel.venueName = suggestion.name
                                viewModel.venueType = suggestion.type
                            } label: {
                                VStack(spacing: 0) {
                                    Rectangle().fill(BoopColors.hairline).frame(height: 1)
                                    HStack(alignment: .top, spacing: BoopSpacing.sm) {
                                        VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                                            Text(suggestion.name)
                                                .font(BoopTypography.cineBody)
                                                .foregroundStyle(BoopColors.textPrimary)
                                            Text(suggestion.reason)
                                                .font(BoopTypography.cineBodyLight)
                                                .foregroundStyle(BoopColors.textSecondary)
                                                .lineSpacing(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        Spacer(minLength: 0)
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .light))
                                            .foregroundStyle(BoopColors.accentColor)
                                    }
                                    .multilineTextAlignment(.leading)
                                    .padding(.vertical, BoopSpacing.md)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        Rectangle().fill(BoopColors.hairline).frame(height: 1)
                    }
                }
            }

            BoopTextField(
                label: "Venue name",
                text: $viewModel.venueName,
                placeholder: "Where would you like to go?"
            )

            // Venue type picker
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                Text("Type")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textSecondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: BoopSpacing.xs) {
                        ForEach(DatePlanViewModel.venueTypes, id: \.0) { type, label in
                            venueTypeChip(label, isSelected: viewModel.venueType == type) {
                                viewModel.venueType = type
                            }
                        }
                    }
                }
            }

            BoopTextField(
                label: "Address (optional)",
                text: $viewModel.address,
                placeholder: "Address or area"
            )

            // Date (future-dated; raw picker retains forward range)
            VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                Text("Date")
                    .font(BoopTypography.cineCaption)
                    .foregroundStyle(BoopColors.textSecondary)
                DatePicker(
                    "",
                    selection: $viewModel.proposedDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .tint(BoopColors.accentColor)
                .font(BoopTypography.cineBody)
            }

            BoopTextField(
                label: "Time (optional)",
                text: $viewModel.proposedTime,
                placeholder: "e.g. 7:00 PM"
            )

            BoopTextField(
                label: "Notes (optional)",
                text: $viewModel.notes,
                placeholder: "Anything else to mention?",
                isMultiline: true,
                maxLength: 500
            )

            BoopButton(title: "Send Proposal", isLoading: viewModel.isSubmitting) {
                Task { await viewModel.proposePlan() }
            }
        }
    }

    private func venueTypeChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(BoopTypography.cineLabel)
                .tracking(2)
                .foregroundStyle(isSelected ? BoopColors.accentColor : BoopColors.textMuted)
                .padding(.horizontal, BoopSpacing.md)
                .padding(.vertical, BoopSpacing.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: BoopRadius.sharp, style: .continuous)
                        .stroke(isSelected ? BoopColors.accentColor : BoopColors.hairline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Past Plans

    private var pastPlansSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            EyebrowLabel(text: "Past plans")

            VStack(spacing: 0) {
                ForEach(viewModel.pastPlans) { plan in
                    VStack(spacing: 0) {
                        Rectangle().fill(BoopColors.hairline).frame(height: 1)
                        HStack(spacing: BoopSpacing.sm) {
                            VStack(alignment: .leading, spacing: BoopSpacing.xxs) {
                                Text(plan.venue.name)
                                    .font(BoopTypography.cineBody)
                                    .foregroundStyle(BoopColors.textPrimary)
                                Text(plan.proposedDate.formatted(.dateTime.month(.abbreviated).day()))
                                    .font(BoopTypography.cineCaption)
                                    .foregroundStyle(BoopColors.textSecondary)
                            }
                            Spacer()
                            Text(plan.statusLabel.uppercased())
                                .font(BoopTypography.cineLabel)
                                .tracking(2)
                                .foregroundStyle(statusColor(plan.status))
                        }
                        .padding(.vertical, BoopSpacing.md)
                    }
                }
                Rectangle().fill(BoopColors.hairline).frame(height: 1)
            }
        }
    }

    // MARK: - Helpers

    private func planDetailRows(_ plan: DatePlanItem) -> some View {
        VStack(spacing: 0) {
            detailRow(label: plan.venue.name, sublabel: plan.venue.type?.capitalized)
            if let address = plan.venue.address, !address.isEmpty {
                detailRow(label: address, sublabel: nil)
            }
            detailRow(
                label: plan.proposedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
                sublabel: plan.proposedTime
            )
            if let notes = plan.notes, !notes.isEmpty {
                detailRow(label: notes, sublabel: nil)
            }
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
        }
    }

    private func detailRow(label: String, sublabel: String?) -> some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(alignment: .firstTextBaseline, spacing: BoopSpacing.sm) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(BoopTypography.cineBody)
                        .foregroundStyle(BoopColors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                if let sublabel {
                    Text(sublabel)
                        .font(BoopTypography.cineCaption)
                        .foregroundStyle(BoopColors.textSecondary)
                }
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "proposed": return BoopColors.accentColor
        case "accepted": return BoopColors.success
        case "declined": return BoopColors.error
        case "completed": return BoopColors.textSecondary
        default: return BoopColors.textMuted
        }
    }
}
