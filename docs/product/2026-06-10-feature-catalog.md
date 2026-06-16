# UnMutee — Feature Catalog

> **Date:** 2026-06-10
> A plain-English guide to every feature on the platform: what it does, how it works, and why it matters.

**The idea in one line:** UnMutee is a dating app where you match on *personality first* and **earn the photo reveal** by actually building a connection — the opposite of swipe-on-looks apps.

---

## 1. Getting in & setting up

### Phone sign-in (OTP)
- **What:** Sign up / log in with your phone number + a 6-digit code.
- **How:** Enter number → receive an SMS code (Twilio) → verified. No passwords.
- **Why:** Fast, low-friction, and ties each account to a real phone (cuts fakes/bots).

### Voice intro
- **What:** A short recorded voice clip on your profile (10–60s).
- **How:** Record in-app; it's stored securely and auto-transcribed.
- **Why:** Voice conveys warmth and personality that photos can't — and it's central to the "hear before you see" promise.

### Photos (held back, not hidden)
- **What:** You upload real photos, but others see them **blurred/silhouetted** until the connection is earned.
- **How:** Up to 6 photos; the app serves blurred versions and only un-blurs after the reveal milestone.
- **Why:** Keeps first impressions about *substance*, not looks — the core differentiator.

### Personality questions (the heart of the profile)
- **What:** A growing set of thoughtful questions across **8 personality dimensions** (emotional vulnerability, attachment, life vision, conflict resolution, love expression, intimacy comfort, lifestyle rhythm, growth mindset). You answer 15+ to go "live."
- **How:** Answer by text *or* voice. New questions unlock daily over your first ~10 days (plus seasonal ones). Each answer feeds your match algorithm.
- **Why:** This is the data that powers real compatibility — and answering daily is a built-in reason to come back.

---

## 2. Understanding people (the AI layer)

### Personality Report
- **What:** An AI-generated read on who you are — 7 facets (emotional style, communication, love language, conflict approach, lifestyle, growth, social energy) + a numerology touch, shown as a radar chart.
- **How:** After milestones (6, 15, 20… answers), GPT-4o analyzes all your answers and produces the report.
- **Why:** People love insight about themselves — it's a delight/share hook *and* it makes the app feel intelligent.

### Compatibility Engine
- **What:** A 0–100 compatibility score + a tier (**Platinum / Gold / Silver / Bronze**) for every potential match, with a per-dimension breakdown.
- **How:** Compares your answers to theirs across the 8 dimensions (exact-match, overlap, and AI text-similarity), weighted into one score.
- **Why:** Surfaces genuinely compatible people instead of random faces — the quality bet that makes the slow approach worth it.

---

## 3. Finding & matching

### Discover
- **What:** A daily, curated set of compatible people — shown by their voice, answers, and *why you fit* (not a face-first swipe deck).
- **How:** One profile card at a time; **Connect** or **Skip**. A small daily limit keeps it intentional.
- **Why:** Quality over volume; you evaluate people on who they are.

### Connect with a note (+ AI openers)
- **What:** When you like someone, you can add a personal note; the app can suggest opening lines.
- **How:** Optional note (text); AI suggests context-aware icebreakers you can tap to use.
- **Why:** Higher-quality first contact = better reply rates and warmer starts.

### Matching
- **What:** When two people both Connect, it's a match — and a conversation is created instantly.
- **How:** Mutual like → match created → you're dropped straight into the chat ("Start Talking").
- **Why:** Captures the excitement at its peak and turns it into an actual conversation.

---

## 4. Building the connection

### Match stages
- **What:** Every connection progresses through stages: **Mutual → Connecting → Reveal-ready → Revealed → Dating → Archived.**
- **How:** Stages advance as you interact (and at the reveal/date milestones), giving a sense of "leveling up" a relationship.
- **Why:** Makes progress visible and gives the relationship a satisfying arc.

### Chat
- **What:** Real-time messaging — text, **voice notes**, images, emoji reactions, and replies.
- **How:** Live (websockets); photos/voice stored securely; offline users get push notifications.
- **Why:** The place the actual connection happens; voice notes deepen it faster.

### Comfort Score → Photo Reveal *(the signature mechanic)*
- **What:** A 0–100 "closeness" score per connection. At **70**, you both unlock the ability to reveal photos.
- **How:** The score rises from real engagement — message depth, voice notes, games played, consistency over days, balanced back-and-forth, and "vulnerability" signals. Photos get progressively less blurry as it climbs, then clear at reveal (both people request it).
- **Why:** This *is* UnMutee — the looks reveal is **earned together**, which builds trust and makes the reveal an emotional payoff instead of a swipe.

### Relationship Insights (AI)
- **What:** An AI summary of your connection — strengths, growth areas, communication style, next steps.
- **How:** GPT-4o analyzes your compatibility + interaction and writes a personalized read.
- **Why:** Coaches the connection forward and reinforces "this app understands us."

---

## 5. Games — playful bonding *(and the fastest way to grow comfort)*

**How games work (all of them):** One person invites the other in the chat. Both tap "ready," see a **3-2-1 countdown**, then answer the round **at the same time** — answers reveal together. Each game is **5 rounds**; some have a cooldown before you can replay. Completed games boost the Comfort Score (they're a strong signal of real engagement).

| Game | What you do | Why it matters |
|---|---|---|
| **Would You Rather** | Pick between two fun/revealing options each round (30s) | Light, low-pressure way to break the ice and learn preferences |
| **Two Truths & A Lie** | Each shares 3 statements; the other guesses the lie (60s) | Playful deduction that surfaces real stories about each other |
| **Never Have I Ever** | React to "never have I ever…" prompts (30s) | Reveals experiences & boundaries in a safe, gamified way |
| **What Would You Do** | Respond to real relationship scenarios (60s) | Tests values & decision-making — how someone *actually* thinks |
| **Intimacy Spectrum** | Rate emotional/physical/values prompts on a 1–10 scale (30s) | Gently calibrates comfort & closeness without pressure |
| **Dream Board** | Share visions of the future, lifestyle, goals (60s) | Aligns on long-term direction — are you heading the same way? |
| **Blind Reveal** | Answer a prompt, then a follow-up reveal unlocks (60s) | Builds curiosity & gradual vulnerability — the "unwrapping" feeling |

**The benefit of games overall:** they make building a connection *fun* (not work), accelerate trust, and feed the comfort score toward the reveal — turning the app's "slow" model into something enjoyable.

---

## 6. Taking it to real life

### Date Readiness Score
- **What:** A 0–100 signal of whether you're both ready to meet (ready at ~70).
- **How:** Blends compatibility, engagement, mutual interest, and "red-flag" checks (e.g., one-sided or inactive).
- **Why:** Nudges people to meet at the *right* time — not too early, not stalled forever.

### Date Planning + Safety
- **What:** Propose a date in-app (venue, time), with safety built in.
- **How:** AI venue suggestions; set an **emergency safety contact**, share **live location**, and do **check-ins** during the date.
- **Why:** Lowers the friction and the fear of meeting a stranger — especially important for women's safety and trust.

---

## 7. Habit, delight & re-engagement

### Streaks
- **What:** A daily 🔥 streak per connection for consecutive days you chat.
- **How:** Increments each day you message; resets after inactivity; you get reminded before it breaks.
- **Why:** Loss-aversion that keeps conversations alive day to day.

### Badges
- **What:** Achievements for milestones (voice verified, question pioneer, game enthusiast, streak keeper, etc.).
- **How:** Auto-awarded as you hit conditions; you get a notification.
- **Why:** Rewards the behaviors that make connections work.

### Boop (nudge)
- **What:** A one-tap "thinking of you" poke to a match.
- **How:** Sends a friendly push (rate-limited to once every few hours).
- **Why:** A zero-pressure way to revive a quiet conversation.

### Seasons
- **What:** Themed content windows (Valentine's, Holi, Diwali, etc.).
- **How:** Special seasonal questions/prompts appear during the window.
- **Why:** Fresh novelty that drives repeat opens around moments that matter.

### Smart notifications
- **What:** Timely nudges — new matches, messages, daily question reminder, streak warnings, morning digest.
- **How:** Push notifications on a daily cadence, with **quiet hours** you control.
- **Why:** Brings people back at the right moments without being spammy.

---

## 8. Beyond the app

### Home-screen Widget
- **What:** An at-a-glance widget showing connections / newest matches.
- **How:** iOS widget synced from the app.
- **Why:** Keeps UnMutee present on the home screen — a gentle pull back in.

### App Clip
- **What:** A lightweight preview that can open a profile without installing the full app.
- **How:** Opens via a link to a profile preview, then invites a full install. *(Note: needs a small domain setup step before it can be invoked in the wild.)*
- **Why:** Lowers the barrier to sharing/inviting people in.

---

## In short
UnMutee already has the full arc of a serious dating product: **understand you → match you well → help you build a real connection → earn the reveal → meet safely → keep you coming back.** The games and the comfort-score-to-reveal mechanic are the distinctive parts — they make the "personality first" promise actually *fun* and emotionally rewarding.
