import SwiftUI

@Observable
class AuthViewModel {
    var phoneNumber = ""
    var otpCode = ""
    var isLoading = false
    var errorMessage: String?
    var showOTP = false
    var resendCountdown = 0

    private var resendTimer: Timer?

    var formattedPhone: String {
        "+91\(phoneNumber)"
    }

    var isPhoneValid: Bool {
        phoneNumber.count == 10
    }

    var isOTPValid: Bool {
        otpCode.count == 6
    }

    // MARK: - Send OTP

    @MainActor
    func sendOTP() async {
        guard isPhoneValid else { return }
        isLoading = true
        errorMessage = nil

        do {
            let _: SendOTPResponse = try await APIClient.shared.request(
                .sendOTP(SendOTPRequest(phone: formattedPhone))
            )
            showOTP = true
            startResendTimer()
        } catch let error as APIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isLoading = false
    }

    // MARK: - Verify OTP

    @MainActor
    func verifyOTP() async {
        guard isOTPValid else { return }
        isLoading = true
        errorMessage = nil

        do {
            let response: VerifyOTPResponse = try await APIClient.shared.request(
                .verifyOTP(VerifyOTPRequest(phone: formattedPhone, otp: otpCode))
            )
            AuthManager.shared.handleLoginSuccess(response: response)
        } catch let error as APIError {
            errorMessage = error.errorDescription
            otpCode = ""
        } catch {
            errorMessage = "Verification failed. Please try again."
            otpCode = ""
        }

        isLoading = false
    }

    // MARK: - Resend

    @MainActor
    func resendOTP() async {
        guard resendCountdown == 0 else { return }
        await sendOTP()
    }

    // MARK: - Timer

    private func startResendTimer() {
        resendCountdown = 60
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else {
                    timer.invalidate()
                    return
                }
                if self.resendCountdown > 0 {
                    self.resendCountdown -= 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }

    func reset() {
        otpCode = ""
        showOTP = false
        errorMessage = nil
        resendTimer?.invalidate()
        resendCountdown = 0
    }
}
