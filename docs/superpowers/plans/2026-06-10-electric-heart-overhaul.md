# Electric Heart Design + Feature Overhaul — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform UnMutee's look and daily-loop UX into the "Electric Heart" identity — semantic light/dark tokens, blur-as-hero portraits, a Moment-Led home, a fog-based comfort-to-reveal chat, a celebrated reveal moment, and a stalled-match recovery flow.

**Architecture:** Additive semantic color layer repoints the existing `BoopColors` names (so all call sites keep compiling and inherit the new look), a shared `BlurredPortrait` + `FogBlur` curve power the human-first visuals, and the daily-loop screens (Home, Chat, reveal) are recomposed from existing view models and models — no backend changes. Implements `docs/superpowers/specs/2026-06-10-design-overhaul.md`.

**Tech Stack:** SwiftUI (iOS 17, `@Observable`), xcodegen (`project.yml` is source of truth; `Boop.xcodeproj/project.pbxproj` is generated **and tracked** — commit it when files are added), Nunito via `Font.nunito(_:size:)`, Firebase/PostHog already wired.

**Verification model:** No XCUITest/unit target exists in this repo; the gate is `xcodebuild ... build` → `BUILD SUCCEEDED` plus the explicit visual check named in each task. Pure-logic helpers (`FogBlur.radius`, `AppTheme.colorScheme`) are written to documented expected values and checked by reasoning + a `#Preview`. Adding a test target is out of scope.

**Build command (used throughout):**
```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend" && xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -6
```
When a task adds or removes files, run `xcodegen generate` first and `git add` the `project.pbxproj`.

**Phases (each independently shippable):**
1. Foundation — tokens + dark mode + `BlurredPortrait`/`FogBlur` (Tasks 1–2)
2. Home — Moment-Led Feed (Tasks 3–4)
3. Chat — The Fog (Tasks 5–6)
4. Reveal — The Clearing (Task 7)
5. Supporting — stalled matches + games surfacing (Tasks 8–9)
6. Sweep — theme toggle + per-screen polish + final verification (Task 10)

---

## Task 1: Semantic adaptive color tokens + dark mode

**Files:**
- Create: `Boop/DesignSystem/Theme/AppTheme.swift`
- Modify: `Boop/Core/Extensions/Color+Boop.swift` (add `Color.dynamic`)
- Modify: `Boop/DesignSystem/Theme/BoopColors.swift` (repoint to adaptive tokens + add brand gradient)
- Modify: `Boop/App/BoopApp.swift` (remove forced light, apply theme override)

- [ ] **Step 1: Add the dynamic-color helper**

Append to `Boop/Core/Extensions/Color+Boop.swift` (after the existing `init(hex:)`):

```swift
extension Color {
    /// Resolves to `light` or `dark` based on the active interface style at render time.
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
```

- [ ] **Step 2: Create the theme model**

```swift
// Boop/DesignSystem/Theme/AppTheme.swift
import SwiftUI

/// User-selectable appearance, persisted via @AppStorage("appTheme").
enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    /// nil = follow system. Applied via .preferredColorScheme at the root.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
```

- [ ] **Step 3: Repoint `BoopColors` to adaptive tokens + add the Electric Heart brand**

Edit `Boop/DesignSystem/Theme/BoopColors.swift`. Replace the **Brand**, **Backgrounds**, **Text**, **Borders**, and **Gradients** sections (lines ~4–21, ~55–64) with the following. Leave the dark-card / tinted-surface / dimension sections in place (they're used by existing screens and still compile); the redesigned surfaces simply stop referencing the mint/yellow ones.

```swift
    // MARK: - Brand (Electric Heart)
    static let brand = Color.dynamic(light: Color(hex: "FF4D6D"), dark: Color(hex: "FF5C7A"))      // coral
    static let brandViolet = Color.dynamic(light: Color(hex: "A23DE8"), dark: Color(hex: "B65CF0")) // violet
    static let primary = brand          // repoint legacy name
    static let secondary = brandViolet  // repoint legacy name (was mint)
    static let accent = Color.dynamic(light: Color(hex: "FF8A5C"), dark: Color(hex: "FFA06E"))      // warm ember

    // MARK: - Backgrounds (adaptive)
    static let background = Color.dynamic(light: Color(hex: "FFFBF7"), dark: Color(hex: "120A16"))
    static let backgroundBlush = Color.dynamic(light: Color(hex: "FFF1EB"), dark: Color(hex: "1A0F1E"))
    static let backgroundMint = Color.dynamic(light: Color(hex: "F3E8F0"), dark: Color(hex: "1A0F22"))
    static let surface = Color.dynamic(light: .white, dark: Color(hex: "1C1124"))
    static let surfaceSecondary = Color.dynamic(light: Color(hex: "F8F4F0"), dark: Color(hex: "241630"))
    static let surfaceElevated = Color.dynamic(light: Color(hex: "FFFCFA"), dark: Color(hex: "241630"))

    // MARK: - Text (adaptive)
    static let textPrimary = Color.dynamic(light: Color(hex: "2A1A2E"), dark: Color(hex: "F4ECF2"))
    static let textSecondary = Color.dynamic(light: Color(hex: "6B5B70"), dark: Color(hex: "B3A4BC"))
    static let textMuted = Color.dynamic(light: Color(hex: "9B8FA5"), dark: Color(hex: "6E6076"))
    static let textOnPrimary = Color.white
```

Then replace `primaryGradient` and add `brandGradient`:

```swift
    // MARK: - Gradients
    static let brandGradient = LinearGradient(
        colors: [brand, brandViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let primaryGradient = brandGradient   // repoint legacy name (BoopButton uses this)
```

And make `border`/`chatBackground`/`chatBubbleReceived` adaptive (find these lines and replace):

```swift
    static let border = Color.dynamic(light: Color(hex: "EEE6EE"), dark: Color(hex: "2E2238"))
    static let chatBackground = Color.dynamic(light: Color(hex: "F6F2EE"), dark: Color(hex: "160C1C"))
    static let chatBubbleReceived = Color.dynamic(light: .white, dark: Color(hex: "241630"))
```

Keep `borderFocus = primary`, the dark-card constants, tinted surfaces, and `dimensionColor(for:)` as-is so existing screens compile.

- [ ] **Step 4: Remove forced light mode and apply the theme override**

Replace `Boop/App/BoopApp.swift` body:

```swift
import SwiftUI

@main
struct BoopApp: App {
    @UIApplicationDelegateAdaptor(BoopAppDelegate.self) private var appDelegate
    @State private var appState = AppState()
    @AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue

    init() {
        Analytics.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme ?? nil)
        }
    }
}
```

- [ ] **Step 5: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 6: Visual check**

Run in the iOS Simulator. Confirm: (a) buttons now show the coral→violet gradient; (b) toggling the simulator's appearance (Features → Toggle Appearance, or Settings → Developer → Dark Appearance) flips the app to the deep-plum dark theme with legible text; (c) nothing renders white-on-white or black-on-black.

- [ ] **Step 7: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
xcodegen generate
git add project.yml Boop.xcodeproj/project.pbxproj Boop/DesignSystem/Theme/AppTheme.swift Boop/DesignSystem/Theme/BoopColors.swift Boop/Core/Extensions/Color+Boop.swift Boop/App/BoopApp.swift
git commit -m "feat(design): Electric Heart semantic tokens + dark mode"
```

---

## Task 2: `BlurredPortrait` component + `FogBlur` curve

**Files:**
- Create: `Boop/DesignSystem/Components/FogBlur.swift`
- Create: `Boop/DesignSystem/Components/BlurredPortrait.swift`

- [ ] **Step 1: Create the blur curve (pure logic)**

```swift
// Boop/DesignSystem/Components/FogBlur.swift
import CoreGraphics

/// Maps a comfort score (0–100) and match stage to a blur radius, so faces
/// visibly sharpen as a connection grows. Revealed/dating = fully clear.
///
/// Expected values (verified by reasoning):
///   stage "revealed"/"dating" → 0
///   comfort nil/0  → 30   (heavy fog)
///   comfort 35     → ~18
///   comfort 70     → 6    (reveal threshold — almost clear)
///   comfort 100    → 2
enum FogBlur {
    static func radius(forComfort comfort: Int?, stage: String?) -> CGFloat {
        if stage == "revealed" || stage == "dating" { return 0 }
        let c = max(0, min(100, comfort ?? 0))
        // Linear: 0 → 30, 100 → 2.
        let radius = 30.0 - (CGFloat(c) / 100.0) * 28.0
        return max(2, radius)
    }
}
```

- [ ] **Step 2: Create the portrait component**

```swift
// Boop/DesignSystem/Components/BlurredPortrait.swift
import SwiftUI

enum PortraitShape {
    case circle
    case roundedRect(CGFloat)
}

/// The app's shared human-first visual: a remote portrait blurred to a given
/// radius (animated, so faces sharpen over time), with an optional dark scrim
/// and overlay content (name, presence, streak). Built on BoopRemoteImage.
struct BlurredPortrait<Overlay: View>: View {
    let urlString: String?
    var blurRadius: CGFloat = 0
    var shape: PortraitShape = .roundedRect(BoopRadius.lg)
    var scrim: Bool = true
    @ViewBuilder var overlay: () -> Overlay

    init(
        urlString: String?,
        blurRadius: CGFloat = 0,
        shape: PortraitShape = .roundedRect(BoopRadius.lg),
        scrim: Bool = true,
        @ViewBuilder overlay: @escaping () -> Overlay = { EmptyView() }
    ) {
        self.urlString = urlString
        self.blurRadius = blurRadius
        self.shape = shape
        self.scrim = scrim
        self.overlay = overlay
    }

    var body: some View {
        ZStack {
            BoopRemoteImage(urlString: urlString) {
                BoopColors.brandGradient.opacity(0.35)
            }
            .blur(radius: blurRadius)
            .animation(.easeInOut(duration: 0.6), value: blurRadius)

            if scrim {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            overlay()
        }
        .clipShape(clipShape)
        .contentShape(clipShape)
    }

    private var clipShape: AnyShape {
        switch shape {
        case .circle: return AnyShape(Circle())
        case .roundedRect(let r): return AnyShape(RoundedRectangle(cornerRadius: r, style: .continuous))
        }
    }
}
```

- [ ] **Step 3: Build**

Run `xcodegen generate` then the build command. Expected: `BUILD SUCCEEDED`. (`AnyShape` is iOS 16+, fine on the 17 target.)

- [ ] **Step 4: Visual check via preview**

Add a temporary `#Preview` at the bottom of `BlurredPortrait.swift` rendering three instances at `blurRadius: 24, 8, 0` with a sample `urlString` and a name overlay; open the Xcode canvas and confirm the blur visibly steps from heavy → clear. Remove the preview before committing (or keep a minimal one).

- [ ] **Step 5: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add project.yml Boop.xcodeproj/project.pbxproj Boop/DesignSystem/Components/FogBlur.swift Boop/DesignSystem/Components/BlurredPortrait.swift
git commit -m "feat(design): BlurredPortrait + FogBlur comfort→blur curve"
```

---

## Task 3: Home section components — Moment hero + Your People row

**Files:**
- Create: `Boop/Features/Home/Views/MomentHeroCard.swift`
- Create: `Boop/Features/Home/Views/YourPeopleRow.swift`

These consume the existing `MatchInfo` model (`Boop/Models/DiscoverModels.swift`): `matchId`, `comfortScore: Int?`, `stage`, `streak?.current`, `otherUser.firstName`, `otherUser.isOnline`, `otherUser.blurLevel`, `otherUser.photos.profilePhotoUrl/blurredUrl/silhouetteUrl`, `otherUser.voiceIntro?.audioUrl`.

- [ ] **Step 1: Add a portrait-URL helper on MatchInfo**

Append to `Boop/Models/DiscoverModels.swift` (after the `MatchInfo` struct):

```swift
extension MatchInfo {
    /// Best available portrait for the current stage: clear if revealed, else
    /// blurred, else silhouette. BlurredPortrait adds the comfort-based fog on top.
    var heroPhotoURL: String? {
        if stage == "revealed" || stage == "dating" {
            return otherUser.photos.profilePhotoUrl ?? otherUser.photos.blurredUrl
        }
        return otherUser.photos.blurredUrl ?? otherUser.photos.silhouetteUrl ?? otherUser.photos.profilePhotoUrl
    }

    var displayName: String {
        if let age = otherUser.age { return "\(otherUser.firstName), \(age)" }
        return otherUser.firstName
    }
}
```

- [ ] **Step 2: Create the hero card**

```swift
// Boop/Features/Home/Views/MomentHeroCard.swift
import SwiftUI

/// The single most charged item on Home: the connection closest to reveal,
/// rendered as a near-clear portrait with a headline and one tap target.
struct MomentHeroCard: View {
    let match: MatchInfo

    private var comfort: Int { match.comfortScore ?? 0 }
    private var pointsToReveal: Int { max(0, 70 - comfort) }

    private var headline: String {
        if match.stage == "revealed" || match.stage == "dating" {
            return "You've revealed — keep it going"
        }
        if pointsToReveal == 0 { return "You're ready to reveal 👀" }
        return "\(pointsToReveal) points from seeing each other"
    }

    var body: some View {
        BlurredPortrait(
            urlString: match.heroPhotoURL,
            blurRadius: FogBlur.radius(forComfort: match.comfortScore, stage: match.stage),
            shape: .roundedRect(BoopRadius.xxl)
        ) {
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                Spacer()
                Text(headline.uppercased())
                    .font(.nunito(.bold, size: 11))
                    .foregroundStyle(Color(hex: "FFD6DD"))
                Text(match.displayName)
                    .font(.nunito(.extraBold, size: 26))
                    .foregroundStyle(.white)
                HStack(spacing: BoopSpacing.xs) {
                    if let streak = match.streak?.current, streak > 0 {
                        Text("🔥 \(streak)")
                            .font(.nunito(.bold, size: 12))
                            .foregroundStyle(.white)
                    }
                    if match.otherUser.isOnline == true {
                        Text("● online")
                            .font(.nunito(.semiBold, size: 11))
                            .foregroundStyle(BoopColors.success)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
        }
        .frame(height: 200)
        .shadow(color: BoopColors.brand.opacity(0.25), radius: 18, y: 10)
    }
}
```

- [ ] **Step 3: Create the Your People row**

```swift
// Boop/Features/Home/Views/YourPeopleRow.swift
import SwiftUI

/// Horizontal row of active connections as portraits that sharpen by comfort.
struct YourPeopleRow: View {
    let matches: [MatchInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("YOUR PEOPLE")
                .font(.nunito(.bold, size: 12))
                .foregroundStyle(BoopColors.textSecondary)
                .padding(.horizontal, BoopSpacing.xl)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: BoopSpacing.sm) {
                    ForEach(matches) { match in
                        NavigationLink {
                            MatchDetailView(matchId: match.matchId)
                        } label: {
                            personCell(match)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, BoopSpacing.xl)
            }
        }
    }

    private func personCell(_ match: MatchInfo) -> some View {
        VStack(spacing: 6) {
            BlurredPortrait(
                urlString: match.heroPhotoURL,
                blurRadius: FogBlur.radius(forComfort: match.comfortScore, stage: match.stage),
                shape: .roundedRect(BoopRadius.lg),
                scrim: false
            ) {
                if match.otherUser.isOnline == true {
                    VStack {
                        HStack {
                            Spacer()
                            Circle().fill(BoopColors.success)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 84, height: 84)
            .overlay(
                RoundedRectangle(cornerRadius: BoopRadius.lg, style: .continuous)
                    .stroke((match.comfortScore ?? 0) >= 70 ? BoopColors.brand : Color.clear, lineWidth: 2)
            )

            Text(match.otherUser.firstName)
                .font(.nunito(.semiBold, size: 12))
                .foregroundStyle(BoopColors.textPrimary)
                .lineLimit(1)
            Text("\(match.comfortScore ?? 0)/70")
                .font(.nunito(.medium, size: 10))
                .foregroundStyle(BoopColors.textMuted)
        }
        .frame(width: 84)
    }
}
```

- [ ] **Step 4: Build**

Run `xcodegen generate` then the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 5: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add project.yml Boop.xcodeproj/project.pbxproj Boop/Models/DiscoverModels.swift Boop/Features/Home/Views/MomentHeroCard.swift Boop/Features/Home/Views/YourPeopleRow.swift
git commit -m "feat(home): MomentHeroCard + YourPeopleRow components"
```

---

## Task 4: Recompose Home into the Moment-Led Feed

**Files:**
- Create: `Boop/Features/Home/Views/DailyQuestionBand.swift`
- Modify: `Boop/Features/Home/Views/HomeView.swift` (replace section composition; keep celebration overlay, notification bell, `.task`/`.onReceive`, sheet)

The hero = the active match with the highest comfort score. "New tonight" reuses the already-loaded `incomingPendingLikes` ("who liked you") — no new fetch, honest to available data. The daily-question band drives the existing `QuestionsFullView` sheet via `viewModel.showQuestionsSheet`. (Surfacing matches' answers to the same question needs a backend endpoint and is deferred per spec §9.)

- [ ] **Step 1: Create the daily-question band**

```swift
// Boop/Features/Home/Views/DailyQuestionBand.swift
import SwiftUI

/// The daily ritual entry — taps into the existing Questions flow.
struct DailyQuestionBand: View {
    let newCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: { Haptics.light(); onTap() }) {
            VStack(alignment: .leading, spacing: 6) {
                Text("TODAY'S QUESTIONS")
                    .font(.nunito(.bold, size: 11))
                    .foregroundStyle(.white.opacity(0.85))
                Text(newCount > 0
                     ? "\(newCount) new unlocked — answer to grow your profile"
                     : "Answer today's questions to deepen your matches")
                    .font(.nunito(.bold, size: 16))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Text("Open").font(.nunito(.semiBold, size: 12))
                    Image(systemName: "arrow.right").font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BoopSpacing.lg)
            .background(BoopColors.brandGradient)
            .clipShape(RoundedRectangle(cornerRadius: BoopRadius.xxl, style: .continuous))
            .shadow(color: BoopColors.brand.opacity(0.3), radius: 14, y: 8)
        }
        .padding(.horizontal, BoopSpacing.xl)
    }
}
```

- [ ] **Step 2: Replace the Home body composition**

In `Boop/Features/Home/Views/HomeView.swift`, replace the `ScrollView { VStack { ... } }` content (the children currently: `header`, seasonal, newQuestionsBanner, `connectionsSection`, `activitySection`) with the Moment-Led order. Keep everything else (the `ZStack`, celebration overlay block, `.task`, `.boopBackground()`, `.sheet`, `.onReceive` handlers) unchanged.

```swift
            ScrollView {
                VStack(spacing: BoopSpacing.xl) {
                    greetingHeader

                    if let hero = heroMatch {
                        NavigationLink {
                            MatchDetailView(matchId: hero.matchId)
                        } label: {
                            MomentHeroCard(match: hero)
                                .padding(.horizontal, BoopSpacing.xl)
                        }
                        .buttonStyle(.plain)
                    }

                    if !viewModel.activeMatches.isEmpty {
                        YourPeopleRow(matches: viewModel.activeMatches)
                    }

                    DailyQuestionBand(newCount: viewModel.newQuestionsCount) {
                        viewModel.showQuestionsSheet = true
                    }

                    if !viewModel.incomingPendingLikes.isEmpty {
                        activitySection   // existing "Liked You" / "Waiting On Them" section, reused as "new tonight"
                    } else if viewModel.activeMatches.isEmpty {
                        emptyDiscoverPrompt
                    }
                }
                .padding(.vertical, BoopSpacing.lg)
            }
            .refreshable { await viewModel.refresh() }
```

- [ ] **Step 3: Add the new helper views + computed hero to HomeView**

Add these inside `HomeView` (you may delete the old `header`, `newQuestionsBanner`, `connectionsSection`, `dailySummary`, `statCard` once nothing references them — but `activitySection` and `seasonalBanner` stay):

```swift
    /// The connection closest to the reveal — the hero of the feed.
    private var heroMatch: MatchInfo? {
        viewModel.activeMatches.max(by: { ($0.comfortScore ?? 0) < ($1.comfortScore ?? 0) })
    }

    private var greetingHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("good evening")
                    .font(.nunito(.medium, size: 13))
                    .foregroundStyle(BoopColors.textSecondary)
                Text(AuthManager.shared.currentUser?.firstName ?? "you")
                    .font(.nunito(.extraBold, size: 26))
                    .foregroundStyle(BoopColors.textPrimary)
            }
            Spacer()
            if let streak = topStreak, streak > 0 {
                Text("🔥 \(streak)")
                    .font(.nunito(.bold, size: 13))
                    .foregroundStyle(BoopColors.brand)
                    .padding(.horizontal, BoopSpacing.sm)
                    .padding(.vertical, 6)
                    .background(BoopColors.backgroundBlush)
                    .clipShape(Capsule())
            }
            NavigationLink(value: NotificationRoute()) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(BoopColors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(BoopColors.surface)
                        .clipShape(Circle())
                    if notificationVM.unreadCount > 0 {
                        Text(notificationVM.unreadCount > 99 ? "99+" : "\(notificationVM.unreadCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(BoopColors.brand)
                            .clipShape(Capsule())
                            .offset(x: 4, y: -2)
                    }
                }
            }
            .accessibilityLabel("Notifications")
        }
        .padding(.horizontal, BoopSpacing.xl)
    }

    private var topStreak: Int? {
        viewModel.activeMatches.compactMap { $0.streak?.current }.max()
    }

    private var emptyDiscoverPrompt: some View {
        VStack(spacing: BoopSpacing.sm) {
            Text("✨").font(.system(size: 36))
            Text("Find your first connection")
                .font(.nunito(.bold, size: 16))
                .foregroundStyle(BoopColors.textPrimary)
            Text("Head to Discover to meet someone whose answers match yours.")
                .font(.nunito(.regular, size: 13))
                .foregroundStyle(BoopColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(BoopSpacing.xl)
        .boopCard(radius: BoopRadius.xxl)
        .padding(.horizontal, BoopSpacing.xl)
    }
```

- [ ] **Step 4: Build**

Run `xcodegen generate` then the build command. Expected: `BUILD SUCCEEDED`. If the compiler flags an unused private method (`header`, `statCard`, etc.), delete it.

- [ ] **Step 5: Visual check**

Simulator: Home now opens on greeting → hero portrait (blurred, sharpening) → Your People row → gradient daily-question band → "Liked You"/empty prompt. Confirm the hero taps into Match Detail, the band opens the Questions sheet, and dark mode still reads.

- [ ] **Step 6: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add project.yml Boop.xcodeproj/project.pbxproj Boop/Features/Home/Views/DailyQuestionBand.swift Boop/Features/Home/Views/HomeView.swift
git commit -m "feat(home): Moment-Led Feed composition"
```

---

## Task 5: Chat — load comfort + The Fog background

**Files:**
- Modify: `Boop/Features/Chat/ViewModels/ChatViewModels.swift` (add `comfortScore`, `loadComfort()`)
- Modify: `Boop/Features/Chat/Views/ChatInboxView.swift` (fog background + header pill in `ChatConversationView`)

`ConversationInfo` has `matchId: String?` and `matchStage: String?`. `APIEndpoint.getComfortScore(matchId:)` returns `ComfortScoreResponse { score, ... }` (both already exist).

- [ ] **Step 1: Add comfort loading to the view model**

In `ChatConversationViewModel` (`ChatViewModels.swift`), add a property near the others:

```swift
    var comfortScore: Int?
```

Add this method (mirroring the existing `@MainActor func` style):

```swift
    @MainActor
    func loadComfort() async {
        guard let matchId = conversation.matchId else { return }
        do {
            let response: ComfortScoreResponse = try await APIClient.shared.request(.getComfortScore(matchId: matchId))
            comfortScore = response.score
        } catch {
            // Non-critical — the fog just stays at its current density.
        }
    }
```

- [ ] **Step 2: Call it when the conversation opens**

In `ChatConversationView` (`ChatInboxView.swift`), find the `.task { ... }` (or the `onAppear`/initial load that calls `viewModel.loadMessages()` / `loadConversationStarters()`) and add `await viewModel.loadComfort()` alongside the existing loads. If there is no `.task`, add one on the root `VStack`:

```swift
        .task {
            await viewModel.loadComfort()
        }
```

(Keep any existing `.task`; just add the comfort load to it.)

- [ ] **Step 3: Add the fog background + header pill**

In `ChatConversationView.body`, wrap the existing root `VStack(spacing: 0) { ... }` in a `ZStack` whose first layer is the fog. Add this computed property and apply it:

```swift
    private var fogBlurRadius: CGFloat {
        // Extra fog on top of the backend's already-stage-appropriate photo.
        FogBlur.radius(forComfort: viewModel.comfortScore, stage: conversation.matchStage)
    }
```

Root structure becomes:

```swift
        ZStack {
            // Fog layer — their portrait, blurred by comfort, behind a scrim.
            if let photo = conversation.otherUser.photo {
                BoopRemoteImage(urlString: photo) { Color.clear }
                    .blur(radius: fogBlurRadius)
                    .animation(.easeInOut(duration: 0.6), value: fogBlurRadius)
                    .overlay(BoopColors.chatBackground.opacity(0.82))
                    .ignoresSafeArea()
            } else {
                BoopColors.chatBackground.ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // ... existing chat content unchanged ...
            }
        }
```

In the existing `.toolbar` principal item (the name/status block), add the fog pill under the name — a tappable capsule that shows progress and opens the comfort detail. Add state `@State private var showComfortDetail = false` to `ChatConversationView`, and in the principal `VStack(alignment: .leading)` add:

```swift
                        if let comfort = viewModel.comfortScore, conversation.matchStage != "revealed", conversation.matchStage != "dating" {
                            Button { showComfortDetail = true } label: {
                                Text("the fog is lifting · \(comfort)/70")
                                    .font(.nunito(.semiBold, size: 11))
                                    .foregroundStyle(BoopColors.brand)
                            }
                        }
```

And present the existing comfort breakdown — reuse `MatchDetailView` gated to comfort, or a lightweight sheet. For v1, present `MatchDetailView` for the match:

```swift
        .sheet(isPresented: $showComfortDetail) {
            if let matchId = conversation.matchId {
                NavigationStack { MatchDetailView(matchId: matchId) }
            }
        }
```

- [ ] **Step 4: Build**

Run the build command. Expected: `BUILD SUCCEEDED`. Watch for legibility — bubbles must stay readable over the fog; the `0.82` scrim opacity ensures it. If text is hard to read in dark mode, raise the scrim opacity to `0.88`.

- [ ] **Step 5: Visual check**

Open a conversation: the other person's blurred face washes the background, a "the fog is lifting · N/70" pill sits under their name, and messages remain crisply readable in both themes.

- [ ] **Step 6: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add Boop/Features/Chat/ViewModels/ChatViewModels.swift Boop/Features/Chat/Views/ChatInboxView.swift
git commit -m "feat(chat): The Fog — comfort-driven blurred background + progress pill"
```

---

## Task 6: Chat — nudge chips toward the reveal

**Files:**
- Modify: `Boop/Features/Chat/Views/ChatInboxView.swift` (composer area in `ChatConversationView`)

- [ ] **Step 1: Add the nudge chip row above the composer**

Above the existing composer in `ChatConversationView`, insert a chip row shown only while below reveal. Add this view builder to `ChatConversationView`:

```swift
    @ViewBuilder
    private var fogNudgeChips: some View {
        if let comfort = viewModel.comfortScore,
           comfort < 70,
           conversation.matchStage != "revealed",
           conversation.matchStage != "dating" {
            HStack(spacing: BoopSpacing.xs) {
                nudgeChip(icon: "mic.fill", label: "Voice note") {
                    isVoiceSheetPresented = true
                }
                nudgeChip(icon: "gamecontroller.fill", label: "Play a game") {
                    showGames = true
                }
            }
            .padding(.horizontal, BoopSpacing.md)
            .padding(.top, BoopSpacing.xs)
        }
    }

    private func nudgeChip(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.light(); action() }) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10, weight: .bold))
                Text(label).font(.nunito(.bold, size: 11))
            }
            .foregroundStyle(BoopColors.brandViolet)
            .padding(.horizontal, BoopSpacing.sm)
            .padding(.vertical, 6)
            .background(BoopColors.backgroundMint)
            .clipShape(Capsule())
        }
    }
```

Note: the "Play a game" target should open the existing game entry. If `ChatConversationView` already has a games entry point or the match-detail games view is reachable, route there; otherwise open `MatchDetailView` via the `showComfortDetail` sheet. Pick whichever path already exists in the file and reuse it — do not invent a new route. (Games surfacing is hardened in Task 9.)

Insert `fogNudgeChips` immediately before the `composer` in the body's `VStack`. Add `@State private var showGames = false` to `ChatConversationView`, and present the existing games surface (refined in Task 9):

```swift
        .sheet(isPresented: $showGames) {
            if let matchId = conversation.matchId {
                NavigationStack { MatchDetailView(matchId: matchId) }
            }
        }
```

- [ ] **Step 2: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Visual check**

Below 70, two chips ("Voice note", "Play a game") sit above the composer; at/after reveal they disappear. Voice chip opens the existing voice recorder sheet.

- [ ] **Step 4: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add Boop/Features/Chat/Views/ChatInboxView.swift
git commit -m "feat(chat): fog nudge chips toward the reveal"
```

---

## Task 7: The Clearing — reveal celebration

**Files:**
- Create: `Boop/Features/Matches/Views/TheClearingView.swift`
- Modify: `Boop/Features/Matches/Views/MatchDetailView.swift` (present on reveal completion)

- [ ] **Step 1: Create the full-screen reveal moment**

```swift
// Boop/Features/Matches/Views/TheClearingView.swift
import SwiftUI

/// The reveal payoff: the fog dissolves and the other person's portrait
/// resolves to full clarity, with a recap of the journey that earned it.
struct TheClearingView: View {
    let name: String
    let photoURL: String?
    let days: Int
    let games: Int
    let voiceNotes: Int
    let onDone: () -> Void

    @State private var blur: CGFloat = 28
    @State private var showText = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            BoopRemoteImage(urlString: photoURL) {
                BoopColors.brandGradient
            }
            .blur(radius: blur)
            .ignoresSafeArea()

            LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: BoopSpacing.md) {
                Spacer()
                if showText {
                    Text("THE FOG HAS LIFTED")
                        .font(.nunito(.bold, size: 12))
                        .foregroundStyle(Color(hex: "FFD6DD"))
                        .transition(.opacity)
                    Text(name)
                        .font(.nunito(.extraBold, size: 34))
                        .foregroundStyle(.white)
                        .transition(.opacity)
                    HStack(spacing: BoopSpacing.xs) {
                        recapChip("🔥 \(days) days")
                        recapChip("🎮 \(games) games")
                        recapChip("🎙 \(voiceNotes) voice")
                    }
                    .transition(.opacity)
                    BoopButton(title: "Say something 💕") { onDone() }
                        .padding(.horizontal, BoopSpacing.xl)
                        .padding(.top, BoopSpacing.sm)
                        .transition(.opacity)
                }
                Spacer().frame(height: BoopSpacing.xl)
            }
            .padding(.bottom, BoopSpacing.xl)
        }
        .onAppear {
            Haptics.celebration()
            withAnimation(.easeInOut(duration: 1.4)) { blur = 0 }
            withAnimation(.easeIn(duration: 0.6).delay(1.0)) { showText = true }
        }
    }

    private func recapChip(_ text: String) -> some View {
        Text(text)
            .font(.nunito(.bold, size: 11))
            .foregroundStyle(.white)
            .padding(.horizontal, BoopSpacing.sm)
            .padding(.vertical, 6)
            .background(.white.opacity(0.18))
            .clipShape(Capsule())
    }
}
```

- [ ] **Step 2: Present it from Match Detail when reveal completes**

In `MatchDetailView`, add state and a fullScreenCover. After `viewModel.requestReveal()` returns and `viewModel.detail?.stage == "revealed"`, trigger it. Add:

```swift
    @State private var showClearing = false
```

Wrap the existing reveal button action so that after the async call it checks the stage:

```swift
                Button {
                    Task {
                        await viewModel.requestReveal()
                        if viewModel.detail?.stage == "revealed" {
                            showClearing = true
                        }
                    }
                } label: { /* existing reveal button label */ }
```

(Find the existing reveal button — currently calling `await viewModel.requestReveal()` at MatchDetailView.swift:407 — and add the post-call stage check + `showClearing = true`.)

Add the cover near the other view modifiers:

```swift
        .fullScreenCover(isPresented: $showClearing) {
            TheClearingView(
                name: viewModel.detail?.otherUser?.firstName ?? "Your match",
                photoURL: viewModel.detail?.otherUser?.photos?.profilePhotoUrl,
                days: viewModel.detail?.streak?.longest ?? viewModel.detail?.streak?.current ?? 0,
                games: gamesCountForRecap,
                voiceNotes: voiceCountForRecap,
                onDone: {
                    showClearing = false
                    if let matchId = viewModel.detail?.matchId {
                        NotificationRouter.shared.openChat(matchId: matchId)
                    }
                }
            )
        }
```

For the recap counts, derive from the comfort breakdown if loaded, else 0 (honest, no fabrication). Add:

```swift
    private var gamesCountForRecap: Int {
        let detail = viewModel.comfort?.breakdown["gamesCompleted"]?.detail ?? ""
        return Int(detail.prefix(while: \.isNumber)) ?? 0
    }
    private var voiceCountForRecap: Int {
        let detail = viewModel.comfort?.breakdown["voiceEngagement"]?.detail ?? ""
        return Int(detail.prefix(while: \.isNumber)) ?? 0
    }
```

(The breakdown `detail` strings start with the count, e.g. "4 games completed (target: 3)" — parsing the leading number is best-effort; if it yields 0 the chip still renders gracefully.)

- [ ] **Step 3: Build**

Run `xcodegen generate` then the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Visual check**

On a match at comfort ≥ 70 with both reveal requests, completing the reveal plays the full-screen Clearing: portrait sharpens from fog to clear, "THE FOG HAS LIFTED" → name → recap chips → "Say something" returns to the now-clear chat.

- [ ] **Step 5: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add project.yml Boop.xcodeproj/project.pbxproj Boop/Features/Matches/Views/TheClearingView.swift Boop/Features/Matches/Views/MatchDetailView.swift
git commit -m "feat(reveal): The Clearing celebration moment"
```

---

## Task 8: Stalled-match recovery — "gone quiet" card

**Files:**
- Create: `Boop/Features/Matches/Views/GoneQuietCard.swift`
- Modify: `Boop/Features/Matches/Views/MatchDetailView.swift` (show card when stalled; wire Boop + archive)

A match is "stalled" when active, below reveal, and inactive — detect client-side from `streak`/recency. Reuse the existing `viewModel.sendBoop()` and `viewModel.archive()` (both exist on `MatchDetailViewModel`). Archiving already frees a Discover slot server-side (the candidate becomes available again is not guaranteed, but the slot/quota is — copy says "made room for someone new").

- [ ] **Step 1: Create the card**

```swift
// Boop/Features/Matches/Views/GoneQuietCard.swift
import SwiftUI

/// Surfaced when a connection has gone quiet: revive with a Boop, or let it go.
struct GoneQuietCard: View {
    let name: String
    let onBoop: () -> Void
    let onLetGo: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: BoopSpacing.sm) {
            Text("This one's gone quiet")
                .font(.nunito(.bold, size: 16))
                .foregroundStyle(BoopColors.textPrimary)
            Text("\(name) hasn't been around lately. Send a Boop to revive it, or gracefully let it go and make room for someone new.")
                .font(.nunito(.regular, size: 13))
                .foregroundStyle(BoopColors.textSecondary)
            HStack(spacing: BoopSpacing.sm) {
                BoopButton(title: "👋 Boop", variant: .outline, fullWidth: true) { onBoop() }
                BoopButton(title: "Let it go", variant: .ghost, fullWidth: true) { onLetGo() }
            }
        }
        .padding(BoopSpacing.lg)
        .boopCard(radius: BoopRadius.xxl)
        .padding(.horizontal, BoopSpacing.xl)
    }
}
```

- [ ] **Step 2: Detect stalled + show the card in Match Detail**

In `MatchDetailView`, add a computed flag and confirmation state:

```swift
    @State private var showLetGoConfirm = false

    private var isStalled: Bool {
        guard let d = viewModel.detail else { return false }
        let active = d.stage != "revealed" && d.stage != "dating" && d.stage != "archived"
        let coldStreak = (d.streak?.current ?? 0) == 0
        let lowComfort = (d.comfortScore ?? 0) < 70
        return active && coldStreak && lowComfort
    }
```

Insert near the top of the detail content (e.g. just under the hero, before the score sections):

```swift
                if isStalled {
                    GoneQuietCard(
                        name: viewModel.detail?.otherUser?.firstName ?? "This match",
                        onBoop: { Task { await viewModel.sendBoop() } },
                        onLetGo: { showLetGoConfirm = true }
                    )
                }
```

Add the confirmation + post-archive navigation:

```swift
        .confirmationDialog("Let this connection go?", isPresented: $showLetGoConfirm, titleVisibility: .visible) {
            Button("Let it go", role: .destructive) {
                Task {
                    await viewModel.archive()
                    NotificationCenter.default.post(name: .init("boop.blockedUser"), object: nil) // reuses the home/inbox refresh signal
                    dismiss()
                }
            }
        } message: {
            Text("This archives the conversation and frees a spot in Discover for someone new.")
        }
```

(`dismiss` — add `@Environment(\.dismiss) private var dismiss` if `MatchDetailView` doesn't already have it from the trust-safety work; it does.)

- [ ] **Step 3: Build**

Run `xcodegen generate` then the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Visual check**

A stalled match (cold streak, comfort < 70) shows the "gone quiet" card with Boop / Let it go; letting go archives and pops back, and Home/inbox refresh (the existing `boop.blockedUser` listener triggers a reload).

- [ ] **Step 5: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add project.yml Boop.xcodeproj/project.pbxproj Boop/Features/Matches/Views/GoneQuietCard.swift Boop/Features/Matches/Views/MatchDetailView.swift
git commit -m "feat(matches): gone-quiet recovery — revive or release"
```

---

## Task 9: Games surfacing — confirm the in-chat entry

**Files:**
- Modify: `Boop/Features/Chat/Views/ChatInboxView.swift` (wire the Task 6 "Play a game" chip to the real game flow)

- [ ] **Step 1: Find the existing game entry and wire the chip to it**

Search the codebase for how games are launched today:
```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend" && grep -rn "MatchGamesView\|createGame\|GameSession\|getGamesForMatch" Boop --include="*.swift" | head
```
Identify the view/route that starts a game for a match (e.g. `MatchGamesView` reachable from `MatchDetailView`, or a `createGame` call). Task 6 already wired the "Play a game" chip to `showGames` presenting `MatchDetailView` in a sheet. If this search reveals a **more direct** games view (e.g. a dedicated `MatchGamesView(matchId:)`), upgrade the Task 6 sheet to present that view instead, so the chip lands the user directly on games rather than on the full match-detail screen:

```swift
        .sheet(isPresented: $showGames) {
            if let matchId = conversation.matchId {
                NavigationStack { MatchGamesView(matchId: matchId) } // use the real view name found in step 1
            }
        }
```

If no dedicated games view exists separate from Match Detail, leave Task 6's wiring as-is (reaching games via Match Detail is acceptable for v1) and this task is a no-op confirmation. Do not create a new game-session flow.

- [ ] **Step 2: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Visual check**

The chat "Play a game" chip opens the real games surface for that match (not a dead end).

- [ ] **Step 4: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add Boop/Features/Chat/Views/ChatInboxView.swift
git commit -m "feat(games): wire in-chat game entry to the existing flow"
```

---

## Task 10: Theme toggle on Profile + full-sweep polish & verification

**Files:**
- Modify: `Boop/Features/Profile/Views/ProfileView.swift` (theme picker)
- Modify: `Boop/Core/Extensions/View+Boop.swift` (`BoopAmbientBackground` to Electric Heart)

- [ ] **Step 1: Retune the ambient background to Electric Heart**

In `Boop/Core/Extensions/View+Boop.swift`, update `BoopAmbientBackground` so the base gradient and orbs use the brand palette and adapt to dark mode. Replace the `sunriseGradient` base and the three orb fills:

```swift
struct BoopAmbientBackground: View {
    var body: some View {
        ZStack {
            BoopColors.background.ignoresSafeArea()

            Circle()
                .fill(BoopColors.brand.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 40)
                .offset(x: -120, y: -260)

            Circle()
                .fill(BoopColors.brandViolet.opacity(0.16))
                .frame(width: 240, height: 240)
                .blur(radius: 36)
                .offset(x: 140, y: -160)

            Circle()
                .fill(BoopColors.accent.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 38)
                .offset(x: 110, y: 320)
        }
    }
}
```

- [ ] **Step 2: Add the theme picker to Profile**

In `ProfileView`, add `@AppStorage("appTheme") private var appTheme = AppTheme.system.rawValue` and, near the Log Out / Delete Account buttons, a segmented picker:

```swift
            VStack(alignment: .leading, spacing: BoopSpacing.xs) {
                Text("Appearance")
                    .font(.nunito(.bold, size: 13))
                    .foregroundStyle(BoopColors.textSecondary)
                Picker("Appearance", selection: $appTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(theme.label).tag(theme.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, BoopSpacing.md)
```

(Because `BoopApp` reads the same `@AppStorage("appTheme")`, changing it here updates the whole app live.)

- [ ] **Step 3: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 4: Full-sweep visual verification (light + dark)**

Walk every primary surface in the simulator in **both** appearances and confirm Electric Heart styling + legibility, no regressions:
- Onboarding (intro, phone, OTP, the 6 steps)
- Home (Moment-Led Feed)
- Discover (candidate cards, Connect button = brand gradient)
- Chat inbox + conversation (The Fog) + nudge chips
- Match Detail (scores, gone-quiet card, reveal → The Clearing)
- Profile (theme picker flips appearance live; block/report/delete entries styled)
- Notifications, Badges, Personality report

Note any screen that looks broken and fix inline (token references only — no structural changes).

- [ ] **Step 5: Bump build number for TestFlight**

In `project.yml`, increment `CURRENT_PROJECT_VERSION` and `CFBundleVersion` from "11" to "12" (both places).

- [ ] **Step 6: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
xcodegen generate
git add project.yml Boop.xcodeproj/project.pbxproj Boop/Features/Profile/Views/ProfileView.swift Boop/Core/Extensions/View+Boop.swift
git commit -m "feat(design): Electric Heart ambient + appearance toggle; build 12"
```

---

## Out of scope (deferred per spec §9)

- Shareable "we met" card after The Clearing.
- Surfacing matches' answers to the daily question ("unlock theirs") — needs a backend endpoint.
- A dedicated in-chat game-session sheet (Task 9 reaches games via the existing surface).
- Full accessibility pass (Dynamic Type, VoiceOver) beyond what exists + dark mode.
- The reveal also auto-playing for the *other* user via push deep-link (v1 plays for the user who completes the reveal; the other sees the existing `photos_revealed` push and the cleared chat).

## Post-implementation

After Task 10, ship build 12 to TestFlight using the proven recipe (ASC key `A4MNMMCCVB`, issuer `0bbf6f7f-a7cf-4b88-8759-4c85e5c0f240`, manual signing) saved in memory `unmutee-testflight-upload-recipe`.
