# Connection page redesign + "How you answer together"

**Date:** 2026-06-16
**Status:** Approved (design), pending implementation plan
**Surfaces:** `MatchDetailView` (frontend) + new sync-analysis page; supporting backend endpoint(s).

## Problem

The match/connection detail page (`MatchDetailView`) has grown to ~12 stacked sections dense with raw, technical metrics: a 7-factor comfort breakdown ("Active days, Games completed, Message depth/volume, Response consistency, Voice engagement, Vulnerability signals"), a 4-factor readiness breakdown ("Compatibility, Engagement, Mutual interest, Red flags"), a comfort-over-time chart, a per-dimension "Why this could work" card, tips, a stage timeline, AI insights, and next actions. It reads as a technical dashboard — overwhelming and boring, not the warm, human moment it should be. Existing defects: dimension labels render un-humanized (`Activedays`, `Gamescompleted`), and a dimension narrative shows `10000% alignment` (double-percentage bug).

## Goal

Reduce the main page to ~5 calm sections, push the technical detail one tap deeper, and add a new **answer-sync analysis** as the emotional centerpiece — showing, from the questions both people have answered, where they align and where they differ, as **synthesized summaries** (never the other person's exact written answers).

## Information architecture

### Main connection page (`MatchDetailView`) — 5 sections

1. **Hero (unchanged).** Keep exactly as today, including the **`BlurredPortrait` background that reveals as comfort grows** (`FogBlur.radius(forComfort:stage:)`). Contains: stage eyebrow ("CONNECTING"), name + age, city, Voice intro, View profile, Boop button, Day streak. No changes.
2. **Connection stage (kept, redesigned horizontal).** Replace the vertical timeline + separate "Recommended next move" card + reveal buttons with ONE concise block: a **horizontal stepper** (Matched → Connecting → Reveal Ready → Revealed/Dating) with the current step highlighted, a one-line live status, and the primary action (Advance / Request Reveal) attached.
3. **"How you answer together" card (NEW — teaser).** A verdict line ("Mostly in sync"), a mini **sync spectrum** bar, and "N questions you've both answered." Taps into the Sync Analysis page.
4. **"Growth & insights" card (consolidation).** Surfaces Comfort as a single high-level number ("Comfort 15/100 · ↗ +5 this week") + one line. Taps into the Growth & Insights page. This card absorbs what is today the comfort breakdown, readiness breakdown, growth chart, and relationship insights.
5. **Next actions (kept, tightened).** About [person], Open chat, Play games, Archive.

**Removed from the main page** (moved behind taps or deleted): the 7-factor comfort breakdown, the 4-factor readiness breakdown, the comfort growth chart, the generic comfort tips, and the "Why this could work" chemistry card (replaced by the sync analysis; this also removes the `10000%` bug site).

### Sync Analysis page (NEW) — "How you answer"

The star. Based only on questions **both** users have answered (the common set — one person may have answered more; only the intersection counts).

- **Header:** "N questions, both answered" + overall verdict ("Mostly in sync") + the full **sync spectrum** bar (5 segments, widths ∝ bucket counts).
- **5 tappable buckets** with counts. Approved wording (tunable): **Highly in sync · In sync · Neutral ground · Different views · Poles apart.**
- **Tap a bucket →** the questions in that bucket. Each question shows: question text, its category, the sync label, and a **one-line synthesized summary of how each person answered** (YOU + [other]). Never the other person's verbatim answer.
- Optionally, the comfort growth chart may also live at the bottom of this page (decided during planning; default: it lives in Growth & Insights).

### Growth & Insights page (consolidation)

Holds everything technical about how the connection is progressing, framed gently: comfort score + trend, the comfort factor breakdown (humanized labels, not raw camelCase), "what grows comfort" tips, the comfort-over-time growth chart, and the existing AI relationship insights ("Analyze Connection"). Reuses today's `comfortCard`, `readinessCard`, `ScoreProgressView`, and `RelationshipInsightsCard`, relocated here.

### About [person] page (`PartnerProfileView`) — privacy hardening

When opened from "About [name]", show only: **voice intro, personality type (archetype), numerology.** **Never** the other person's exact written answers. Audit the current view and remove/forbid any path that exposes raw answers.

## Data & backend

### Sync computation (reuses existing logic)

`CompatibilityService` already fetches both users' answers and computes per-question similarity (`single_choice` = exact match; `multiple_choice` = Jaccard; `text` = embedding cosine). Reuse this to:

1. Find the common answered `questionNumber` set.
2. Compute per-question similarity (0–1).
3. Bucket each by tunable thresholds, e.g. `≥0.85` Highly in sync · `≥0.6` In sync · `≥0.4` Neutral ground · `≥0.2` Different views · `<0.2` Poles apart. (Note: `single_choice` is binary 1.0/0.0, so those land in the extreme buckets — acceptable; `text`/`multiple_choice` give the gradient.)

### Summaries (LLM, privacy-safe)

For each common question, synthesize a short, neutral one-line summary of **each** person's answer (and the bucket/verdict). Use one **batched** LLM call returning a JSON array for all ~15 questions (OpenAI, same pattern as the existing insights endpoint, with a rule-based fallback). **Cache** per match (invalidate when either user adds an answer). The endpoint returns **only summaries** — never raw `textAnswer` / `selectedOption` for the other user.

### Endpoint

`GET /api/v1/matches/:matchId/answer-sync` →
```
{
  totalCommon: number,
  verdict: string,                 // "Mostly in sync"
  buckets: [{ key, label, count }],
  questions: [{ questionNumber, category, syncLevel, summaryYou, summaryThem }]
}
```
Single endpoint (15 items is small). Privacy enforced server-side: summaries only.

## Defects fixed as part of this work

- Un-humanized dimension labels (`Activedays` → "Active days") wherever a dimension key is shown.
- `10000% alignment` double-percentage — its site (the chemistry card) is removed; ensure any reused dimension-score formatting outputs a sane 0–100%.

## Out of scope

- Changing the comfort/readiness scoring math.
- Changing the reveal/stage state machine.
- The Hero (kept verbatim).

## Open questions (resolve in planning)

- Final bucket thresholds and whether `single_choice` should use a softer mid-bucket.
- Whether the growth chart appears on the Sync page, the Growth page, or both.
- Whether the user's own answers may be shown verbatim (other party never is); default: summaries for both for consistency.
