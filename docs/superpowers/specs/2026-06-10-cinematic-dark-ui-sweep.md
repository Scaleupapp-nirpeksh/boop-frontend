# UnMutee — Cinematic Dark UI Sweep (full app redesign)

> **Date:** 2026-06-10
> **Author:** Design (Claude) + Founder (Nirpeksh)
> **Status:** Design — approved in brainstorming, pending spec review
> **Scope:** Complete visual redesign of **every screen** in the iOS app to the "Cinematic Dark" language. Frontend only (`boop-frontend`). No flow/behavior changes — same data, same navigation, same endpoints; this is purely look-and-feel. (The first-time-flow / time-to-dopamine restructure is a **separate, later** effort.)
> **Supersedes:** the visual language of `2026-06-10-design-overhaul.md` ("Electric Heart"). The semantic token *architecture* from that effort is reused; the *values and execution* are replaced.

---

## 1. Why

The founder's verdict on the shipped "Electric Heart" look and the candy mockups: cartoonish — emoji-as-icons, pastel tiles, juicy gradient buttons, ring badges. It reads like a generic template, not a premium product. The chosen replacement is **Cinematic Dark**: photography-led, editorial, restrained, dark-first, with a single coral accent and zero decorative emoji. Restraint signals quality. This redesign brings the *entire* app — including the already-shipped Home/Chat/reveal/match screens — into one coherent, grown-up language.

---

## 2. The Cinematic Dark language (the system every screen obeys)

**Ground.** Near-black with a violet undertone. Deep, quiet, cinematic. People appear as full-bleed blurred photography that fades into the ground.

**Typography.** Light-weight display type (SF/system, weight 300) for names, questions, headlines — large and confident, negative tracking on big sizes. Labels are **uppercase, letter-spaced (1.5–3px), low-opacity** — the editorial signature. Body stays regular weight, comfortable. Nunito is replaced by the system font for the cinematic weights and tracking control (the variable Nunito lacks the ultralight register and tracked-caps feel); confirm at build whether to keep Nunito for body or move fully to system — default to **system font** for consistency with the light-weight aesthetic.

**Accent.** A single flat coral (`#FF4D6D`) used **sparingly**: a thin 2px rule under a label, the fill of a selected radio, the single primary action bar, the filled portion of a 1px progress line. Gradients from Electric Heart are **retired** (no coral→violet juicy buttons). One accent, used with discipline.

**Structure.** Hairlines, not cards. 1px dividers at low-opacity white (dark) / warm-grey (light) separate rows and sections. Lists are hairline-separated rows with thin chevrons — not filled tiles. Generous negative space.

**Shape.** Sharp. Controls use a **2px corner radius** (not pill/20px rounding). Primary action = a sharp coral bar. Portraits/photos keep soft rounding only where they're framed.

**Iconography.** **No emoji anywhere in the UI.** Where an icon is needed, use thin-weight SF Symbols (`.thin`/`.ultraLight`) sparingly, or a text label. Play controls = a simple triangle; chevrons = thin ›.

**Motion.** Quiet and filmic — slow fades, the comfort-blur dissolve, no bouncy springs. (Reuse the existing `BlurredPortrait` animated blur.)

**Light variant (secondary).** The Editorial direction: cream `#F7F3EC` ground, ink `#1B1B18` text, a single vermilion `#C0392B` accent, warm-grey hairlines, the same layouts and type treatment. Carried by the semantic token layer so layouts are theme-agnostic; dark is the hand-polished priority, light is verified to be coherent.

---

## 3. Token system (dark-first re-skin)

Reuse the semantic adaptive layer from the Electric Heart effort (`Color.dynamic(light:dark:)`, `BoopColors`, `AppTheme`), but **redefine the values dark-first** and change defaults.

### 3.1 Color tokens (dark value listed first since dark is primary)

```
ground            dark #0C0810   light #F7F3EC      (app background)
surface           dark #14101B   light #FFFFFF      (raised panels, sparingly)
surfaceGlass      dark rgba(34,22,42,.72)+blur  light rgba(255,255,255,.7)+blur
textPrimary       dark #F4ECF2   light #1B1B18
textSecondary     dark rgba(255,255,255,.62)  light #6B6358
textMuted         dark rgba(255,255,255,.40)  light #A8A095   (labels)
hairline          dark rgba(255,255,255,.11)  light #E2DBCF   (dividers/rules)
accent            dark #FF4D6D   light #C0392B   (the single coral/vermilion)
accentOnDark      #FF4D6D (used on photography in both themes)
textOnAccent      #FFFFFF
success/error/warning  retuned for legibility on near-black + cream
```

- `BoopColors.brand`/`primary` → `accent` (flat coral). `brandViolet`, `brandGradient`, `primaryGradient` → **deprecated**: keep the symbols defined (so nothing breaks) but repoint `primaryGradient` to a *flat* `accent` fill so any not-yet-redesigned surface stops showing the old gradient. New code uses `accent` directly.
- `background`/`surface*`/`text*`/`border`/`chatBackground`/`chatBubbleReceived` repointed to the values above.
- `BoopApp` default appearance flips to **dark** (`@AppStorage("appTheme")` default `.dark`); the Profile appearance toggle still offers System/Light/Dark.

### 3.2 Typography

Add a cinematic type ramp (system font) used by redesigned screens:
```
displayXL   42 / weight .thin / tracking -1     (reveal, big moments)
display     32 / weight .light / tracking -0.5  (names, screen titles)
title       25 / weight .light / tracking -0.3  (questions, section heroes)
label       11 / weight .semibold / tracking +2 / UPPERCASE   (the eyebrow signature)
body        15 / weight .regular                (content)
bodyLight   15 / weight .light                  (options, quiet content)
caption     11 / weight .regular / textMuted
```
Keep `BoopTypography` (Nunito) defined for any un-migrated surface; redesigned screens use the new ramp. Decide at implementation whether body stays Nunito or system — default system.

### 3.3 Radius & rules
- `BoopRadius`: introduce `sharp = 2` and use it for controls/buttons/inputs in redesigned screens. Photos/portrait frames keep `lg/xl`. Pills (`full`) retired except for small status dots.
- Hairline helper: a reusable 1px `hairline`-colored divider/rule + a coral 2px accent rule.

### 3.4 Reusable cinematic components (built once, used everywhere)
- **`CinematicHeader`** — full-bleed `BlurredPortrait` fading into `ground`, with a coral rule + light-weight title + tracked subtitle overlaid (Discover, Profile, Match detail, reveal).
- **`EyebrowLabel`** — uppercase tracked label (the editorial signature).
- **`AccentRule`** — the 24×2 coral rule used as a section marker.
- **`HairlineRow`** — a list row: title (+ optional trailing value/chevron), hairline top border (settings lists, option lists, stat breakdowns).
- **`HairlineProgress`** — a 1px track with a coral filled portion (questions, comfort).
- **`CinematicButton`** — sharp (2px) primary = flat coral bar; secondary = hairline-outlined; tertiary = tracked text. Replaces the gradient `BoopButton` look (keep `BoopButton` API, restyle its internals).
- **`VoiceLine`** — the refined play control + thin waveform/progress line (Discover, chat, voice intro).

---

## 4. Per-screen redesign (every screen; grouped)

Each screen adopts the language; notable per-screen intent below. **No behavior/flow change** — same data and navigation.

### 4.1 Already-shipped screens — re-skin to Cinematic Dark
- **Home (Moment-Led Feed)** — greeting as light-weight display + tracked date label; hero connection as a `CinematicHeader`; "your people" row as blurred portraits with hairline captions (drop the candy borders); the daily-question band becomes a hairline-bounded block with a coral rule (not a gradient slab); activity as hairline rows. Bell/streak as thin elements, no pill candy.
- **Chat — The Fog** — already dark-leaning; align scrim/ground to `ground`, bubbles to surface/coral (sent = flat coral, 2px corners; received = `surface`), the fog pill + nudge chips become tracked-label/hairline style (no mint capsules). Composer on `surface`, sharp.
- **The Clearing (reveal)** — already cinematic in spirit; retune type to the new ramp, recap chips become hairline/tracked, single coral accent.
- **Match detail** — `CinematicHeader` hero; scores as typeset numerals with hairline dividers (retire the dark-card tiles + warm gradient bar); comfort/readiness as `HairlineProgress`; gone-quiet + reveal CTAs as `CinematicButton`.

### 4.2 The four hero screens
- **Discover** (`DiscoverView`, `CandidateCardView`, `ConnectNoteSheet`) — the Cinematic Dark direction shown: full-bleed blurred portrait, light-weight name, "NN compatible" tracked label, a thin coral rule, `VoiceLine`, hairline "why you fit" note, Pass (hairline) / Connect (coral bar). Connect-note sheet matches.
- **Games** (`GameViews`, `GameHistoryView`) — a quiet lobby: live invite as a single coral-accented feature block (not a gradient slab); all games as **hairline rows** (name · vibe · time as tracked metadata), no colourful tiles, no emoji. The live synced round (ready → 3-2-1 → simultaneous answer → reveal) restyled cinematic; countdown as large light-weight numerals.
- **Questions** (`QuestionsView`, `QuestionsFullView`, onboarding `QuestionsView`, `QuestionsProgressView`) — the shown design: near-black, one light-weight question, `EyebrowLabel` dimension under an `AccentRule`, options as `HairlineRow`s with a coral radio when selected, `HairlineProgress` toward 15, voice option as a tracked text line, `CinematicButton` Continue.
- **Profile / Me** (`ProfileView`) — the shown design: own photo fading to `ground` with name under a coral rule, stats as typeset numerals split by a hairline, personality type as a quiet feature line, settings as a `HairlineRow` list with thin chevrons (no icons/tiles). Appearance toggle, block/report/delete entries restyled.

### 4.3 Profile sub-pages
- **PersonalityReportView** + **PersonalityRadarChartView** — editorial report: light-weight type, the radar restyled to thin coral/white strokes on near-black (no rainbow dimension colors — tonal with coral accent), facets as hairline rows with typeset scores.
- **MyAnswersView** — hairline list of question→answer, tracked dimension labels.
- **BadgesView** — badges as a restrained grid/list: monochrome thin glyphs or typeset names with earned/locked state via opacity + a coral mark on earned (no emoji medals).
- **NotificationSettingsView** — hairline toggle rows, tracked section labels.
- **VoiceReRecordView** — `VoiceLine` + cinematic recorder.

### 4.4 Matches sub-pages
- **CompatibilityDeepDiveView** — dimension breakdown as hairline rows with typeset percentages + thin bars; AI narrative in body type.
- **DatePlanView** — editorial plan layout; safety (emergency contact, check-ins, location) as clearly-marked hairline sections; CTAs as `CinematicButton`.
- **RelationshipInsightsView** — narrative in body type, section eyebrows, coral rules.
- **ScoreProgressView** — the history chart restyled to thin coral line on near-black with hairline gridlines.

### 4.5 Auth & entry
- **SplashView** — **rename "boop" → "UnMutee"**; cinematic wordmark (light-weight, tracked) on `ground` with a quiet coral rule animation. (The bug the founder flagged.)
- **OnboardingIntroView** — full-bleed cinematic intro slides, light-weight type, tracked labels, coral-rule progress dots.
- **WelcomeView / PhoneInputView / OTPVerificationView** — near-black, light-weight headlines, hairline inputs, `CinematicButton`, tracked field labels; OTP boxes sharp with coral focus.

### 4.6 Onboarding steps
- **BasicInfoView, LocationView, BioView, VoiceIntroView, PhotoUploadView** — consistent cinematic step layout: `EyebrowLabel` step indicator + `HairlineProgress`, light-weight prompt, hairline inputs / sharp controls, `VoiceLine` for the voice step, photo grid framed (not tiled-candy). Same 6-step flow & gates (flow change is the later effort).

### 4.7 Misc
- **NotificationInboxView** — hairline notification rows, tracked timestamps, coral unread dot.
- **MatchCelebrationView** — align to The Clearing's cinematic moment.
- **ChatMediaGalleryView, ImageViewerView, ConversationStartersCard, ReportUserSheet** — cinematic surfaces, hairline structure, `CinematicButton`s.
- **MainTabView** — dark tab bar, thin-weight SF Symbol tab icons, coral selected state (no filled candy).
- **BoopWidget** (`BoopWidgetViews`) + **BoopClip** (`ProfilePreviewView`) — match the cinematic language (near-black widget, light-weight type, blurred portrait, coral accent).

---

## 5. Out of scope
- **No flow/behavior/navigation changes.** Same onboarding steps, same gates, same endpoints, same tab structure. (First-time-flow/dopamine restructure = separate spec, next.)
- No backend changes.
- No new features (this is purely visual).
- Custom font adoption beyond system/Nunito decision; no new third-party UI libs.
- Light-variant hand-polish is best-effort via tokens; dark is the priority surface.

## 6. Component / file impact map

| Layer | Work |
|---|---|
| Tokens | `BoopColors` (dark-first values, accent flat, gradient retired), `BoopSpacing`/`BoopRadius` (+`sharp`), new cinematic type ramp, `BoopApp` default→dark |
| New shared components | `CinematicHeader`, `EyebrowLabel`, `AccentRule`, `HairlineRow`, `HairlineProgress`, `VoiceLine`; restyle `BoopButton`→cinematic, `BoopCard`/`boopCard` →hairline panel, `BoopTextField`/`BoopOTPField`/`BoopSegmentedPicker`/`BoopProgressBar` |
| Shipped re-skin | Home, Chat (fog/bubbles/composer/chips), Match detail, The Clearing, GoneQuietCard, MomentHeroCard, YourPeopleRow, DailyQuestionBand, ConnectionCard |
| Hero redesigns | Discover (+CandidateCard, ConnectNoteSheet), Games (+History), Questions (onboarding + full + progress), Profile |
| Profile sub | PersonalityReport, PersonalityRadarChart, MyAnswers, Badges, NotificationSettings, VoiceReRecord |
| Matches sub | CompatibilityDeepDive, DatePlan, RelationshipInsights, ScoreProgress |
| Auth/entry | Splash (rename), OnboardingIntro, Welcome, PhoneInput, OTP |
| Onboarding steps | BasicInfo, Location, Bio, VoiceIntro, PhotoUpload |
| Misc | NotificationInbox, MatchCelebration, ChatMediaGallery, ImageViewer, ConversationStartersCard, ReportUserSheet, MainTabView, Widget, Clip |

## 7. Success criteria
- Every screen reads as one coherent Cinematic Dark language: near-black ground, light-weight display type, tracked uppercase labels, hairline structure, a single disciplined coral accent, **no emoji in chrome**, sharp controls.
- App is dark by default; the light (editorial cream/ink) variant is coherent via tokens; the Profile toggle switches them.
- Splash shows "UnMutee", not "boop".
- No behavior/flow regressions; trust-&-safety, comfort, reveal, games, date-planning all function exactly as before.
- Builds green; ships to TestFlight (build 13).
