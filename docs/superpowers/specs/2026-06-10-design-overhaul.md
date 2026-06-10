# UnMutee — Design + Feature Overhaul ("Electric Heart")

> **Date:** 2026-06-10
> **Author:** CPO/Design (Claude) + Founder (Nirpeksh)
> **Status:** Design — approved in brainstorming, pending spec review
> **Scope:** Full visual-identity overhaul (light + dark) plus redesign of the daily-loop surfaces and the signature comfort-to-reveal experience. Frontend only (`boop-frontend`, SwiftUI). No backend changes — all data this design needs already exists (comfort score + breakdown, reveal status, streaks, daily questions, compatibility, voice notes, games).

---

## 1. Why this exists

The product's mechanics are strong but the app "doesn't excite you when you open it — potentially dull." Root cause is conceptual, not cosmetic: an app about *people* currently shows almost no people (everything hides behind blur and progress bars), forces light mode, and renders its signature mechanic (comfort → photo reveal) as an invisible backend number. This overhaul fixes the feeling by (a) giving the app a bolder, emotional identity, (b) making **blurred human faces the hero visual** everywhere, and (c) staging the comfort-to-reveal arc as visible, suspenseful, celebrated.

**Design north star:** opening UnMutee should feel like *butterflies* — warm, alive, with somewhere exciting to go on every screen.

---

## 2. Decisions locked in brainstorming

| Decision | Choice |
|---|---|
| Visual identity | **Electric Heart** — coral→violet gradients, big confident type, juicy glowing buttons over a warm base |
| Theme | **Light + real dark mode**, semantic tokens, follows system setting (removes forced light mode) |
| Scope | **Full sweep** — every surface gets at least the token restyle; daily-loop + signature surfaces get hand-crafted redesign |
| Home | **Moment-Led Feed** — scrollable magazine: hero moment → your people → daily question → new tonight |
| Chat hero | **The Fog** — their blurred face *is* the chat background; fog lifts as comfort climbs; subtle "+points" nudge chips |
| Reveal | **The Clearing** — full-screen takeover; fog dissolves, face resolves, journey recap, primed return to chat |
| Navigation | **4 tabs, Home as launcher** — Home/Discover/Chat/Me unchanged; Home sections tease into the full Discover deck and Chat inbox |
| Stalled matches | **Gentle nudge, then easy release** — soft "gone quiet" card → Boop to revive OR gracefully let go; releasing frees a Discover slot |

---

## 3. Design system: from hardcoded light colors to semantic adaptive tokens

### 3.1 The problem with today's tokens

`Boop/DesignSystem/Theme/BoopColors.swift` is an `enum` of ~60 static `Color(hex:)` literals, all light-mode values, plus light-only gradients. `BoopApp.swift` forces `.preferredColorScheme(.light)`. There is no semantic layer, so dark mode is impossible without touching every call site, and the palette is the old flat coral/mint.

### 3.2 The new architecture (additive, non-breaking)

Introduce a **semantic token layer** that resolves per-trait (light/dark) at runtime, using SwiftUI dynamic colors built from `UIColor { traitCollection in ... }` (pure code — consistent with the existing `Color(hex:)` approach, no asset-catalog migration). The existing `BoopColors` names are **kept and repointed** to the new tokens so the ~hundreds of existing call sites keep compiling and pick up the new look automatically.

**Token roles (each has a light and dark value):**

```
// Brand (Electric Heart)
brandCoral          #FF4D6D   (light)   #FF5C7A  (dark)
brandViolet         #A23DE8   (light)   #B65CF0  (dark)
brandGradient       coral → violet (the signature; replaces primaryGradient)

// Surfaces
background          #FFFBF7 warm cream / #120A16 deep plum
surface             #FFFFFF / #1C1124
surfaceElevated     #FFFCFA / #241630
surfaceTinted       #FFF1F3 / #2A1830   (the soft coral/violet wash used behind nudges)

// Text
textPrimary         #2A1A2E / #F4ECF2
textSecondary       #6B5B70 / #B3A4BC
textMuted           #9B8FA5 / #6E6076
textOnBrand         #FFFFFF (both)

// Lines / states
border              #EEE6EE / #2E2238
success / error / warning  retuned for contrast on both themes
```

**Mapping rules:**
- `BoopColors.primary` → `brandCoral`; introduce `BoopColors.brand` + `BoopColors.brandGradient` (coral→violet) as the new signature; deprecate `secondary`/`accent` mint+yellow usage in favor of the coral→violet system (keep the symbols defined so nothing breaks, but stop using them in redesigned surfaces).
- `background`, `surface*`, `text*`, `border`, `chatBackground`, `chatBubbleReceived` all become adaptive.
- `dimensionColor(for:)` is retuned to read well on both themes.
- Light-only decorative gradients (`sunsetGradient`, `tealMintGradient`, etc.) are retained but unused in redesigned surfaces; new surfaces use `brandGradient` and a small set of adaptive gradients.

**`BoopApp.swift`:** remove `.preferredColorScheme(.light)` so the app follows the system setting. Add a manual override toggle on the **Me (Profile) screen** (System / Light / Dark) persisted to `@AppStorage`, applied at the root.

`BoopTypography` (Nunito scale) and `BoopSpacing`/`BoopRadius` are unchanged in structure; type may go slightly bolder/larger on hero surfaces using the existing weights.

### 3.3 Blur-as-hero: a shared portrait component

The reveal mechanic already serves `silhouetteUrl` (discovery), `blurredUrl` (connecting), and clear `url` (revealed) plus an integer `blurLevel`. Introduce one reusable view used everywhere a person appears:

**`BlurredPortrait`** — renders a remote portrait at a blur radius derived from comfort/stage, with an optional gradient scrim and presence/streak adornments. Inputs: `urlString`, `blurLevel` (or comfort 0–100 → radius curve), `shape` (circle / roundedRect), `overlay` content. Animates blur radius changes (so faces visibly "sharpen"). Built on the existing `BoopRemoteImage`. This is the single component that makes the whole app feel human and warm.

---

## 4. Navigation

Tabs unchanged: **Home · Discover · Chat · Me**. Home is the curated launcher; its sections deep-link into Discover (full deck) and Chat (a specific conversation), so there is no duplicated functionality — only teasers that route to the canonical surfaces.

---

## 5. Home — "Moment-Led Feed"

A vertical, editorial scroll. Sections top to bottom:

1. **Greeting + streak pill** — "good evening, Nirpeksh" and the most-urgent streak ("🔥 4 · 3h left") if one is at risk.
2. **Hero moment** — the single most emotionally charged item, chosen by priority: a new voice note from a near-reveal connection > reveal-ready > new like > streak at risk. Rendered as a `BlurredPortrait` (near-clear if close to reveal) with a one-line headline ("Ananya sent you a voice note", "8 points from focus") and a single tap target into that chat.
3. **Your people** — horizontal row of `BlurredPortrait` cards for active connections, each sharpening by comfort, with presence dot / streak ring / "typing…" state. Tapping opens that chat. A trailing "→" opens Chat.
4. **Today's question** (daily ritual) — a brandGradient band with today's question and "N matches answered · tap to unlock theirs." Answering routes into the existing questions flow; this is the core "why open today" hook. (Uses existing daily-question data; "unlock theirs" surfaces matches' answers to the same question.)
5. **New tonight** — a teaser strip/grid of 2–4 fresh discovery candidates (`BlurredPortrait` + compatibility %), tapping into the Discover tab.

**Hierarchy rule:** exactly one hero; everything else is a calm section. Empty/low-data states degrade gracefully (no connections yet → discovery and ritual lead).

**Source data:** all exists — pending likes, matches w/ comfort + streak + last message, daily question + matches' answers, discovery candidates.

---

## 6. Chat — "The Fog"

The conversation screen becomes atmospheric:

- **Background:** the other person's portrait, heavily blurred, fills the chat behind a translucent scrim. **Blur radius is tied to comfort score** — the fog is visibly thicker at 40 than at 65. As comfort rises, the fog lifts. This *is* the progress indicator; there is no dominating meter.
- **Header:** name, presence, and a compact "the fog is lifting · 62/70" pill (tappable → a detail sheet with the full comfort breakdown that already exists).
- **Nudge chips:** contextual, subtle prompts toward 70 — e.g. a centered "🎙 a voice note clears more fog →" and composer chips ("🎙 voice · 🎮 game · 💬 go deeper"). These map to the real comfort factors (voice engagement, games, message depth). Copy is encouraging, never nagging.
- **Messages/composer:** restyled to Electric Heart — sent bubbles use `brandGradient`, received bubbles adaptive surface; bubbles sit on the fog with subtle elevation for legibility.
- **Games entry** lives here (chip + invite), opening the existing synced game flow.
- **Below 70:** reveal is locked; the fog + nudges communicate "keep going." **At/above 70 with mutual reveal request,** trigger The Clearing (§7). The existing 3-active-days floor still applies — if comfort ≥ 70 but days < 3, the nudge copy reflects "you're close, give it a little time" rather than offering reveal.

Legibility is the main risk; the scrim opacity and bubble elevation are tuned so text always passes contrast on both themes, including when the background portrait is light.

---

## 7. The reveal — "The Clearing"

Triggered when both users have requested reveal at comfort ≥ 70 (backend already advances stage to `revealed` and notifies both). On the revealing client:

1. Full-screen takeover. The fog the user has talked through **dissolves in an animated wash**, and the other person's portrait **resolves from blurred to fully clear** (animate `BlurredPortrait` blur → 0).
2. Headline: "the fog has lifted" → their name, large.
3. **Journey recap ribbon** — chips for what earned it: days talking, games played, voice notes exchanged (all derivable from existing data / comfort breakdown).
4. Primary action "Say something 💕" returns to the now-clear chat with the composer focused. A secondary, optional **shareable "we met" card** can be a fast-follow (not required for v1).
5. If the *other* user triggered the reveal while this user is offline, they get the existing `photos_revealed` push; opening it plays The Clearing.

Both participants experience The Clearing (each sees the other resolve).

---

## 8. Supporting features

### 8.1 Games surfacing
Games are currently buried in match detail. Surface them where comfort is built: the **Fog nudge chip + an in-chat game invite**, and an entry from the Home hero when a game is the recommended next move. The live synced-game UI (ready → 3-2-1 → simultaneous answer → reveal) gets the Electric Heart restyle but keeps its mechanics.

### 8.2 Stalled-match handling
When a connection is one-sided or inactive (reuse the existing date-readiness "red flag" signals: >80% one-sided, inactivity), surface a gentle card in that chat and/or the Home "your people" row: **"This one's gone quiet."** Two actions:
- **Boop to revive** — uses the existing boop (4h cooldown) to nudge.
- **Let it go** — archives the match (existing archive flow, `archiveReason: 'one_sided'`/`'inactivity'`) and **frees a Discover slot**, framed as "made room for someone new" so moving on reads as progress, not loss.

No silent auto-archive; the user always chooses.

### 8.3 Full-sweep restyle (token-level + targeted polish)
- **Onboarding** — Electric Heart gradients, bolder type, juicy buttons; flow unchanged. Progress toward the 15-answer unlock keeps the recently-added progress UI.
- **Discover** — candidate cards use `BlurredPortrait`, brandGradient Connect button, voice-first presentation retained.
- **Profile / Me** — restyle; add the **theme override toggle** (System/Light/Dark) and ensure the existing block/report/delete-account entries adopt the new styling.
- **Match detail, Personality report, Badges, Notifications** — token restyle so nothing looks left behind.

---

## 9. Out of scope (explicit)

- No backend changes. (If a future "we met" share-card or a Home daily-question "compare answers" view needs a new endpoint, that's a separate spec.)
- No new monetization, no Android, no localization, no iPad layout — separate efforts.
- Shareable reveal card is a fast-follow, not v1.
- Accessibility pass (Dynamic Type, full VoiceOver) is desirable but tracked separately; this spec keeps existing accessibility and adds dark mode.

---

## 10. Component / file impact map

| Area | New | Modified |
|---|---|---|
| Tokens | semantic adaptive color layer | `BoopColors.swift` (repoint names), `BoopApp.swift` (drop forced light, add theme override) |
| Shared | `BlurredPortrait` view | `BoopRemoteImage` (compose) |
| Home | `MomentHeroCard`, `YourPeopleRow`, `DailyQuestionBand`, `NewTonightStrip` | Home view + view model (compose sections from existing data) |
| Chat | fog background layer, nudge chips, fog header pill | `ChatInboxView.swift` (ChatConversationView), composer |
| Reveal | `TheClearingView` (full-screen takeover + animations) | reveal trigger wiring from chat + `photos_revealed` deep link |
| Games | in-chat game invite/entry | existing `GameViews` (restyle) |
| Stalled | "gone quiet" card | match/chat views, archive wiring (existing endpoint) |
| Sweep | — | Onboarding, Discover, Profile/Me (theme toggle), Match detail, Personality, Badges, Notifications |

---

## 11. Success criteria

- App follows system light/dark; a manual override works; no surface is unreadable in either theme.
- Every primary surface shows real (blurred) human faces, not empty placeholders.
- In any active conversation, a user can see how close they are to the reveal and what action moves it — without leaving chat.
- The reveal plays a celebrated full-screen moment, not a silent un-blur.
- Stalled connections can be revived or released in two taps, and releasing visibly refills discovery.
- Build is green and ships to TestFlight; no regressions in the trust-&-safety or comfort-floor behavior shipped previously.
