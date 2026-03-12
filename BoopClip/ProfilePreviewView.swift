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

        guard let url = URL(string: "https://api.boop.app/api/v1/public/profile/\(userId)") else {
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

    // Colors (matching Boop design)
    private let coral = Color(red: 1.0, green: 0.42, blue: 0.42)
    private let teal = Color(red: 0.31, green: 0.80, blue: 0.77)
    private let bgColor = Color(red: 1.0, green: 0.976, blue: 0.961)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(teal)
                    Text("Loading profile...")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } else if let profile = viewModel.profile {
                profileCard(profile)
            } else {
                welcomeCard
            }
        }
        .task {
            if let userId {
                await viewModel.load(userId: userId)
            }
        }
    }

    private func profileCard(_ profile: PublicProfile) -> some View {
        VStack(spacing: 24) {
            // Logo
            Text("boop")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [coral, teal], startPoint: .leading, endPoint: .trailing)
                )

            // Blurred photo placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [coral.opacity(0.2), teal.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                if let photoURL = profile.photo, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .blur(radius: 15)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(teal.opacity(0.5))
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(teal.opacity(0.5))
                }
            }

            VStack(spacing: 8) {
                Text(profile.firstName)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                if let city = profile.city {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.system(size: 12))
                        Text(city)
                    }
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: 16) {
                    statPill(value: "\(profile.questionsAnswered)", label: "answers", color: coral)
                    if profile.profileReady {
                        statPill(value: "Ready", label: "profile", color: teal)
                    }
                }
                .padding(.top, 4)
            }

            VStack(spacing: 12) {
                Text("Photos are blurred until you connect.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Link(destination: URL(string: "https://apps.apple.com/app/boop/id000000000")!) {
                    Text("Download Boop to connect")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: [coral, teal], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 20, y: 10)
        )
        .padding(.horizontal, 24)
    }

    private var welcomeCard: some View {
        VStack(spacing: 20) {
            Text("boop")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [coral, teal], startPoint: .leading, endPoint: .trailing)
                )

            Text("Personality-first dating")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
            }

            Link(destination: URL(string: "https://apps.apple.com/app/boop/id000000000")!) {
                Text("Get Boop")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [coral, teal], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 40)
        }
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - URL Parsing

    static func extractUserId(from url: URL) -> String? {
        // Expected: https://boop.app/profile/:userId
        let components = url.pathComponents
        guard components.count >= 3, components[1] == "profile" else { return nil }
        return components[2]
    }
}
