import SwiftUI

struct PublicProfile: Codable {
    let firstName: String
    let city: String?
    let questionsAnswered: Int
    let profileReady: Bool
    let photo: String?
}

struct PublicProfileResponse: Codable {
    let success: Bool
    let profile: PublicProfile
}

@Observable
class ProfilePreviewViewModel {
    var profile: PublicProfile?
    var isLoading = false
    var errorMessage: String?

    @MainActor
    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }

        guard let url = URL(string: "https://api.unmutee.in/api/v1/public/profile/\(userId)") else {
            errorMessage = "Invalid profile link."
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                errorMessage = "Profile not found."
                return
            }
            let decoder = JSONDecoder()
            let result = try decoder.decode(PublicProfileResponse.self, from: data)
            profile = result.profile
        } catch {
            errorMessage = "Could not load profile."
        }
    }
}

struct ProfilePreviewView: View {
    @State private var viewModel = ProfilePreviewViewModel()
    @State private var userId: String?

    // Cinematic Dark tokens (local — App Clip is an isolated target without the
    // main app's design system). Mirrors BoopColors / BoopTypography.
    private let accent = Color(red: 1.0, green: 0.302, blue: 0.427)        // #FF4D6D
    private let ground = Color(red: 0.047, green: 0.031, blue: 0.063)      // #0C0810
    private let textPrimary = Color(red: 0.957, green: 0.925, blue: 0.949) // #F4ECF2
    private let textSecondary = Color.white.opacity(0.62)
    private let textMuted = Color.white.opacity(0.40)
    private let hairline = Color.white.opacity(0.11)

    var body: some View {
        ZStack {
            ground.ignoresSafeArea()

            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(accent)
                    Text("LOADING")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(textMuted)
                }
            } else if let profile = viewModel.profile {
                profileCard(profile)
            } else {
                welcomeCard
            }
        }
        .preferredColorScheme(.dark)
        .task {
            if let userId {
                await viewModel.load(userId: userId)
            }
        }
    }

    private func profileCard(_ profile: PublicProfile) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            // Tracked wordmark
            Text("UNMUTEE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3)
                .foregroundStyle(textMuted)

            // Blurred portrait — stays blurred until you connect
            blurredPortrait(profile.photo)

            // Identity block
            VStack(alignment: .leading, spacing: 12) {
                Rectangle()
                    .fill(accent)
                    .frame(width: 24, height: 2)

                Text(profile.firstName)
                    .font(.system(size: 34, weight: .thin))
                    .foregroundStyle(textPrimary)

                if let city = profile.city {
                    Text(city.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(textSecondary)
                }

                HStack(spacing: 24) {
                    statColumn(value: "\(profile.questionsAnswered)", label: "ANSWERS")
                    if profile.profileReady {
                        statColumn(value: "READY", label: "PROFILE")
                    }
                }
                .padding(.top, 4)
            }

            // Note + CTA
            VStack(alignment: .leading, spacing: 16) {
                Rectangle()
                    .fill(hairline)
                    .frame(height: 1)

                Text("Photos stay blurred until you connect.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(textSecondary)

                Link(destination: URL(string: "https://apps.apple.com/app/boop/id000000000")!) {
                    Text("INSTALL TO CONNECT")
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    private func blurredPortrait(_ photoURL: String?) -> some View {
        ZStack {
            if let photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .blur(radius: 18)
                } placeholder: {
                    accent.opacity(0.18)
                }
            } else {
                accent.opacity(0.18)
                Image(systemName: "person.fill")
                    .font(.system(size: 44, weight: .thin))
                    .foregroundStyle(textMuted)
            }

            // Bottom scrim into ground
            LinearGradient(
                colors: [.clear, ground.opacity(0.5)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .frame(height: 260)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(hairline, lineWidth: 1)
        )
    }

    private var welcomeCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("UNMUTEE")
                .font(.system(size: 13, weight: .semibold))
                .tracking(4)
                .foregroundStyle(textPrimary)

            Rectangle()
                .fill(accent)
                .frame(width: 56, height: 2)

            Text("Personality before pixels")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(textSecondary)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(accent)
            }

            Link(destination: URL(string: "https://apps.apple.com/app/boop/id000000000")!) {
                Text("GET UNMUTEE")
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 40)
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .thin))
                .foregroundStyle(accent)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(textMuted)
        }
    }

    // MARK: - URL Parsing

    static func extractUserId(from url: URL) -> String? {
        // Expected: https://unmutee.in/profile/:userId
        let components = url.pathComponents
        guard components.count >= 3, components[1] == "profile" else { return nil }
        return components[2]
    }
}
