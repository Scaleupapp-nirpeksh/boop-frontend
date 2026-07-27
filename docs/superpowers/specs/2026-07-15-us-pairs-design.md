# "Us" — Explore Compatibility With People You Already Know

**Date:** 2026-07-15
**Status:** Draft for review
**Authors:** Nirpeksh, Pratiksha (with Claude)
**Scope:** boop-backend + boop-frontend. Reuses the existing Match/Game/Chemistry machinery.

---

## 1. Concept & Strategy

UnMutee today only serves strangers meeting through Discover. **"Us"** lets two people who already know each other (a crush, someone you just met IRL, a situationship, an established couple) explore their compatibility together — games, "How you play" chemistry, "How you two answer," a compatibility vibe — **without the discovery/reveal sequence** (they know each other's faces; there is nothing to reveal).

**Why it matters (founder view):**
- **Viral loop:** every invite recruits a new user through a personal, high-intent channel ("I want to play this with you"). Cheapest acquisition available to a 2-founder team.
- **Second market:** couples-deepening apps (Paired etc.) prove people pay for exactly this. For UnMutee it is a *reuse project* — the questions, games, answer-sync and chemistry engine already exist.
- **Brand-safe:** "Personality before pixels" flips, doesn't break: faces are known, answers aren't.

**Decisions locked (founders, 2026-07-15):**

| Decision | Choice |
|---|---|
| Audience | One flexible mode for BOTH pre-dating (crush/just met) and couples |
| Dating pool | Independent & user-controlled: a person can have pairs AND date normally; pair-only users are invisible in Discover unless they opt in |
| Multiplicity | **Multiple pairs per person** (one Match per pair); each invite code pairs with exactly one person |
| Invite mechanism | **6-character pair code** at launch (share-links later) |
| Name | **"Us"** |

---

## 2. Non-Goals (v1)

- No share-links / universal links (code only; links are a later upgrade).
- No group compatibility (pairs only, but many of them).
- No separate "couple questions" content pack (reuse the existing 60 + daily questions; a dedicated pack is a future monetisation hook).
- No changes to the dating pipeline (stages, comfort, reveal) for discover-origin matches.
- No web experience.

---

## 3. Core Mechanics

### 3.1 Pair formation
1. Any user opens **Us → "Invite someone you know"** → gets a **pair code** (6 chars, unambiguous alphabet, e.g. `ROSE42`) + share sheet with a prefilled message and App Store link.
2. The other person redeems the code:
   - **Existing user:** Us → "Have a code?" → enter → paired.
   - **New user:** Welcome screen gains "Have a pair code?" → phone OTP signup → minimal onboarding (name, DOB/18+ gate, gender optional) → paired → then a fork: *"Also want to meet new people on UnMutee?"* → **Yes** → continue the normal dating onboarding later; **Not now** → lands in Us as a pair-only account.
3. Redemption creates a **`Match` with `origin: "pair"`** + a Conversation — chat, all 7 games, game-chemistry and answer-sync work immediately because they all hang off `matchId`.

### 3.2 Pair invite rules
- Code: 6 chars from `A-Z2-9` minus lookalikes (no 0/O/1/I); unique; expires in **7 days**; single redemption.
- Max **5 active codes** per user (rate limit); codes revocable.
- Guards: cannot redeem your own code; blocked users cannot pair (generic "code isn't valid" — never reveals a block); 18+ enforced for everyone.

### 3.2.1 Redemption when the two are already connected (decided)
- **Already matched, not yet revealed:** the existing match **auto-reveals and merges** — photos unlock, all history (chat, games, comfort) is kept, and the connection gains the Us view. Celebration moment: *"You found each other twice ✨"*. No duplicate match (unique `pairKey`).
- **Already matched and revealed/dating:** no state change; warm "you two are already connected" cheer pointing at the existing connection.
- **Previously ended pair (archived):** a fresh code **reactivates** the archived match as a fresh start (pairKey blocks creating a second one).
- **Both on the app, never matched:** normal pair creation — and paired people are **excluded from each other's Discover** (new exclusion: anyone you share an active Match with, any origin, never appears in your candidates).

### 3.3 Account modes & the dating pool
- New field `User.discoverable: Boolean` (default `true` for normal signups, `false` for pair-only signups).
- Discover's `getCandidates` additionally filters `discoverable: true`.
- Settings gains **"Show me in Discover"** — enabling it requires completing the dating profile (photos, voice, enough questions); pair-only users can flip it any time.
- New `profileStage` value **`pair_only`**: treated as *complete* for pair-scoped features (chat/games/questions with their pairs) but *not* for Discover. This relaxes `requireCompleteProfile` only where the resource belongs to a pair-origin match — the single trickiest integration point, called out in §6.

### 3.4 What a pair sees (and doesn't)
| Feature | Pairs ("Us") | Dating matches |
|---|---|---|
| Clear photos (no blur) | ✅ always | Only after reveal |
| Chat, voice notes, images | ✅ | ✅ |
| All 7 games + "How you play" chemistry | ✅ | ✅ |
| "How you two answer" (answer-sync) | ✅ | ✅ |
| Compatibility vibe (from answers) | ✅ | ✅ |
| Stages / comfort points / fog / reveal | ❌ hidden | ✅ |
| Boop/streak (already removed) | ❌ | ❌ |
| Block / report / safety | ✅ | ✅ |
| Archive | "End this pair" (with confirmation) | Archive (with confirmation) |

Comfort still computes server-side (harmless); it is simply never displayed for pairs.

---

## 4. Backend Design (boop-backend)

### 4.1 New model: `PairInvite`
```js
{
  code: String (unique, 6 chars),
  createdBy: ObjectId(User),
  status: 'active' | 'redeemed' | 'revoked' | 'expired',
  expiresAt: Date,                  // +7 days
  redeemedBy: ObjectId(User) | null,
  redeemedAt: Date | null,
}
```

### 4.2 Match changes
- `origin: { type: String, enum: ['discover', 'pair'], default: 'discover' }`
- `CONNECTION_STAGES` gains `PAIRED: 'paired'` — pair matches are created at `stage: 'paired'` and never move through the dating stages. Stage-advance/reveal endpoints reject pair matches.

### 4.3 Endpoints
| Route | Purpose |
|---|---|
| `POST /api/v1/pairs/invites` | Create code (rate-limited) |
| `GET /api/v1/pairs/invites` | My active codes |
| `DELETE /api/v1/pairs/invites/:code` | Revoke |
| `POST /api/v1/pairs/redeem` `{code}` | Validate + create pair Match & Conversation; returns matchId + partner preview |
| `GET /api/v1/matches?origin=pair` | Us list (existing endpoint + origin filter; defaults to `discover` so old clients are unaffected) |

### 4.4 Behavioural changes
- `discover.service.getCandidates`: exclude `discoverable: false` users and all pair-origin matches from interactions logic.
- Match list endpoints: default `origin: 'discover'`; pairs returned only when requested.
- `requireCompleteProfile`: accept `profileStage: 'pair_only'` **only** for pair-scoped resources (games/messages/answer-sync on a pair match, question answering, profile basics). Implementation: middleware stays; the few controllers involved check match origin when the caller is `pair_only`.
- Push notifications: "〔Name〕 joined your Us 🎉" on redemption (reuses NotificationService).
- Account deletion already wipes matches/conversations by user — pairs included automatically. `PairInvite` cleanup added to deletion.

---

## 5. iOS Design (boop-frontend)

### 5.1 Entry points
- **Home:** new "Us" section (below Your People): pair cards (photo, name, one warm line) + **"Invite someone you know"** card. Empty state sells the loop: *"Already know someone? See how you two really fit."*
- **Welcome/onboarding:** "Have a pair code?" path → after OTP + minimal profile, redeem → the Yes/Not-now dating fork (§3.1).
- **In-app redemption:** field inside Us for existing users.

### 5.2 The pair page (person-first, trimmed)
Reuses `PartnerProfileView` with a pair variant:
- Hero: **clear** photo (or initial-avatar if none), name, voice intro if present, archetype/essence if they've answered enough.
- "You two": chemistry verdict + "How you play" + "How you two answer" + the playful you-vs-them compare. **No fog, no points, no stages.**
- Actions: Chat · Play Games · How you answer · End this pair (confirm dialog).
- The games hub and 360° next-angle suggestions work unchanged (matchId-based).

### 5.3 Pair-only user experience
- Tab bar unchanged, but Discover shows an invitation to complete the dating profile instead of candidates (with the "Show me in Discover" toggle).
- Me tab: "Come into focus" card copy adapts: *"Every answer sharpens how we show you two fit."* Questions flow identical.

### 5.4 Day-0 experience & page states (decided)

Pairs are almost always **asymmetric at birth** (inviter has 15–60 answers, archetype, photos; invitee usually has zero). Analysis is **instant whenever data exists** (answer-sync and game chemistry compute on-the-fly), so the design problem is the empty/partial states — the pair page is a **state machine**, never a page of empty sections:

| Stage | Trigger | "You Two" shows | Primary CTA |
|---|---|---|---|
| **0 · Day one** | paired, no games, no common answers | "Your story starts here — a quick game sparks your first chemistry" + promise line ("as you both answer daily questions, we'll compare minds too") | **Play your first game** (works with zero history) |
| **1 · First chemistry** | ≥1 game done, few/no common questions | "How you play" verdict + rows; questions section shows warm progress ("2 questions in common so far — grows every day") | keep playing / nudge questions |
| **2 · Full picture** | real question overlap | verdict + per-question sync + you-vs-them compare + firsts | everything |

**Mirrored views:** shared sections (You Two / How you play / How you answer) are identical for both; the person section flips. When the partner is brand-new, their archetype slot reuses the **"coming into focus"** metaphor — blurred merge-orbs + "〔Name〕 has answered 3 questions; their type appears as they share more" — giving the inviter a reason to nudge and the invitee a visible reason to answer. (No fog on photos in Us — focus applies to the *type*, not the face.)

**Joined moment:** redemption push to the inviter ("〔Name〕 joined your Us 🎉"); both see a one-time "You two are paired — day one" ribbon; Us-list cards carry state lines ("New — play your first game" → chemistry verdict once games exist).

**Two existing users pairing:** skip Stage 0 entirely — their question overlap already exists, so "How you two answer" and the compatibility vibe are populated **from the first second**, plus game CTA.

### 5.5 Share message (v1)
> *"I want to see how we actually match 👀 My UnMutee code: ROSE42 — get the app: 〔App Store link〕"*

---

## 6. Risks & Edge Cases
- **Existing-match collision:** resolved by merge/auto-reveal rules in §3.2.1 (never a cold error).
- **`requireCompleteProfile` relaxation** is the highest-risk change — must not accidentally open dating features to pair-only accounts. Mitigation: origin check lives server-side per-resource; add unit tests for every pair-scoped route with a `pair_only` caller.
- **Answer-sync sparsity:** a brand-new invitee has answered nothing → "How you two answer" empty state nudges them to the Me questions ("Answer a few and watch this fill in").
- **Privacy:** pairs never appear in Discover, public profiles, or the dating lists of either person; a pair is visible only to its two members.
- **Abuse & safety:** codes are single-use, expiring, revocable, rate-limited. Blocking inside a pair deactivates it for both instantly (chat closes, disappears from both Us lists). Redemption against a block fails generically. Reports flow through the existing moderation pipeline unchanged.
- **Old app versions:** unaware clients never see pairs (origin filter defaults to `discover`) — no breakage.

## 7. Monetisation hooks (later, noted only)
- Deeper "Us reports" (AI relationship letter, monthly recap) as a premium add-on — the proven Paired-style upsell; slots into the existing IAP plan.

## 8. Build Phases
1. **Backend core:** PairInvite + endpoints, Match.origin/'paired', discover & list filters, `pair_only` completeness, tests.
2. **iOS core:** Us section + invite create/share + redeem (in-app & onboarding fork) + trimmed pair page.
3. **Polish:** redemption push, revoke UI, "Show me in Discover" toggle, share-link upgrade, Us premium hooks.

## 9. Success Metrics (fun, not dashboards — internal only)
Invites created / redeemed (viral coefficient), % redeemers converting to dating opt-in, pair D7 retention vs dating D7.
