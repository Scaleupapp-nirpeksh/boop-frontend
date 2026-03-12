import SwiftUI

struct DatePlanView: View {
    @State var viewModel: DatePlanViewModel

    init(matchId: String) {
        _viewModel = State(initialValue: DatePlanViewModel(matchId: matchId))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: BoopSpacing.lg) {
                // Pending plan from other user
                if let pending = viewModel.pendingPlanForMe {
                    incomingPlanCard(pending)
                }

                // Active confirmed plan
                if let active = viewModel.activePlan, active.status == "accepted" {
                    confirmedPlanCard(active)
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
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.error)
                }

                if let success = viewModel.successMessage {
                    Text(success)
                        .font(BoopTypography.footnote)
                        .foregroundStyle(BoopColors.success)
                }
            }
            .padding(.horizontal, BoopSpacing.xl)
            .padding(.vertical, BoopSpacing.lg)
        }
        .boopBackground()
        .navigationTitle("Date Plans")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPlans()
        }
    }

    // MARK: - Incoming Plan (needs response)

    private func incomingPlanCard(_ plan: DatePlanItem) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(BoopColors.primary)
                    Text("You have a date invitation!")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                }

                planDetailRows(plan)

                HStack(spacing: BoopSpacing.sm) {
                    BoopButton(title: "Accept", isLoading: viewModel.isSubmitting) {
                        Task { await viewModel.respondToPlan(plan._id, accept: true) }
                    }

                    BoopButton(title: "Decline", variant: .outline) {
                        Task { await viewModel.respondToPlan(plan._id, accept: false) }
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous)
                .stroke(BoopColors.primary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Confirmed Plan (with safety features)

    private func confirmedPlanCard(_ plan: DatePlanItem) -> some View {
        VStack(spacing: BoopSpacing.md) {
            BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
                VStack(alignment: .leading, spacing: BoopSpacing.md) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(BoopColors.success)
                        Text("Date Confirmed")
                            .font(BoopTypography.headline)
                            .foregroundStyle(BoopColors.textPrimary)
                        Spacer()
                        Button("Cancel") {
                            Task { await viewModel.cancelPlan(plan._id) }
                        }
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.error)
                    }

                    planDetailRows(plan)

                    Button {
                        Task { await viewModel.completePlan(plan._id) }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as completed")
                        }
                        .font(BoopTypography.callout)
                        .foregroundStyle(BoopColors.secondary)
                    }
                }
            }

            // Safety section
            safetyCard(plan)
        }
    }

    // MARK: - Safety Card

    private func safetyCard(_ plan: DatePlanItem) -> some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 18))
                        .foregroundStyle(BoopColors.secondary)
                    Text("Safety")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                }

                // Safety contact
                if let contact = plan.safetyContact, contact.name != nil {
                    HStack {
                        Image(systemName: "person.badge.shield.checkmark")
                            .foregroundStyle(BoopColors.success)
                        Text("\(contact.name ?? "") will be notified if needed")
                            .font(BoopTypography.footnote)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: BoopSpacing.sm) {
                        Text("Share with a trusted friend")
                            .font(BoopTypography.callout)
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

                Divider()

                // Check-in buttons
                Text("During your date")
                    .font(BoopTypography.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(BoopColors.textPrimary)

                HStack(spacing: BoopSpacing.sm) {
                    Button {
                        Task { await viewModel.checkIn(planId: plan._id, status: "ok") }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("I'm good")
                        }
                        .font(BoopTypography.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BoopSpacing.sm)
                        .background(BoopColors.success)
                        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
                    }

                    Button {
                        Task { await viewModel.checkIn(planId: plan._id, status: "help") }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Need help")
                        }
                        .font(BoopTypography.callout)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BoopSpacing.sm)
                        .background(BoopColors.error)
                        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
                    }
                }

                // Recent check-ins
                if let checkIns = plan.checkIns, !checkIns.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(checkIns.suffix(3)) { checkIn in
                            HStack(spacing: 6) {
                                Image(systemName: checkIn.status == "ok" ? "checkmark.circle" : "exclamationmark.triangle")
                                    .font(.system(size: 12))
                                    .foregroundStyle(checkIn.status == "ok" ? BoopColors.success : BoopColors.error)
                                Text(checkIn.status == "ok" ? "Checked in OK" : "Help requested")
                                    .font(BoopTypography.caption)
                                    .foregroundStyle(BoopColors.textSecondary)
                                Spacer()
                                if let ts = checkIn.timestamp {
                                    Text(ts.formatted(.dateTime.hour().minute()))
                                        .font(BoopTypography.caption)
                                        .foregroundStyle(BoopColors.textMuted)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Proposal Section

    private var proposalSection: some View {
        VStack(spacing: BoopSpacing.md) {
            if !viewModel.showProposalForm {
                BoopButton(title: "Propose a Date") {
                    withAnimation { viewModel.showProposalForm = true }
                    Task { await viewModel.loadSuggestions() }
                }
            } else {
                proposalForm
            }
        }
    }

    private var proposalForm: some View {
        BoopCard(padding: BoopSpacing.lg, radius: BoopRadius.xxl) {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                HStack {
                    Text("Plan a Date")
                        .font(BoopTypography.headline)
                        .foregroundStyle(BoopColors.textPrimary)
                    Spacer()
                    Button("Cancel") {
                        withAnimation { viewModel.showProposalForm = false }
                    }
                    .font(BoopTypography.footnote)
                    .foregroundStyle(BoopColors.textMuted)
                }

                // AI venue suggestions
                if viewModel.isLoadingSuggestions {
                    HStack {
                        ProgressView()
                        Text("Getting venue ideas...")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textSecondary)
                    }
                } else if !viewModel.venueSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                        Text("Suggestions")
                            .font(BoopTypography.caption)
                            .foregroundStyle(BoopColors.textMuted)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: BoopSpacing.xs) {
                                ForEach(viewModel.venueSuggestions) { suggestion in
                                    Button {
                                        viewModel.venueName = suggestion.name
                                        viewModel.venueType = suggestion.type
                                    } label: {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(suggestion.name)
                                                .font(BoopTypography.footnote)
                                                .fontWeight(.medium)
                                                .foregroundStyle(BoopColors.textPrimary)
                                            Text(suggestion.reason)
                                                .font(BoopTypography.caption)
                                                .foregroundStyle(BoopColors.textSecondary)
                                                .lineLimit(2)
                                        }
                                        .padding(BoopSpacing.sm)
                                        .frame(width: 180, alignment: .leading)
                                        .background(BoopColors.surfaceSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous))
                                    }
                                }
                            }
                        }
                    }
                }

                BoopTextField(
                    label: "Venue name",
                    text: $viewModel.venueName,
                    placeholder: "Where would you like to go?"
                )

                // Venue type picker
                VStack(alignment: .leading, spacing: 4) {
                    Text("Type")
                        .font(BoopTypography.subheadline)
                        .foregroundStyle(BoopColors.textSecondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: BoopSpacing.xs) {
                            ForEach(DatePlanViewModel.venueTypes, id: \.0) { type, label in
                                Button {
                                    viewModel.venueType = type
                                } label: {
                                    Text(label)
                                        .font(BoopTypography.footnote)
                                        .fontWeight(viewModel.venueType == type ? .semibold : .regular)
                                        .foregroundStyle(viewModel.venueType == type ? .white : BoopColors.textPrimary)
                                        .padding(.horizontal, BoopSpacing.sm)
                                        .padding(.vertical, 6)
                                        .background(viewModel.venueType == type ? BoopColors.primary : BoopColors.surfaceSecondary)
                                        .clipShape(Capsule())
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

                DatePicker(
                    "Date",
                    selection: $viewModel.proposedDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .font(BoopTypography.body)

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
    }

    // MARK: - Past Plans

    private var pastPlansSection: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("Past Plans")
                .font(BoopTypography.headline)
                .foregroundStyle(BoopColors.textPrimary)

            ForEach(viewModel.pastPlans) { plan in
                BoopCard(padding: BoopSpacing.md, radius: BoopRadius.xl) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.venue.name)
                                .font(BoopTypography.callout)
                                .foregroundStyle(BoopColors.textPrimary)
                            Text(plan.proposedDate.formatted(.dateTime.month(.abbreviated).day()))
                                .font(BoopTypography.caption)
                                .foregroundStyle(BoopColors.textSecondary)
                        }
                        Spacer()
                        Text(plan.statusLabel)
                            .font(BoopTypography.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(statusColor(plan.status))
                            .padding(.horizontal, BoopSpacing.xs)
                            .padding(.vertical, 3)
                            .background(statusColor(plan.status).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func planDetailRows(_ plan: DatePlanItem) -> some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            detailRow(icon: "mappin.circle.fill", label: plan.venue.name, sublabel: plan.venue.type?.capitalized)
            if let address = plan.venue.address, !address.isEmpty {
                detailRow(icon: "map.fill", label: address, sublabel: nil)
            }
            detailRow(
                icon: "calendar",
                label: plan.proposedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
                sublabel: plan.proposedTime
            )
            if let notes = plan.notes, !notes.isEmpty {
                detailRow(icon: "text.quote", label: notes, sublabel: nil)
            }
        }
    }

    private func detailRow(icon: String, label: String, sublabel: String?) -> some View {
        HStack(spacing: BoopSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(BoopColors.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(BoopTypography.body)
                    .foregroundStyle(BoopColors.textPrimary)
                if let sublabel {
                    Text(sublabel)
                        .font(BoopTypography.caption)
                        .foregroundStyle(BoopColors.textSecondary)
                }
            }
        }
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "proposed": return BoopColors.accent
        case "accepted": return BoopColors.success
        case "declined": return BoopColors.error
        case "completed": return BoopColors.secondary
        default: return BoopColors.textMuted
        }
    }
}
