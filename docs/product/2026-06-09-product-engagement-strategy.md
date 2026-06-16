# UnMutee — Product & Engagement Strategy (CPO Analysis)

> **Date:** 2026-06-09
> **Author:** CPO (Claude) for Nirpeksh
> **Status:** Analysis — for review & prioritization
> **Scope:** Full reassessment of features, flows, and engagement/retention mechanics, grounded in the actual codebase (frontend + backend). Goal: make UnMutee *unmissable* — engaging, retaining, habit-forming.

---

## 1. Executive Summary

UnMutee has a **genuinely differentiated thesis** ("personality before pixels", earn-the-photo-reveal) and a **surprisingly deep engagement engine already built** — a daily question loop, a comfort-score gate, streaks, personality reports, live games, seasonal content, "boops", and date-readiness scoring. Very few pre-launch dating apps have this much mechanism.

**The problem is not missing features — it's that the core emotional loop has breaks that stop the magic from landing.** Three of them are severe and cheap to fix:

1. **The match payoff is a dead-end.** When two people match — the single biggest dopamine moment in any dating app — the "Start Talking" button does nothing (`MatchCelebrationView.swift:82` → `// TODO: Navigate to chat`). The user has to dismiss, hunt through tabs, and find the conversation. The peak moment leaks.
2. **The signature mechanic is invisible.** The whole product promise is "earn the reveal" via a comfort score that must hit 70. But users **never see the comfort score build** or what moves it. The defining experience is a hidden backend number.
3. **Activation is a 15–18 minute gauntlet** before a user sees a single other human, with a confusing "answered 6 → enter app but still not ready" limbo, and a hard dead-end if fewer than 6 questions are unlocked that day.

**Strategy in one line:** *Don't add features yet — make the emotional beats of the existing loop actually land: fast activation → instant match-to-chat → a visible, suspenseful "earning the reveal" → reveal as a celebrated milestone → daily habit hooks that are surfaced and rewarded.*

---

## 2. Product Thesis & Positioning

**What it is:** A compatibility-first dating app where you match on a 60+ question personality engine, talk with photos blurred, and **earn** the photo reveal by building a real connection (comfort score ≥ 70). Anti-swipe, anti-superficial, safety-forward — well suited to the Indian market and to women's intent/safety concerns.

**The wedge:** Every mainstream app optimizes for fast, photo-led judgment. UnMutee inverts it: *substance first, looks last, earned not given.* That is a real, defensible identity — **if** the product makes that inversion feel exciting rather than slow.

**The risk in the thesis:** "Slow" can read as "boring/effortful." The entire job of the product is to make the slow build feel like rising tension and payoff (like a good show), not like homework. Right now the build-up is invisible and the payoffs are muted — so the thesis is under-delivered, not wrong.

---

## 3. Current State — Feature Inventory & Maturity

| Feature | Engagement role | Maturity |
|---|---|---|
| Compatibility engine (8 dimensions, weighted) | Match quality | ✅ Shipped, sophisticated |
| Daily question loop (unlock by `dayAvailable`, 10 days + seasonal) | Daily return habit | ✅ Shipped |
| Personality reports (GPT-4o, milestones 6/15/20…60) | Self-insight hook | 🟡 Shipped but **buried** (Profile-only, no nudge to view) |
| Comfort score → photo reveal gate (≥70) | The signature mechanic | 🔴 Backend-only — **invisible to users** |
| Match progression (mutual→connecting→reveal_ready→revealed→dating) | Relationship arc | 🟡 Works but **opaque** (unclear rules, no status feedback) |
| Match celebration | The payoff moment | 🔴 **Dead-end** — "Start Talking" unwired |
| Chat + voice + reactions | Core conversation | ✅ Shipped (but cold — no previews, no warm-up) |
| Live games (7 types, synced rounds) | Bonding + comfort fuel | 🟡 Shipped but **buried in match detail** |
| Streaks (per-match, 7/30-day badges) | Habit / loss-aversion | 🟡 Tiny UI; streak-milestone notification **unwired** |
| Badges (6 categories) | Achievement | 🔴 3+ taps deep; `badge_earned` notification **unwired** |
| Seasons (6 windows/yr) | Recurring novelty | 🟡 Banner exists but **taps go nowhere** |
| "Boop"/nudge (4h cooldown) | Low-friction re-engage | ✅ Shipped (low prominence) |
| Date planning + readiness score (≥70) + safety | Real-world conversion | 🟡 Gated, **no calendar integration**, model partly unwired |
| Daily push cadence (9am digest / 11am questions / 6pm nudges / midnight reset) | Re-engagement | ✅ Shipped — strong bones |

**Read:** The bones are excellent. The failures are almost all **"last-mile" — surfacing, wiring, and feedback** — not missing systems. That's good news: high impact, low effort.

---

## 4. The User Journey, Mapped (intended arc vs. where it breaks)

```
INSTALL → Onboard → ACTIVATE → Daily loop → Discover → MATCH → Chat → Comfort builds → REVEAL → Dating
```

| Stage | Intended beat | Reality / break |
|---|---|---|
| Onboard | "Quick, intriguing setup" | **15–18 min**, mandatory voice intro, photos, 6+ questions before *any* person is seen |
| Activate | "I'm in, show me people" | Enters app at 6 answers but stuck `questions_pending`; **no progress to 'ready' shown**; dead-end if <6 questions unlocked today |
| Daily loop | "A reason to open today" | Strong cron pushes + home "X liked you" hook ✅ — but no streak-at-risk urgency, seasons dead-end |
| Discover | "Curated, substance-first" | Good card UX, AI openers ✅ |
| **Match** | **The payoff** | 🔴 **"Start Talking" does nothing** — momentum lost |
| Chat | "Warm, easy first message" | Cold inbox, no previews, games hidden |
| **Comfort → Reveal** | **The signature suspense** | 🔴 **Comfort score invisible**; reveal-request status opaque; no notification when the other person requests |
| Reveal | "Celebrated milestone" | Photos just un-blur; no moment |
| Dating | "Plan a real date safely" | Good, but gated at readiness ≥70 with no signposting; no calendar add |

**The arc is sound; the climaxes are muted or broken.**

---

## 5. Engagement & Retention Teardown

### Loops that already exist (and mostly work)
- **Daily question loop:** new questions unlock at midnight IST; 11am reminder; feeds compatibility + personality. Good habit engine.
- **Comfort → reveal loop:** chat/voice/games raise a 0–100 score; 70 unlocks the reveal; blur decreases by tier (30→20→10→clear). *Brilliant design — but unseen.*
- **Streak loop:** per-match daily activity; resets after 2 days idle; 6pm "don't break your streak" push. Loss-aversion engine — but the UI is a tiny flame.
- **Match progression loop:** staged relationship with gates. Gives a sense of "leveling up" — if it's legible.

### What's working ✅
- Real daily push architecture (4 touchpoints/day, segmented by state).
- Home "daily summary" hook ("X people liked you", "X new questions").
- The comfort/blur design itself is a category-defining idea.
- Genuinely high-effort content (questions, games, personality) that competitors lack.

### The breaks & gaps 🔴 (grounded in code)
1. **Match → chat dead-end** — `MatchCelebrationView.swift:82`.
2. **Comfort score invisible** — computed in `comfort.service.js` (factors/weights known), never surfaced as a build-up; users can't see what raises it.
3. **Reveal status opaque** — no notification when the *other* user requests reveal; "X of 2 requests" with no nudge.
4. **Onboarding limbo** — `RootView.swift:72` lets users in at 6 answers but leaves them `questions_pending` with no path/progress shown; question batching can hard-block activation.
5. **No "profile is ready / your search is live" moment** — the activation win is silent.
6. **Unwired retention notifications** — `streak_milestone` and `badge_earned` types exist but aren't fired; badges/streaks earned in silence.
7. **Buried surfaces** — badges 3+ taps deep, personality report Profile-only, games inside match detail, seasons banner dead-ends.
8. **Cold chat** — no message previews in inbox, no first-message warm-up, game invites not surfaced.

### Drop-off map (estimated)
| Transition | Risk | Cause |
|---|---|---|
| Install → Ready | **High** | 15–18 min onboarding, voice mandate, question limbo |
| Match → first message | **Very high** | dead-end celebration |
| Connecting → reveal | **High** | invisible comfort progress, opaque reveal |
| Day 1 → Day 7 | **High** | habit hooks buried/unwired; no streak urgency surfaced |

---

## 6. The Core Problems (synthesis)

- **P1 — Activation friction.** Too long, too much, too confusing before the first human. Kills Day-0.
- **P2 — Broken payoff.** The match moment leaks; the reward isn't delivered.
- **P3 — Invisible signature mechanic.** "Earn the reveal" is the brand — and it's a hidden number. No suspense, no agency, no payoff.
- **P4 — Buried/unwired habit hooks.** Streaks, badges, personality, games, seasons exist but don't compound into a habit.
- **P5 — No "why open today" urgency** for returning users beyond "X liked you."

---

## 7. Strategy — How UnMutee Becomes Unmissable

**Principle: make the emotional beats land.** A dating app is an *emotional* product; UnMutee already has the rare mechanics — it just isn't *staging* them. Four moves:

1. **Get to the first human fast** (activation), then let depth accrue *after* the hook is set.
2. **Never leak a peak** — match, reveal, "you're ready", streak milestones, badges = celebrated, immediate, in-context moments.
3. **Make "earning the reveal" the hero experience** — a visible, suspenseful, two-person progress bar with clear "do this to get closer" actions. This is the product's whole identity; it must be the most visible thing in a conversation.
4. **Surface the habit loops** — streaks, daily questions, games, and a single daily ritual that gives an unmissable reason to open.

---

## 8. Prioritized Roadmap (impact / effort)

### Phase 0 — Fix the broken loop (P0 · days · mostly wiring)
*Highest ROI in the whole product. Almost all low-effort.*

| # | Fix | Impact | Effort |
|---|---|---|---|
| 0.1 | **Match → chat:** wire "Start Talking" to open the conversation (kill the TODO) | 🔥🔥🔥 | XS |
| 0.2 | **Reveal notifications + status:** push when the other user requests reveal; clear "1 of 2 → revealed!" states | 🔥🔥🔥 | S |
| 0.3 | **"You're ready!" moment:** celebrate reaching `ready`; "Your match search is live" | 🔥🔥 | XS |
| 0.4 | **Onboarding limbo fix:** show progress to 15; never hard-block — always allow continuing; fix "<6 questions today" dead-end | 🔥🔥🔥 | S |
| 0.5 | **Wire `streak_milestone` + `badge_earned` notifications** (types already exist) | 🔥🔥 | XS |

### Phase 1 — Make the signature mechanic shine (P1 · 1–2 wks)

| # | Build | Impact | Effort |
|---|---|---|---|
| 1.1 | **Comfort-to-Reveal hero UI:** a prominent, suspenseful two-person progress meter in every conversation, with "do X to get closer" prompts (send voice, play a game, go deeper) | 🔥🔥🔥 | M |
| 1.2 | **Reveal as a celebrated milestone:** synchronized reveal animation/moment, not a silent un-blur | 🔥🔥 | S |
| 1.3 | **Surface games + active game state in chat** (the fastest comfort-builder) | 🔥🔥 | S–M |
| 1.4 | **Make compatibility legible in-chat** ("why you're 84% — your top 3 alignments") | 🔥 | S |

### Phase 2 — Build the daily habit (P1/P2 · 2–4 wks)

| # | Build | Impact | Effort |
|---|---|---|---|
| 2.1 | **A daily ritual** — one unmissable "open me" surface (e.g., a daily question/prompt for you *and* your matches to answer and compare) | 🔥🔥🔥 | M |
| 2.2 | **Surface streaks prominently** + at-risk countdown ("🔥7 ends in 4h") | 🔥🔥 | S |
| 2.3 | **Promote personality report** as a shareable, evolving artifact (re-engage at each milestone) | 🔥🔥 | M |
| 2.4 | **Chat inbox warmth:** previews, conversation starters surfaced, game invites at tab level | 🔥 | S |
| 2.5 | **Seasons:** make the banner do something (themed questions/games/limited rewards) | 🔥 | S |

### Phase 3 — New engagement bets (P2+ · explore later)
- Shareable "compatibility card" for virality. • Voice-first prompts. • "Date readiness" coaching. • Calendar integration for dates. • Audio rooms / weekly events. *(Design individually after Phase 0–2 lands.)*

---

## 9. North-Star & Metrics (instrument first — there's almost none today)

**Proposed North Star:** **Weekly Connecting Conversations** — # of matches where *both* people exchanged messages in the last 7 days. It captures the whole thesis (matched → actually talking → building toward reveal), better than installs or matches alone.

**Input/funnel metrics to instrument (none exist yet — build this before optimizing):**
- **Activation:** install → profile `ready` % ; time-to-ready ; drop-off per onboarding step.
- **Core loop:** match → first message % (this will expose the 0.1 bug) ; conversations reaching comfort 70 % ; reveals completed ; dates planned.
- **Retention:** D1/D7/D30 ; streak-active rate ; daily question completion ; DAU/WAU.
- **Counter-metrics:** report/block rate, one-sided conversation rate.

Without this instrumentation we're optimizing blind — **a lightweight analytics layer is itself a Phase 0 item.**

---

## 10. What I'd Build First (recommendation)

**Do Phase 0 immediately** — it's days of work, mostly wiring already-built systems, and it repairs the two worst leaks (match payoff, activation) plus makes retention notifications real. Then **Phase 1.1 (the Comfort-to-Reveal hero UI)** because it makes the product's *signature promise* finally visible — that's what turns "a slow dating app" into "the app where the build-up is the fun."

Concretely, my top 5:
1. Match → chat (0.1)
2. Comfort-to-Reveal hero UI + reveal moment (1.1 + 1.2)
3. Onboarding limbo fix + "you're ready" moment (0.4 + 0.3)
4. Reveal notifications/status (0.2)
5. Lightweight analytics instrumentation (so we can see the funnel)

---

## 11. Open Questions / Decisions for Founder
- **Onboarding philosophy:** keep depth-first (15 questions before discover) or flip to "see people fast, deepen after"? (I lean: let them browse/preview sooner, gate *connecting* on depth.)
- **North-star agreement:** is "weekly connecting conversations" the right success definition, or do you prefer "first dates planned"?
- **Analytics:** OK to add a lightweight analytics SDK (e.g., PostHog/Amplitude) so we stop flying blind?
- **Scope of first sprint:** all of Phase 0, or Phase 0 + the Comfort-to-Reveal hero?
