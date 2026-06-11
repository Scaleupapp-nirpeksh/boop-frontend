# UnMutee — First-Time Flow + Personality Experience

> **Date:** 2026-06-11
> **Author:** CPO/Design (Claude) + Founder (Nirpeksh)
> **Status:** Design — approved in brainstorming, pending spec review
> **Scope:** Restructure the first-time user flow to front-load a fast reward ("reward first → curiosity → invest"), redesign the question experience (fixed onboarding set + an ongoing "Deepen" engine + daily nudge), and fix/redesign the personality & profile surfaces. **Both repos:** `boop-backend` (Node) + `boop-frontend` (iOS).
> **Builds on:** the Cinematic Dark visual language (`2026-06-10-cinematic-dark-ui-sweep.md`). All new UI is Cinematic Dark.

---

## 1. The problem

A new user does ~30–40 minutes of pure input — basic info → location → bio → voice intro (mic gate) → 3–6 photos → 6 questions to enter, **15 to be discoverable** — before the app gives anything back. The first reward (a personality read, or seeing anyone) lands at ~35 min, and two-sided liquidity (being seen by others) only at 15 answers (~55–70 min). Most people never reach the payoff.

**Fix:** front-load a delightful payoff in ~3 minutes (an instant personality reveal + a "people who fit you" teaser), then let curiosity pull users into the heavier profile-building (voice, photos, more questions) once they already want to be here.

---

## 2. Decisions locked in brainstorming

| Decision | Choice |
|---|---|
| First reward | **Personality reveal + "N people near you fit your vibe"** teaser |
| Reward speed | After **8 fixed onboarding questions** (curated to span all 8 dimensions) — ~3 min |
| Reorder | **Defer voice + photos** until the user tries to Connect |
| Connect-setup (→ ready) | **voice intro + 3 photos + the 8 onboarding answers** |
| Discoverable = connectable | Once `ready` (down from the 15-answer wall) |
| Onboarding question set | **Fixed, identical for every user**, all 8 dimensions, mixed depth, voice-or-text |
| Ongoing questions | A **"Deepen" engine** with a rising **match-confidence meter**; light daily drip + unlimited within unlocked; a **daily nudge** |
| Personality "type" | **Fixed archetype catalog** (numbered + rarity %) — treatment "Coded & Rare" |
| Page redesigns | Question Progress → confidence engine · Badges → trophy shelf · Personality → radar-led + Share card |
| Profile fixes | Set-Main bug · voice-intro progress bar · My-Answers voice playback + transcript · labeled photo-reorder |

---

## 3. The new flow

```
Phone OTP
 → Basic info (trimmed): first name, DOB, gender, interested-in, city   (~45s)
 → 8 fixed onboarding questions (all 8 dimensions, voice or text)        (~2.5 min)
 → ✨ PERSONALITY REVEAL + "N people near you fit your vibe →"          ← first dopamine (~3 min)
 → PREVIEW MODE: browse the blurred, voice-first Discover deck (read-only)
 → tap Connect → "Add your voice + photos to start connecting"
 → CONNECT-SETUP: voice intro + 3 photos  → now READY (discoverable + connectable); the pending like is sent
 → DEEPEN over time: answer more questions (confidence meter climbs) + daily nudges
```

---

## 4. Profile-stage model (backend)

Replaces the linear `incomplete → voice_pending → questions_pending → ready`:

- **`incomplete`** — no basic info.
- **`preview`** *(new)* — has basic info **and** the 8 onboarding answers. Can **fetch/browse** the Discover deck (read-only). **Not** surfaced to others. Cannot Connect. Personality reveal generated.
- **`ready`** — completed connect-setup: **voice intro + 3 photos** (already has the 8 answers). Discoverable by others **and** can Connect.

Transitions:
- `incomplete → preview`: basic info saved **and** `questionsAnswered >= 8` (the onboarding set).
- `preview → ready`: `voiceIntro` present **and** photos ≥ 3 (the 8 answers are already met).

Notes:
- The old `voice_pending` / `questions_pending` stages are removed (or mapped: any legacy user mid-onboarding is migrated to the nearest new stage by the same predicates). **No real users yet**, so a clean cutover + reseed is acceptable.
- The "15 answers" gate is **retired** as the discoverability bar; 15+ still matters for the *full* personality report and sharper matches (see §6), not for being seen.

---

## 5. Onboarding question set (the fixed 8)

The 8 dimensions: `emotional_vulnerability, attachment_patterns, life_vision, conflict_resolution, love_expression, intimacy_comfort, lifestyle_rhythm, growth_mindset` (each has 4–8 seeded questions; `depthLevel` ∈ surface/moderate/deep/vulnerable; `dayAvailable` day-drip; `Question.js`).

- **Add `isOnboarding: Boolean` (default false)** to `src/models/Question.js`.
- **Seed/flag exactly 8 questions as `isOnboarding: true`** — **one per dimension**, biased to **surface/moderate** depth and fast types (mostly single-choice, ≤1 free-text) so the set takes ~2.5 min while covering every compatibility angle. (Curate from the existing 60; do not write new content unless a dimension lacks a suitable fast question.) These 8 are `dayAvailable: 1`.
- **Identical for every user** — required for accurate overlap-based compatibility (the engine compares commonly-answered questions; a fixed early set guarantees overlap, critical now that the early bar is 8 not 15).
- `question.service.getAvailableQuestions` (onboarding context) returns the 8 `isOnboarding` questions in a fixed order; answering is **voice or text** (already supported — voice answers transcribe async).
- The onboarding set counts toward `questionsAnswered` and feeds the reveal.

---

## 6. The reveal + the "Deepen" engine

### 6.1 Personality reveal (after the 8)
- The GPT-4o analysis is generated when the 8 onboarding answers are in. **Adjust `MILESTONES`** in `src/services/personality.service.js` so the first (preliminary) analysis fires at **8** (currently 6); keep later milestones (15, 20, …) for the deepening report.
- New iOS **Reveal screen** (Cinematic Dark, "The Clearing"-style): the archetype (see §7), 3 signature traits, a warm one-line read, then the pull — **"N people near you match your vibe →"** (N from a discover count for this user). Tapping enters preview/browse.

### 6.2 "Deepen your profile" — ongoing questions (Question Progress redesign)
The current `QuestionsProgressView` becomes a **confidence engine**:
- A prominent **match-confidence ring** (0–100%) that climbs as you answer ("answer 6 more to reach 70%"). Confidence is a simple, documented function of answers + dimension coverage (e.g., `min(100, round(answeredAcrossDimensions / targetCoverage * 100))` — define the exact formula in the plan; it must be monotonic and feel rewarding, not punitive).
- **Per-dimension coverage** rows (answered/available per dimension, thin coral bars) so users see what's thin.
- A single coral **"Answer more"** CTA → the question flow.
- **Unlock cadence:** keep the **light daily drip** (new questions unlock by `dayAvailable` = a reason to return), but **within what's unlocked, users may answer unlimited** in one sitting. (No change to the drip mechanic; the redesign just surfaces the full unlocked pool + the meter.)

### 6.3 Daily nudge
A gentle, cinematic daily prompt pulling users back to deepen — surfaced on Home (the existing daily-question band, recontextualized) and via the existing daily push (`questions_reminder`). Copy frames it as "a new question to sharpen your matches," not a chore. (Reuses existing cron/notification infra; no new endpoint.)

---

## 7. Personality archetypes (the "Coded & Rare" type)

To make "Your type" feel like a collectible identity (treatment A — type number + rarity %), constrain the AI to a **fixed catalog**:

- **Define a fixed catalog of ~12–16 archetypes** (e.g., "The Gentle Adventurer"), each with: a stable `code` (Type 01…16), a name, a short essence line, and the trait signature that maps to it. Store as a constant/seed (`src/utils/archetypes.js` or a collection).
- The GPT-4o personality analysis is changed to **classify the user into one catalog archetype** (return the `code`) rather than inventing a free-form name. (Prompt + response schema update in `personality.service.js`; keep the 7-facet scores + summary + numerology as-is.)
- **Rarity %** = share of analyzed users with that archetype, from a **cached aggregate** (a periodic count of users per archetype, e.g. a daily cron or an incrementally-maintained counter). Exposed on the personality response as `rarityPercent`.
- **Fallback / scope dial:** if the rarity aggregate is deemed too much for v1, ship the catalog + code + essence (the "Type 07" coding and the comparable/shareable archetype) and **omit the live rarity %** (or show a static band). The catalog itself is the load-bearing part; rarity is the cherry. *(Founder to confirm scope at review.)*

### Personality Insights redesign (`PersonalityReportView`)
- **Lead with the archetype** in the "Coded & Rare" treatment: `TYPE 07` + `9% RARE` + the name (light-weight) + essence line + coral rule.
- Then the **radar** (already tonal coral from the Cinematic sweep), then **animated facet bars** (the 7 facet scores, thin coral bars), the AI prose one tap deeper, numerology quiet below.
- A **"Share card"** that renders the archetype + radar (+ rarity) into a shareable image (UIImage → share sheet). Virality hook. (Frontend-only; renders from existing data.)

---

## 8. Browse-in-preview + the Connect gate

- **Discover (preview mode):** a `preview` user can fetch candidates and browse the blurred, voice-first deck read-only. The Connect button is visible; tapping it when not `ready` opens **connect-setup** (record voice → add 3 photos), shows progress, and on completion flips to `ready`, sends the pending like, and continues into the normal match flow. A persistent, quiet "complete your profile to connect" banner sits in preview.
- **Backend:**
  - `discover.getCandidates` — allow `preview` requesters (they browse; candidates are still only `profileStage: 'ready'`, so preview users aren't surfaced to others — already true).
  - `discover.likeUser` (Connect) — **gate the requester on `ready`**; if `preview`, return a typed `409`/`422` ("complete_setup_required") the app catches to launch connect-setup. (No silent fail.)
- **iOS:** `RootView` entry gate enters the app at `preview` (8 onboarding answers), not the old 6; onboarding container reordered (basic info → 8 questions → Reveal → app); connect-setup flow reuses the existing voice/photo screens, recontextualized as "add these to start connecting."

---

## 9. Profile fixes & polish

### 9.1 Set-Main bug (backend) — *real defect*
`profile.service._rebuildProfilePhotoFromGalleryItem` re-processes the chosen main photo by `fetch(item.url)` on a **stored S3 *presigned* URL that expires (~1h)** → 403 → "Could not fetch selected photo for profile processing" when setting main on an older photo. **Fix:** re-fetch the original image via the **authenticated S3 client using the stored `s3Key`** (`GetObject`), not the expiring presigned URL. (Gallery items already store `s3Key`.) Apply wherever a stored photo is re-processed.

### 9.2 Voice-intro progress bar (iOS)
`RemoteAudioPlayer` exposes only `isPlaying`/`currentURL` — no position. **Add** an AVPlayer periodic time observer exposing `elapsed`/`duration`/`progress (0…1)` (observable). **`VoiceLine`** gains a `progress: Double` and renders real progress (reuse `HairlineProgress` for the middle line) + elapsed/duration text. Used in ProfileView + VoiceReRecordView + anywhere VoiceLine plays.

### 9.3 My Answers — voice playback + transcript (iOS)
For answers given by **voice**, `MyAnswersView` shows a **`VoiceLine` to play the recording** plus the **full transcript** text (both already stored server-side — voice answers transcribe async). Text answers unchanged.

### 9.4 Photo reorder clarity (iOS)
The ← / → buttons (move photo earlier/later) are unlabeled and cryptic. Add **accessibility labels** ("Move earlier"/"Move later") and a small visual affordance/caption so the reorder action reads clearly. (Behavior unchanged — `movePhoto(from:by:)`.)

### 9.5 Badges → trophy shelf (iOS)
Redesign `BadgesView` from a text list to a **grid of progress-ring medallions**: earned = full coral ring + a thin glyph (custom/SF symbol, **no emoji**), in-progress = partial ring with the count, locked = dim ring. An overall **"7 of 14" arc** and a **"closest to earning"** nudge. (Uses existing badge catalog/earned data.)

---

## 10. Out of scope / preserved
- The earn-the-reveal **comfort mechanic, photo blur until comfort 70, games, chat, trust-safety, dates** — all unchanged (this changes *when* you provide voice/photos, not the reveal mechanic).
- The 8 dimensions, compatibility engine, daily-question **content** — unchanged; only *which* questions are the fixed onboarding set, *when* milestones fire, and *how* progress is surfaced.
- No monetization, no new push types (reuses existing crons/notifications).
- Real-user migration is trivial (no users yet) — clean cutover + question reseed acceptable.

## 11. Success criteria
- A new user reaches the **personality reveal in ~3 minutes** (8 quick questions), before any voice/photo demand.
- Voice + photos are only required at **Connect**, and completing them makes the user `ready` (discoverable + connectable) — no 15-answer wall.
- Every user answers the **same 8** onboarding questions (compatibility overlap guaranteed).
- The "Deepen" engine shows a **rising match-confidence meter**; a daily nudge brings users back.
- "Your type" reads as a **coded, rare archetype** with a shareable card.
- Set-Main works on any photo; voice intro shows real progress; My Answers plays voice + shows transcript; Badges is a visual shelf.
- No regressions; builds green; ships to TestFlight (build 14).

## 12. Component / file impact (high level)
| Area | Backend | iOS |
|---|---|---|
| Stages | profile.service / question.service stage transitions (+`preview`); discover requester gate | RootView entry gate; onboarding reorder; connect-setup flow; preview banner |
| Questions | `Question.isOnboarding` + seed 8; getAvailableQuestions (onboarding context) | Reveal screen; QuestionsProgress→confidence engine; daily nudge surface |
| Personality | archetype catalog + classify in personality.service; rarity aggregate | PersonalityReport redesign (Coded&Rare + radar + facet bars + Share card) |
| Profile fixes | set-main re-process from s3Key | RemoteAudioPlayer progress; VoiceLine progress; MyAnswers voice+transcript; photo-reorder labels; Badges trophy shelf |
