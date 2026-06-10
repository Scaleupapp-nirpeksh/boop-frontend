# Cinematic Dark UI Sweep — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign every screen of the UnMutee iOS app into the "Cinematic Dark" language (dark-first, photography-led, editorial, hairline structure, single flat-coral accent, no emoji), implementing `docs/superpowers/specs/2026-06-10-cinematic-dark-ui-sweep.md`.

**Architecture:** A dark-first re-skin of the existing semantic token layer + a cinematic type ramp + a small set of reusable cinematic components carry the language; every screen is then redesigned to apply those primitives. Purely visual — no behavior, data, navigation, or endpoint changes.

**Tech Stack:** SwiftUI (iOS 17, `@Observable`), xcodegen (`project.yml` source of truth; `Boop.xcodeproj/project.pbxproj` is generated AND git-tracked — run `xcodegen generate` when files are added and `git add` the pbxproj), system font for cinematic type, existing `BlurredPortrait`/`FogBlur`.

**Method for screen tasks (read this):** Phase 1 (tokens + type + components) is given as **exact code** because everything depends on it. Phases 2–4 are **redesign briefs**, not verbatim screen code: each names the exact components/tokens to use, the concrete structural changes (before→after of key elements), and acceptance criteria. The implementer **reads the current screen file, preserves ALL behavior/state/navigation/data wiring (much of it from trust-&-safety, comfort, reveal, games work), and re-expresses the layout** in the cinematic language. Do not change logic, view models, API calls, or navigation. This is the correct approach for a 30-screen visual sweep; vague briefs are still failures — each brief is specific.

**Verification model:** No XCUITest/unit target exists. Gate = `xcodebuild ... build` → `BUILD SUCCEEDED` + the visual checks named per task (run in simulator, **toggle dark AND light**). Build command:
```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend" && xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -6
```
Run `xcodegen generate` first whenever files are added.

**Hard rules for every task:**
- **No emoji in any UI chrome.** Use thin SF Symbols (`.font(.system(size:weight:.thin))`) or text. (Emoji inside user-generated content/reactions stays.)
- **Preserve behavior exactly.** Same `@State`, view models, `.task`, `.onReceive`, sheets, navigation, API calls. If unsure whether something is decoration vs. behavior, keep it.
- **Use tokens/components, not literals.** Colors via `BoopColors`, type via the cinematic ramp / `EyebrowLabel` etc. Only the design-system files define raw hex.

**Phases:** 1 Foundation (Tasks 1–3) · 2 Re-skin shipped screens (4–6) · 3 Hero screens (7–10) · 4 Everything else (11–16).

---

## Task 1: Dark-first token re-skin

**Files:**
- Modify: `Boop/DesignSystem/Theme/BoopColors.swift`
- Modify: `Boop/DesignSystem/Theme/BoopSpacing.swift` (add `sharp` radius)
- Modify: `Boop/App/BoopApp.swift` (default appearance → dark)

- [ ] **Step 1: Re-skin `BoopColors` dark-first**

Replace the **Brand**, **Backgrounds**, **Text**, **Borders**, and **Gradients** sections with the Cinematic Dark values. Keep every other symbol defined (dark-card constants, tinted surfaces, semantic, `dimensionColor`) so un-migrated call sites compile.

```swift
    // MARK: - Accent (Cinematic Dark — single flat coral / vermilion)
    static let accentColor = Color.dynamic(light: Color(hex: "C0392B"), dark: Color(hex: "FF4D6D"))
    static let brand = accentColor          // repoint legacy
    static let primary = accentColor        // repoint legacy
    static let secondary = accentColor      // repoint legacy (was violet) — one accent now
    static let accent = accentColor         // repoint legacy ember
    static let brandViolet = accentColor    // retired; kept defined, points to accent

    // MARK: - Ground & surfaces (dark-first)
    static let ground = Color.dynamic(light: Color(hex: "F7F3EC"), dark: Color(hex: "0C0810"))
    static let background = ground           // repoint legacy
    static let backgroundBlush = Color.dynamic(light: Color(hex: "EFE9DD"), dark: Color(hex: "14101B"))
    static let backgroundMint = Color.dynamic(light: Color(hex: "EFE9DD"), dark: Color(hex: "14101B"))
    static let surface = Color.dynamic(light: .white, dark: Color(hex: "14101B"))
    static let surfaceSecondary = Color.dynamic(light: Color(hex: "F0EADE"), dark: Color(hex: "1A141F"))
    static let surfaceElevated = Color.dynamic(light: .white, dark: Color(hex: "1A141F"))

    // MARK: - Text
    static let textPrimary = Color.dynamic(light: Color(hex: "1B1B18"), dark: Color(hex: "F4ECF2"))
    static let textSecondary = Color.dynamic(light: Color(hex: "6B6358"), dark: Color.white.opacity(0.62))
    static let textMuted = Color.dynamic(light: Color(hex: "A8A095"), dark: Color.white.opacity(0.40))
    static let textOnPrimary = Color.white
```

Replace borders + gradients:

```swift
    // MARK: - Hairlines / borders
    static let hairline = Color.dynamic(light: Color(hex: "E2DBCF"), dark: Color.white.opacity(0.11))
    static let border = hairline             // repoint legacy
    static let borderFocus = accentColor

    // MARK: - Gradients (retired — flattened to the accent so legacy call sites render flat coral)
    static let brandGradient = LinearGradient(colors: [accentColor, accentColor], startPoint: .leading, endPoint: .trailing)
    static let primaryGradient = brandGradient
    static let secondaryGradient = brandGradient
```

Leave `warmGradient`, `sunriseGradient`, `coralPinkGradient`, `sunsetGradient`, `tealMintGradient`, `highlightGradient` defined (un-migrated surfaces) but they will be removed as screens migrate; if trivial, point them at `brandGradient` too. Keep `chatBackground`/`chatBubbleReceived`:

```swift
    static let chatBackground = ground
    static let chatBubbleReceived = surface
```

Keep `error`/`success`/`warning` but retune for near-black + cream legibility:
```swift
    static let error = Color.dynamic(light: Color(hex: "C0392B"), dark: Color(hex: "FF6B6B"))
    static let success = Color.dynamic(light: Color(hex: "2E7D5B"), dark: Color(hex: "5BD6A0"))
    static let warning = Color.dynamic(light: Color(hex: "B7791F"), dark: Color(hex: "F0B84E"))
```

- [ ] **Step 2: Add the sharp radius**

In `Boop/DesignSystem/Theme/BoopSpacing.swift`, add to `enum BoopRadius`:
```swift
    static let sharp: CGFloat = 2
```

- [ ] **Step 3: Default appearance → dark**

In `Boop/App/BoopApp.swift`, change the AppStorage default:
```swift
    @AppStorage("appTheme") private var appTheme = AppTheme.dark.rawValue
```
(Leave the `.preferredColorScheme(AppTheme(rawValue: appTheme)?.colorScheme)` line as-is.)

- [ ] **Step 4: Build**

Run the build command. Expected `BUILD SUCCEEDED`. Fix any symbol you over-removed (do not touch call sites).

- [ ] **Step 5: Visual check**

Launch: the whole app is now near-black by default; any remaining gradient buttons render as flat coral; text is legible. (Screens still have old layout — that's later tasks.)

- [ ] **Step 6: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add Boop/DesignSystem/Theme/BoopColors.swift Boop/DesignSystem/Theme/BoopSpacing.swift Boop/App/BoopApp.swift
git commit -m "feat(cinematic): dark-first token re-skin, flat coral accent, sharp radius"
```

---

## Task 2: Cinematic type ramp

**Files:**
- Modify: `Boop/DesignSystem/Theme/BoopTypography.swift`

- [ ] **Step 1: Add the cinematic (system-font) ramp**

Append to `enum BoopTypography` (keep the existing Nunito tokens for un-migrated surfaces):

```swift
    // MARK: - Cinematic ramp (system font, light weights)
    static let cineDisplayXL = Font.system(size: 42, weight: .thin)
    static let cineDisplay = Font.system(size: 32, weight: .light)
    static let cineTitle = Font.system(size: 25, weight: .light)
    static let cineHeadline = Font.system(size: 19, weight: .light)
    static let cineLabel = Font.system(size: 11, weight: .semibold)   // use UPPERCASE + .tracking(2) at the call site / via EyebrowLabel
    static let cineBody = Font.system(size: 15, weight: .regular)
    static let cineBodyLight = Font.system(size: 15, weight: .light)
    static let cineCaption = Font.system(size: 11, weight: .regular)
```

- [ ] **Step 2: Build**

Run the build command. Expected `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add Boop/DesignSystem/Theme/BoopTypography.swift
git commit -m "feat(cinematic): system-font cinematic type ramp"
```

---

## Task 3: Reusable cinematic components + restyle base controls

**Files:**
- Create: `Boop/DesignSystem/Components/CinematicComponents.swift`
- Modify: `Boop/DesignSystem/Components/BoopButton.swift`
- Modify: `Boop/Core/Extensions/View+Boop.swift` (boopCard → hairline panel; ambient → cinematic)

- [ ] **Step 1: Create the cinematic components**

```swift
// Boop/DesignSystem/Components/CinematicComponents.swift
import SwiftUI

/// Uppercase, letter-spaced low-opacity label — the editorial signature.
struct EyebrowLabel: View {
    let text: String
    var color: Color = BoopColors.textMuted
    var body: some View {
        Text(text.uppercased())
            .font(BoopTypography.cineLabel)
            .tracking(2)
            .foregroundStyle(color)
    }
}

/// The 24×2 coral rule used as a section marker.
struct AccentRule: View {
    var width: CGFloat = 24
    var body: some View {
        Rectangle().fill(BoopColors.accentColor).frame(width: width, height: 2)
    }
}

/// A hairline-topped list row: leading title, optional trailing value, optional chevron.
struct HairlineRow<Trailing: View>: View {
    let title: String
    var titleColor: Color = BoopColors.textPrimary
    var showChevron: Bool = false
    @ViewBuilder var trailing: () -> Trailing

    init(_ title: String, titleColor: Color = BoopColors.textPrimary, showChevron: Bool = false,
         @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }) {
        self.title = title; self.titleColor = titleColor; self.showChevron = showChevron; self.trailing = trailing
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(BoopColors.hairline).frame(height: 1)
            HStack(spacing: BoopSpacing.sm) {
                Text(title).font(BoopTypography.cineBody).foregroundStyle(titleColor)
                Spacer()
                trailing()
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .thin))
                        .foregroundStyle(BoopColors.textMuted)
                }
            }
            .padding(.vertical, BoopSpacing.md)
        }
    }
}

/// A 1px progress track with a coral filled portion (0...1).
struct HairlineProgress: View {
    let progress: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(BoopColors.hairline)
                Rectangle().fill(BoopColors.accentColor)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: 1)
    }
}

/// Refined voice control: a thin-stroked play circle + a 1px progress line.
struct VoiceLine: View {
    var duration: String
    var isPlaying: Bool = false
    var onTap: () -> Void = {}
    var body: some View {
        HStack(spacing: BoopSpacing.sm) {
            Button(action: onTap) {
                Image(systemName: isPlaying ? "pause" : "play.fill")
                    .font(.system(size: 12, weight: .thin))
                    .foregroundStyle(BoopColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(BoopColors.textPrimary.opacity(0.5), lineWidth: 1))
            }
            Rectangle().fill(BoopColors.hairline).frame(height: 1).frame(maxWidth: .infinity)
            Text(duration).font(BoopTypography.cineCaption).foregroundStyle(BoopColors.textMuted)
        }
    }
}

/// Full-bleed blurred portrait fading into the ground, with overlaid title block.
/// Uses the existing BlurredPortrait. Caller supplies the overlay content (eyebrow, name, etc.).
struct CinematicHeader<Overlay: View>: View {
    let urlString: String?
    var blurRadius: CGFloat
    var height: CGFloat = 280
    @ViewBuilder var overlay: () -> Overlay

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            BlurredPortrait(urlString: urlString, blurRadius: blurRadius, shape: .roundedRect(0), scrim: false)
                .frame(height: height)
                .clipped()
            LinearGradient(colors: [.clear, BoopColors.ground.opacity(0.6), BoopColors.ground],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: height)
            VStack(alignment: .leading, spacing: BoopSpacing.xs) { overlay() }
                .padding(BoopSpacing.lg)
        }
        .frame(height: height)
    }
}
```

- [ ] **Step 2: Restyle `BoopButton` to cinematic (keep its API)**

In `BoopButton.swift`, keep the `BoopButton(title:variant:isLoading:isDisabled:fullWidth:action:)` signature. Change: corner radius `BoopRadius.xl` → `BoopRadius.sharp`; `.primary` background from `BoopColors.primaryGradient` to a flat `BoopColors.accentColor` fill; `.secondary` → hairline-outlined (clear fill, `BoopColors.hairline` stroke, `textPrimary` label); `.outline` keeps stroke but use `BoopColors.hairline`/`accentColor`; `.ghost` → tracked text (`textSecondary`). Drop the colored drop-shadow (or make it `accentColor.opacity(0.25)` only for `.primary`). Keep haptics. Title font may move to `Font.system(size: 15, weight: .semibold)` for the tracked-button feel.

- [ ] **Step 3: Restyle `boopCard` + ambient (View+Boop.swift)**

`boopCard` modifier: replace the filled rounded card + white stroke with a **hairline panel** — `BoopColors.surface` fill at `BoopRadius.sharp` (or keep `lg` for large panels) with a 1px `BoopColors.hairline` stroke, no heavy shadow. `BoopAmbientBackground`: replace orbs with a quiet near-black (`BoopColors.ground`) base and at most one very subtle accent glow at low opacity; in light it's cream. The app's busy screens largely use full-bleed photography, so the ambient should be calm.

- [ ] **Step 4: Build + preview**

Run `xcodegen generate` then the build command. Expected `BUILD SUCCEEDED`. Add a temporary `#Preview` to `CinematicComponents.swift` rendering each component on `BoopColors.ground`; confirm in canvas they read in dark and light. Keep a minimal preview or remove before commit.

- [ ] **Step 5: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add project.yml Boop.xcodeproj/project.pbxproj Boop/DesignSystem/Components/CinematicComponents.swift Boop/DesignSystem/Components/BoopButton.swift Boop/Core/Extensions/View+Boop.swift
git commit -m "feat(cinematic): shared components + cinematic BoopButton/boopCard/ambient"
```

---

## Task 4: Re-skin Home (Moment-Led Feed)

**Files:** Modify `Boop/Features/Home/Views/HomeView.swift`, `MomentHeroCard.swift`, `YourPeopleRow.swift`, `DailyQuestionBand.swift`, `ConnectionCard.swift`.

**Brief:** Preserve all behavior (`.task`, `.onReceive`, celebration overlay, sheet, navigation). Re-express:
- **greetingHeader:** "good evening" → `EyebrowLabel`; name → `BoopTypography.cineDisplay`; streak as a tracked caption ("🔥" removed → a thin `flame` SF Symbol `.thin` + number, or just "STREAK 4" tracked); bell as thin `bell` SF Symbol, unread as a small coral dot (not a candy pill).
- **MomentHeroCard:** rebuild on `CinematicHeader` — blurred portrait fading to ground, `EyebrowLabel` (e.g. "8 POINTS FROM FOCUS"), name in `cineDisplay`, `AccentRule` above it; drop the brand drop-shadow card look.
- **YourPeopleRow:** "YOUR PEOPLE" via `EyebrowLabel`; portraits keep `BlurredPortrait` but captions become `cineCaption`/`textMuted`; selected/near-reveal ring → a thin coral underline or 1px coral stroke, not a 2px candy border.
- **DailyQuestionBand:** replace the flat coral gradient slab with a hairline-bounded block: `EyebrowLabel` "TODAY'S QUESTIONS", `cineHeadline` prompt, `AccentRule`, a tracked "OPEN" with a thin chevron. Tap still sets `showQuestionsSheet`.
- **activitySection / ConnectionCard / emptyDiscoverPrompt:** convert tiles to hairline rows / `CinematicHeader`-lite; `BoopButton` already cinematic.

**Acceptance:** near-black feed; no gradients/pills/emoji; hero portrait fades to ground; hairline structure; behavior unchanged.

- [ ] Build (`BUILD SUCCEEDED`), visual-check Home in dark+light, then commit:
```bash
git add Boop/Features/Home/Views/HomeView.swift Boop/Features/Home/Views/MomentHeroCard.swift Boop/Features/Home/Views/YourPeopleRow.swift Boop/Features/Home/Views/DailyQuestionBand.swift Boop/Features/Home/Views/ConnectionCard.swift
git commit -m "feat(cinematic): re-skin Home"
```

---

## Task 5: Re-skin Chat (The Fog)

**Files:** Modify `Boop/Features/Chat/Views/ChatInboxView.swift` (inbox rows + `ChatConversationView` + `ChatMessageBubble`), `ConversationStartersCard.swift`.

**Brief:** Preserve all behavior (fog background, comfort load, nudge chips, report/block, voice/image, onReceive, pagination). Re-express:
- **Inbox:** `BoopSectionIntro`/header → `EyebrowLabel` + `cineDisplay`; conversation rows → hairline rows (avatar = small `BlurredPortrait` circle, name `cineBody`, last message `cineCaption`/`textMuted`, unread = coral dot + tracked count); filter segmented control restyled minimal.
- **Conversation:** fog stays; align scrim to `BoopColors.ground`; **sent bubble** = flat `accentColor`, `BoopRadius.sharp` corners, white text; **received bubble** = `BoopColors.surface`, sharp; the "fog is lifting · N/70" pill → an `EyebrowLabel`-style tracked text with a thin coral rule (no capsule); **nudge chips** → hairline-outlined sharp chips with thin SF Symbols (mic/`gamecontroller` `.thin`), not mint capsules; composer on `surface`, sharp, thin-symbol buttons.
- **ConversationStartersCard:** hairline panel, `cineBody` suggestions.

**Acceptance:** cohesive near-black chat; bubbles sharp; no mint/pills/emoji chrome; legible over fog (keep scrim opacity tuning); all behavior intact.

- [ ] Build, visual-check (dark+light, a real conversation incl. below-70 chips), commit:
```bash
git add Boop/Features/Chat/Views/ChatInboxView.swift Boop/Features/Chat/Views/ConversationStartersCard.swift
git commit -m "feat(cinematic): re-skin Chat (inbox, fog conversation, bubbles, chips)"
```

---

## Task 6: Re-skin Match detail, The Clearing, GoneQuiet, MatchCelebration

**Files:** Modify `Boop/Features/Matches/Views/MatchDetailView.swift`, `TheClearingView.swift`, `GoneQuietCard.swift`, `Boop/Features/Home/Views/MatchCelebrationView.swift`.

**Brief:** Preserve all behavior (reveal flow + The Clearing trigger, comfort/readiness, boop, archive, gone-quiet, report/block menu, scores). Re-express:
- **MatchDetailView:** hero → `CinematicHeader`; scores (match %, comfort, readiness) → typeset numerals in a row split by hairlines (retire dark-card tiles + `warmGradient` bar); comfort/readiness bars → `HairlineProgress`; stage timeline → tracked labels + coral rule; section headers → `EyebrowLabel`; all CTAs already cinematic via `BoopButton`.
- **TheClearingView:** retune to ramp — "THE FOG HAS LIFTED" via `EyebrowLabel`, name `cineDisplayXL`, recap chips → hairline/tracked items (no candy capsules, no emoji — use thin SF Symbols or plain tracked text like "9 DAYS · 4 GAMES · 23 VOICE"), single coral accent.
- **GoneQuietCard:** hairline panel, `cineHeadline` title, `cineBody` copy, cinematic buttons.
- **MatchCelebrationView:** align to The Clearing's look.

**Acceptance:** match surfaces cohesive; scores typeset not tiled; reveal moment still cinematic; behavior intact.

- [ ] Build, visual-check, commit:
```bash
git add Boop/Features/Matches/Views/MatchDetailView.swift Boop/Features/Matches/Views/TheClearingView.swift Boop/Features/Matches/Views/GoneQuietCard.swift Boop/Features/Home/Views/MatchCelebrationView.swift
git commit -m "feat(cinematic): re-skin match detail, reveal, gone-quiet, celebration"
```

---

## Task 7: Redesign Discover (hero)

**Files:** Modify `Boop/Features/Discover/Views/DiscoverView.swift`, `Boop/Features/Home/Views/CandidateCardView.swift`, `Boop/Features/Discover/Views/ConnectNoteSheet.swift`.

**Brief (the approved Cinematic direction):** Preserve behavior (candidate queue, like/pass, daily limit, connect-note, voice playback). Re-express the candidate card as full-screen Cinematic Dark: full-bleed `BlurredPortrait` fading to ground; top row = `EyebrowLabel` "DISCOVER" + tracked "NN today"; `EyebrowLabel` "NN COMPATIBLE" + thin `AccentRule`; name in `cineDisplay` (light weight); subtitle `cineCaption` ("27 · Bengaluru · aligned on life vision"); `VoiceLine` for the voice intro; "why you fit" as hairline-outlined sharp chips (text only, thin); actions = Pass (hairline-outlined, sharp) / Connect (flat coral bar, sharp). `ConnectNoteSheet` matches (hairline input, cinematic button).

**Acceptance:** matches the approved Discover mockup; no ring badge, no candy; voice + compatibility legible; like/pass/connect-note work.

- [ ] Build, visual-check, commit:
```bash
git add Boop/Features/Discover/Views/DiscoverView.swift Boop/Features/Home/Views/CandidateCardView.swift Boop/Features/Discover/Views/ConnectNoteSheet.swift
git commit -m "feat(cinematic): redesign Discover"
```

---

## Task 8: Redesign Games (hero)

**Files:** Modify `Boop/Features/Games/Views/GameViews.swift` (`MatchGamesView`, `GameSessionView`), `GameHistoryView.swift`.

**Brief:** Preserve behavior (create/ready/respond/cancel, 5-round sync, cooldowns, history). Re-express:
- **MatchGamesView (lobby):** `EyebrowLabel`/`cineDisplay` title; the live invite → a single hairline-bounded feature block with a coral rule + tracked payoff ("+8 COMFORT"), cinematic Join button (no gradient slab); **all games as hairline rows** — game name `cineBody`, vibe + time as tracked `cineCaption` metadata, thin chevron — **no colourful tiles, no emoji**.
- **GameSessionView (live round):** near-black; the 3-2-1 countdown as large `cineDisplayXL` numerals; prompts in `cineTitle`; answer options as hairline rows / cinematic; simultaneous-reveal moment restyled; round progress via `HairlineProgress`.
- **GameHistoryView:** hairline list.

**Acceptance:** lobby is a quiet list not a candy grid; live round cinematic; all game mechanics intact.

- [ ] Build, visual-check (start a game), commit:
```bash
git add Boop/Features/Games/Views/GameViews.swift Boop/Features/Games/Views/GameHistoryView.swift
git commit -m "feat(cinematic): redesign Games (lobby + live round + history)"
```

---

## Task 9: Redesign Questions (hero)

**Files:** Modify `Boop/Features/Onboarding/Views/QuestionsView.swift`, `Boop/Features/Home/Views/QuestionsFullView.swift`, `Boop/Features/Questions/Views/QuestionsProgressView.swift`.

**Brief (the approved direction):** Preserve behavior (answer submit, voice answer, day-drip, progress to 15, stage advance, the "already ready" handling). Re-express each question screen: near-black; top = `EyebrowLabel` "QUESTION NN" + tracked "NN / 15" with a `HairlineProgress` below; centered question in `cineTitle` (light weight) under an `AccentRule` + `EyebrowLabel` dimension; **options as `HairlineRow`s** with a coral radio (filled `accentColor` dot when selected, thin ring otherwise); single-choice/multi-choice both hairline; voice option as a tracked text line ("— OR ANSWER BY VOICE"); Continue = flat coral `CinematicButton`. `QuestionsProgressView` = hairline breakdown with `HairlineProgress`.

**Acceptance:** matches the approved Questions mockup; feels like a conversation; submit/voice/progress all work; no form-y look, no emoji.

- [ ] Build, visual-check (answer a few, dark+light), commit:
```bash
git add Boop/Features/Onboarding/Views/QuestionsView.swift Boop/Features/Home/Views/QuestionsFullView.swift Boop/Features/Questions/Views/QuestionsProgressView.swift
git commit -m "feat(cinematic): redesign Questions (answering + full + progress)"
```

---

## Task 10: Redesign Profile / Me (hero)

**Files:** Modify `Boop/Features/Profile/Views/ProfileView.swift`.

**Brief (the approved direction):** Preserve behavior (edit, photos, voice, navigation to sub-pages, appearance toggle, block/report/delete, logout). Re-express: own photo header fading to ground (`CinematicHeader` with the user's clear profile photo, blurRadius 0) with `AccentRule` + name `cineDisplay` + tracked subtitle ("28 · Bengaluru · VOICE VERIFIED"); stats (answers · badges) as typeset numerals split by a hairline with `EyebrowLabel`s; personality type as a quiet feature line (`EyebrowLabel` "YOUR TYPE" + `cineHeadline`); the Me items + settings as a `HairlineRow` list with thin chevrons (no icons/tiles); appearance picker restyled minimal; logout/delete as tracked text rows (delete in `error`).

**Acceptance:** matches the approved Profile mockup; premium header; hairline list; behavior intact.

- [ ] Build, visual-check, commit:
```bash
git add Boop/Features/Profile/Views/ProfileView.swift
git commit -m "feat(cinematic): redesign Profile / Me"
```

---

## Task 11: Profile sub-pages

**Files:** Modify `Boop/Features/Profile/Views/PersonalityReportView.swift`, `PersonalityRadarChartView.swift`, `MyAnswersView.swift`, `BadgesView.swift`, `NotificationSettingsView.swift`, `VoiceReRecordView.swift`.

**Brief:** Preserve behavior. Re-express each:
- **PersonalityReportView:** editorial — `EyebrowLabel`/`cineDisplay` headings, facets as hairline rows with typeset scores + thin bars (`HairlineProgress`), narrative in `cineBody`.
- **PersonalityRadarChartView:** redraw the radar with **thin coral + white strokes on near-black** (tonal — drop the per-dimension rainbow `dimensionColor`; use `accentColor` + white opacities).
- **MyAnswersView:** hairline list, `EyebrowLabel` dimension tags, answer in `cineBody`.
- **BadgesView:** restrained — badges as a list/grid of tracked names with earned = full opacity + a thin coral mark, locked = dim; **no emoji medals** (use a thin SF Symbol or just typography).
- **NotificationSettingsView:** hairline toggle rows, `EyebrowLabel` section headers (toggles keep coral tint).
- **VoiceReRecordView:** `VoiceLine` + cinematic recorder controls.

**Acceptance:** all six cohesive; radar tonal not rainbow; no emoji; behavior intact.

- [ ] Build, visual-check each, commit:
```bash
git add Boop/Features/Profile/Views/PersonalityReportView.swift Boop/Features/Profile/Views/PersonalityRadarChartView.swift Boop/Features/Profile/Views/MyAnswersView.swift Boop/Features/Profile/Views/BadgesView.swift Boop/Features/Profile/Views/NotificationSettingsView.swift Boop/Features/Profile/Views/VoiceReRecordView.swift
git commit -m "feat(cinematic): re-skin Profile sub-pages"
```

---

## Task 12: Matches sub-pages

**Files:** Modify `Boop/Features/Matches/Views/CompatibilityDeepDiveView.swift`, `DatePlanView.swift`, `RelationshipInsightsView.swift`, `ScoreProgressView.swift`.

**Brief:** Preserve behavior (deep-dive narratives, date propose/respond/safety/check-ins/venues, insights load, score history). Re-express:
- **CompatibilityDeepDiveView:** dimension breakdown as hairline rows with typeset % + thin bars; narratives in `cineBody`; `EyebrowLabel` sections.
- **DatePlanView:** editorial plan layout; safety (emergency contact, location sharing, check-ins) as clearly-marked hairline sections with `EyebrowLabel`s; cinematic buttons; keep all the safety wiring.
- **RelationshipInsightsView:** narrative body type, eyebrows, coral rules.
- **ScoreProgressView:** redraw the history chart as a **thin coral line on near-black with hairline gridlines** (drop heavy fills).

**Acceptance:** cohesive; charts thin/tonal; date safety intact; behavior intact.

- [ ] Build, visual-check, commit:
```bash
git add Boop/Features/Matches/Views/CompatibilityDeepDiveView.swift Boop/Features/Matches/Views/DatePlanView.swift Boop/Features/Matches/Views/RelationshipInsightsView.swift Boop/Features/Matches/Views/ScoreProgressView.swift
git commit -m "feat(cinematic): re-skin Matches sub-pages"
```

---

## Task 13: Auth, Splash (rename), Onboarding intro

**Files:** Modify `Boop/Features/Splash/SplashView.swift`, `OnboardingIntroView.swift`, `Boop/Features/Auth/Views/WelcomeView.swift`, `PhoneInputView.swift`, `OTPVerificationView.swift`.

**Brief:** Preserve behavior (auth flow, OTP entry/resend, intro paging). Re-express:
- **SplashView:** change the wordmark text from **"boop" → "UnMutee"** (line ~85) and restyle: near-black ground, `cineDisplay`/light-weight tracked wordmark, a quiet `AccentRule` reveal animation (keep timing logic).
- **OnboardingIntroView:** full-bleed cinematic slides (blurred photography ok), `cineTitle` headlines, `EyebrowLabel` captions, coral-rule/hairline page dots; keep skip + paging.
- **WelcomeView / PhoneInputView / OTPVerificationView:** near-black, `cineDisplay` headlines, `EyebrowLabel` field labels, hairline inputs (restyle `BoopTextField`/`BoopPhoneInput`/`BoopOTPField` if needed to hairline+sharp+coral-focus), cinematic buttons; keep validation/shake/resend countdown.

**Acceptance:** splash says "UnMutee"; auth cohesive; OTP coral focus; flow + validation intact.

- [ ] Build, visual-check (incl. splash text), commit:
```bash
git add Boop/Features/Splash/SplashView.swift Boop/Features/Splash/OnboardingIntroView.swift Boop/Features/Auth/Views/WelcomeView.swift Boop/Features/Auth/Views/PhoneInputView.swift Boop/Features/Auth/Views/OTPVerificationView.swift
git commit -m "feat(cinematic): re-skin auth + onboarding intro; splash boop->UnMutee"
```

---

## Task 14: Onboarding steps

**Files:** Modify `Boop/Features/Onboarding/Views/BasicInfoView.swift`, `LocationView.swift`, `BioView.swift`, `VoiceIntroView.swift`, `PhotoUploadView.swift`, `OnboardingContainerView.swift`.

**Brief:** Preserve behavior & the 6-step flow/gates (flow change is the later effort). Re-express a consistent cinematic step: `OnboardingContainerView` progress → `EyebrowLabel` "STEP N OF 6" + `HairlineProgress`; each step uses `cineTitle` prompt, hairline inputs / `BoopSegmentedPicker` restyled, sharp controls; `VoiceIntroView` uses `VoiceLine` + cinematic recorder; `PhotoUploadView` photo grid framed (not candy tiles); cinematic Continue button.

**Acceptance:** onboarding cohesive; same steps/gates; inputs hairline; behavior intact.

- [ ] Build, visual-check (walk the steps), commit:
```bash
git add Boop/Features/Onboarding/Views/BasicInfoView.swift Boop/Features/Onboarding/Views/LocationView.swift Boop/Features/Onboarding/Views/BioView.swift Boop/Features/Onboarding/Views/VoiceIntroView.swift Boop/Features/Onboarding/Views/PhotoUploadView.swift Boop/Features/Onboarding/Views/OnboardingContainerView.swift
git commit -m "feat(cinematic): re-skin onboarding steps"
```

---

## Task 15: Misc surfaces + tab bar

**Files:** Modify `Boop/Features/Notifications/Views/NotificationInboxView.swift`, `Boop/Features/Chat/Views/ChatMediaGalleryView.swift`, `ImageViewerView.swift`, `Boop/Features/Safety/ReportUserSheet.swift`, `Boop/Features/Main/MainTabView.swift`.

**Brief:** Preserve behavior. Re-express:
- **NotificationInboxView:** hairline notification rows, `cineBody` title, tracked `cineCaption` timestamp, coral unread dot.
- **ChatMediaGalleryView / ImageViewerView:** near-black, minimal chrome, thin controls.
- **ReportUserSheet:** hairline reason rows (the report flow from trust-safety) with coral selection, cinematic submit; keep all submit logic.
- **MainTabView:** dark tab bar, thin-weight SF Symbol tab icons, **coral selected state** (replace `.tint(BoopColors.primary)` which now resolves to coral — confirm selected icons read; set unselected to `textMuted`); keep the 4 tabs + chat badge.

**Acceptance:** cohesive; tab bar dark with coral selection; report flow intact.

- [ ] Build, visual-check, commit:
```bash
git add Boop/Features/Notifications/Views/NotificationInboxView.swift Boop/Features/Chat/Views/ChatMediaGalleryView.swift Boop/Features/Chat/Views/ImageViewerView.swift Boop/Features/Safety/ReportUserSheet.swift Boop/Features/Main/MainTabView.swift
git commit -m "feat(cinematic): re-skin notifications, media gallery, report sheet, tab bar"
```

---

## Task 16: Widget, App Clip, build bump, full sweep verification

**Files:** Modify `BoopWidget/BoopWidgetViews.swift`, `BoopClip/ProfilePreviewView.swift`, `project.yml`.

- [ ] **Step 1: Re-skin Widget + Clip**

`BoopWidgetViews`: near-black widget background, `cineCaption`/tracked labels, blurred portrait thumbnails, coral accent (no candy). `ProfilePreviewView` (App Clip): cinematic profile preview matching Discover/Profile language. Keep widget data + clip universal-link behavior.

- [ ] **Step 2: Bump build to 13**

In `project.yml`: `CURRENT_PROJECT_VERSION: "12"` → `"13"` and `CFBundleVersion: "12"` → `"13"` (both occurrences).

- [ ] **Step 3: Build**

Run `xcodegen generate` then the build command. Expected `BUILD SUCCEEDED`.

- [ ] **Step 4: Full-sweep visual verification (dark + light)**

Walk EVERY surface in the simulator in **both** appearances; confirm one coherent Cinematic Dark language and **no emoji in chrome, no candy tiles, no leftover gradients/pills**, splash says "UnMutee". Surfaces: Splash, Onboarding intro, Auth (welcome/phone/OTP), Onboarding steps, Home, Discover, Games (lobby+round), Chat (inbox+fog+chips), Match detail, The Clearing, Gone-quiet, Profile + all sub-pages (report/radar/answers/badges/notif-settings/voice), Matches sub-pages (deep-dive/date/insights/score), Notifications, Tab bar, Widget. Fix any leftover token/literal inline (no structural/behavior changes).

- [ ] **Step 5: Commit**

```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add project.yml Boop.xcodeproj/project.pbxproj BoopWidget/BoopWidgetViews.swift BoopClip/ProfilePreviewView.swift
git commit -m "feat(cinematic): re-skin widget + clip; build 13; sweep verified"
```

---

## Out of scope
- No flow/behavior/navigation/endpoint changes (first-time-flow restructure is the next, separate effort).
- No backend changes, no new features.
- Light variant is verified-coherent via tokens; dark is the hand-polished priority.

## Post-implementation
Ship build 13 to TestFlight via the saved recipe (ASC key `A4MNMMCCVB`, issuer `0bbf6f7f-a7cf-4b88-8759-4c85e5c0f240`, manual signing) — memory `unmutee-testflight-upload-recipe`.
