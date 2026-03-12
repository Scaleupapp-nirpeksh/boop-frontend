import Foundation

@Observable
final class DatePlanViewModel {
    let matchId: String

    var plans: [DatePlanItem] = []
    var venueSuggestions: [VenueSuggestion] = []
    var isLoading = false
    var isSubmitting = false
    var isLoadingSuggestions = false
    var errorMessage: String?
    var successMessage: String?

    // Propose form
    var venueName = ""
    var venueType = "coffee"
    var address = ""
    var proposedDate = Date().addingTimeInterval(86400) // tomorrow
    var proposedTime = ""
    var notes = ""
    var showProposalForm = false

    // Safety
    var safetyContactName = ""
    var safetyContactPhone = ""

    var activePlan: DatePlanItem? {
        plans.first { $0.status == "accepted" || $0.status == "proposed" }
    }

    var pendingPlanForMe: DatePlanItem? {
        let userId = AuthManager.shared.currentUser?.id ?? ""
        return plans.first { $0.status == "proposed" && $0.proposedBy != userId }
    }

    var pastPlans: [DatePlanItem] {
        plans.filter { $0.status == "completed" || $0.status == "declined" || $0.status == "cancelled" }
    }

    static let venueTypes = [
        ("coffee", "Coffee"),
        ("dinner", "Dinner"),
        ("activity", "Activity"),
        ("walk", "Walk"),
        ("drinks", "Drinks"),
        ("other", "Other"),
    ]

    init(matchId: String) {
        self.matchId = matchId
    }

    @MainActor
    func loadPlans() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: DatePlansResponse = try await APIClient.shared.request(.getDatePlans(matchId: matchId))
            plans = response.plans
            errorMessage = nil
        } catch {
            errorMessage = "Could not load date plans."
        }
    }

    @MainActor
    func proposePlan() async {
        guard !venueName.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a venue name."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        let formatter = ISO8601DateFormatter()
        let request = ProposeDatePlanRequest(
            venueName: venueName.trimmingCharacters(in: .whitespaces),
            venueType: venueType,
            address: address.isEmpty ? nil : address,
            proposedDate: formatter.string(from: proposedDate),
            proposedTime: proposedTime.isEmpty ? nil : proposedTime,
            notes: notes.isEmpty ? nil : notes
        )

        do {
            let response: DatePlanResponse = try await APIClient.shared.request(.proposeDatePlan(matchId: matchId, request: request))
            plans.insert(response.plan, at: 0)
            showProposalForm = false
            resetForm()
            successMessage = "Date plan sent!"
            errorMessage = nil
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not send date plan."
        }
    }

    @MainActor
    func respondToPlan(_ planId: String, accept: Bool, reason: String? = nil) async {
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let response: DatePlanResponse = try await APIClient.shared.request(
                .respondToDatePlan(planId: planId, accept: accept, declineReason: reason)
            )
            if let idx = plans.firstIndex(where: { $0._id == planId }) {
                plans[idx] = response.plan
            }
            successMessage = accept ? "Date confirmed!" : "Plan declined."
            errorMessage = nil
        } catch {
            errorMessage = "Could not respond to plan."
        }
    }

    @MainActor
    func cancelPlan(_ planId: String) async {
        do {
            let response: DatePlanResponse = try await APIClient.shared.request(.cancelDatePlan(planId: planId))
            if let idx = plans.firstIndex(where: { $0._id == planId }) {
                plans[idx] = response.plan
            }
        } catch {
            errorMessage = "Could not cancel plan."
        }
    }

    @MainActor
    func completePlan(_ planId: String) async {
        do {
            let response: DatePlanResponse = try await APIClient.shared.request(.completeDatePlan(planId: planId))
            if let idx = plans.firstIndex(where: { $0._id == planId }) {
                plans[idx] = response.plan
            }
            successMessage = "Date marked as completed!"
        } catch {
            errorMessage = "Could not complete plan."
        }
    }

    @MainActor
    func loadSuggestions() async {
        isLoadingSuggestions = true
        defer { isLoadingSuggestions = false }

        do {
            let response: VenueSuggestionsResponse = try await APIClient.shared.request(.getVenueSuggestions(matchId: matchId))
            venueSuggestions = response.suggestions
        } catch {
            // Silently fail
        }
    }

    @MainActor
    func setSafetyContact(planId: String) async {
        guard !safetyContactName.isEmpty, !safetyContactPhone.isEmpty else {
            errorMessage = "Please fill in both name and phone."
            return
        }

        do {
            let _: DatePlanResponse = try await APIClient.shared.request(
                .setSafetyContact(planId: planId, name: safetyContactName, phone: safetyContactPhone)
            )
            await loadPlans()
            successMessage = "Safety contact set!"
        } catch {
            errorMessage = "Could not set safety contact."
        }
    }

    @MainActor
    func checkIn(planId: String, status: String) async {
        do {
            let _: DatePlanResponse = try await APIClient.shared.request(.submitCheckIn(planId: planId, status: status))
            await loadPlans()
            if status == "help" {
                successMessage = "Alert sent to your safety contact."
            }
        } catch {
            errorMessage = "Could not submit check-in."
        }
    }

    private func resetForm() {
        venueName = ""
        venueType = "coffee"
        address = ""
        proposedDate = Date().addingTimeInterval(86400)
        proposedTime = ""
        notes = ""
    }
}
