# Connection Page Redesign + Answer-Sync Analysis — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Declutter the connection detail page to ~5 calm sections and add a new "How you answer together" sync-analysis experience (common questions bucketed by sync level with synthesized per-person summaries, never exact answers).

**Architecture:** New backend `AnswerSyncService` reuses the existing per-question similarity from `CompatibilityService`, buckets each common question by sync level, and adds a batched, cached, privacy-safe LLM summary layer; exposed at `GET /api/v1/matches/:matchId/answer-sync`. The SwiftUI frontend adds an `AnswerSyncView` (consumes the endpoint) and a `GrowthInsightsView` (absorbs the technical comfort/readiness/chart/insights blocks), then trims `MatchDetailView` to Hero → horizontal stage → "How you answer" teaser → "Growth & insights" teaser → Next actions.

**Tech Stack:** Node/Express/Mongoose + Jest (backend); SwiftUI iOS 17, XcodeGen (frontend); OpenAI `gpt-4o-mini` for summaries.

**Spec:** `docs/superpowers/specs/2026-06-16-connection-page-redesign-design.md`

**Repos:** backend `/Users/nirpekshnandan/My Products/boop-backend`, frontend `/Users/nirpekshnandan/My Products/boop-frontend`.

**Prerequisite:** In the backend repo run `npm install` once (devDependencies incl. jest are not currently in `node_modules`).

---

## File structure

**Backend (create):**
- `src/services/answerSync.service.js` — sync computation + bucketing + LLM summaries + cache.
- `tests/unit/answerSync.service.test.js` — unit tests (mocked models/LLM).

**Backend (modify):**
- `src/controllers/match.controller.js` — add `getAnswerSync` handler.
- `src/routes/match.routes.js` — add `GET /:matchId/answer-sync`.

**Frontend (create):**
- `Boop/Features/Matches/Views/AnswerSyncView.swift` — the sync-analysis page.
- `Boop/Features/Matches/ViewModels/AnswerSyncViewModel.swift`.
- `Boop/Features/Matches/Views/GrowthInsightsView.swift` — consolidated comfort/readiness/chart/insights page.
- `Boop/Features/Matches/Views/ConnectionStageStrip.swift` — horizontal stage stepper.

**Frontend (modify):**
- `Boop/Models/InteractionModels.swift` — add `AnswerSyncResponse` + nested types.
- `Boop/Core/Network/APIEndpoint.swift` — add `getAnswerSync(matchId:)`.
- `Boop/Features/Matches/Views/MatchDetailView.swift` — trim to 5 sections; add teasers; move blocks to `GrowthInsightsView`.
- `Boop/Features/Matches/ViewModels/MatchDetailViewModel.swift` — humanize dimension labels; expose a lightweight sync teaser fetch.
- `Boop/Features/Matches/Views/PartnerProfileView.swift` — privacy audit (no written answers).

---

## Phase 1 — Backend: answer-sync service + endpoint

### Task 1.1: Sync computation + bucketing (`AnswerSyncService.computeBuckets`)

**Files:**
- Create: `src/services/answerSync.service.js`
- Test: `tests/unit/answerSync.service.test.js`

- [ ] **Step 1: Write the failing test**

```js
// tests/unit/answerSync.service.test.js
jest.mock('../../src/models/Answer', () => ({ find: jest.fn() }));
jest.mock('../../src/models/Question', () => ({ find: jest.fn() }));

const Answer = require('../../src/models/Answer');
const Question = require('../../src/models/Question');
const AnswerSyncService = require('../../src/services/answerSync.service');

const lean = (docs) => ({ select: () => ({ lean: () => Promise.resolve(docs) }), lean: () => Promise.resolve(docs) });

describe('AnswerSyncService.computeBuckets', () => {
  it('buckets common questions by similarity and ignores non-common ones', async () => {
    Answer.find
      .mockReturnValueOnce(lean([ // user A
        { questionNumber: 1, selectedOption: 'A' },
        { questionNumber: 2, selectedOption: 'A' },
        { questionNumber: 9, selectedOption: 'A' }, // not common
      ]))
      .mockReturnValueOnce(lean([ // user B
        { questionNumber: 1, selectedOption: 'A' }, // exact -> highly_in_sync
        { questionNumber: 2, selectedOption: 'B' }, // mismatch -> poles_apart
      ]));
    Question.find.mockReturnValue({ lean: () => Promise.resolve([
      { questionNumber: 1, questionType: 'single_choice', dimension: 'love_expression' },
      { questionNumber: 2, questionType: 'single_choice', dimension: 'conflict_resolution' },
    ])});

    const res = await AnswerSyncService.computeBuckets('a', 'b');
    expect(res.totalCommon).toBe(2);
    const byLevel = Object.fromEntries(res.questions.map((q) => [q.questionNumber, q.syncLevel]));
    expect(byLevel[1]).toBe('highly_in_sync');
    expect(byLevel[2]).toBe('poles_apart');
    const counts = Object.fromEntries(res.buckets.map((b) => [b.key, b.count]));
    expect(counts.highly_in_sync).toBe(1);
    expect(counts.poles_apart).toBe(1);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run (in backend repo): `npm test -- answerSync`
Expected: FAIL — "Cannot find module '../../src/services/answerSync.service'".

- [ ] **Step 3: Write minimal implementation**

```js
// src/services/answerSync.service.js
const Answer = require('../models/Answer');
const Question = require('../models/Question');
const CompatibilityService = require('./compatibility.service');

// Ordered sync buckets, strongest first. Thresholds tunable.
const BUCKETS = [
  { key: 'highly_in_sync', label: 'Highly in sync', min: 0.85 },
  { key: 'in_sync',        label: 'In sync',        min: 0.6 },
  { key: 'neutral_ground', label: 'Neutral ground', min: 0.4 },
  { key: 'different_views',label: 'Different views', min: 0.2 },
  { key: 'poles_apart',    label: 'Poles apart',     min: -1 },
];

function bucketFor(similarity) {
  return BUCKETS.find((b) => similarity >= b.min) || BUCKETS[BUCKETS.length - 1];
}

class AnswerSyncService {
  /**
   * Compute the per-question sync level for every question BOTH users answered.
   * Pure of LLM — returns questionNumber, dimension, similarity, syncLevel.
   */
  static async computeBuckets(userIdA, userIdB) {
    const [ansA, ansB] = await Promise.all([
      Answer.find({ userId: userIdA }).select('+embedding').lean(),
      Answer.find({ userId: userIdB }).select('+embedding').lean(),
    ]);
    const mapA = new Map(ansA.map((a) => [a.questionNumber, a]));
    const mapB = new Map(ansB.map((a) => [a.questionNumber, a]));
    const common = [...mapA.keys()].filter((qn) => mapB.has(qn));

    const questions = await Question.find({ questionNumber: { $in: common } }).lean();
    const qMap = new Map(questions.map((q) => [q.questionNumber, q]));

    const counts = Object.fromEntries(BUCKETS.map((b) => [b.key, 0]));
    const perQuestion = [];
    for (const qn of common) {
      const q = qMap.get(qn);
      if (!q) continue;
      const sim = CompatibilityService._questionSimilarity(q, mapA.get(qn), mapB.get(qn));
      const bucket = bucketFor(sim);
      counts[bucket.key] += 1;
      perQuestion.push({ questionNumber: qn, dimension: q.dimension, similarity: sim, syncLevel: bucket.key });
    }

    return {
      totalCommon: perQuestion.length,
      buckets: BUCKETS.map((b) => ({ key: b.key, label: b.label, count: counts[b.key] })),
      questions: perQuestion,
    };
  }
}

module.exports = AnswerSyncService;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npm test -- answerSync`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add src/services/answerSync.service.js tests/unit/answerSync.service.test.js
git commit -m "feat(answer-sync): per-question sync bucketing service"
```

### Task 1.2: Privacy-safe LLM summaries + verdict + cache

**Files:**
- Modify: `src/services/answerSync.service.js`
- Test: `tests/unit/answerSync.service.test.js`

- [ ] **Step 1: Write the failing test** (append)

```js
describe('AnswerSyncService.summarize', () => {
  it('uses the rule-based fallback when no LLM and never returns raw answers', async () => {
    const per = [{ questionNumber: 1, dimension: 'love_expression', similarity: 1, syncLevel: 'highly_in_sync' }];
    const qDocs = [{ questionNumber: 1, questionText: 'How do you show love?', dimension: 'love_expression' }];
    const ansA = new Map([[1, { questionNumber: 1, textAnswer: 'SECRET-A' }]]);
    const ansB = new Map([[1, { questionNumber: 1, textAnswer: 'SECRET-B' }]]);
    const out = await AnswerSyncService.summarize(per, qDocs, ansA, ansB, { llm: false });
    expect(out[0]).toHaveProperty('summaryYou');
    expect(out[0]).toHaveProperty('summaryThem');
    expect(JSON.stringify(out)).not.toContain('SECRET-A');
    expect(JSON.stringify(out)).not.toContain('SECRET-B');
  });
});

describe('AnswerSyncService.verdict', () => {
  it('summarizes the distribution into a phrase', () => {
    expect(AnswerSyncService.verdict([
      { key: 'highly_in_sync', count: 6 }, { key: 'in_sync', count: 4 },
      { key: 'neutral_ground', count: 2 }, { key: 'different_views', count: 2 }, { key: 'poles_apart', count: 1 },
    ])).toMatch(/sync/i);
  });
});
```

- [ ] **Step 2: Run to verify it fails**

Run: `npm test -- answerSync`
Expected: FAIL — `summarize`/`verdict` not a function.

- [ ] **Step 3: Implement** (add to the class, above `module.exports`)

```js
  /**
   * Verdict phrase from the bucket distribution.
   */
  static verdict(buckets) {
    const c = Object.fromEntries(buckets.map((b) => [b.key, b.count]));
    const total = buckets.reduce((s, b) => s + b.count, 0) || 1;
    const aligned = (c.highly_in_sync + c.in_sync) / total;
    if (aligned >= 0.7) return 'Mostly in sync';
    if (aligned >= 0.4) return 'A balanced mix';
    return 'You see things differently';
  }

  /**
   * Produce a 1-line neutral summary of EACH person's answer per question.
   * Privacy: returns only synthesized summaries — never the raw answer text.
   * Batched single LLM call; rule-based fallback when llm is disabled/fails.
   */
  static async summarize(perQuestion, questionDocs, mapA, mapB, opts = {}) {
    const qMap = new Map(questionDocs.map((q) => [q.questionNumber, q]));
    const useLLM = opts.llm !== false && process.env.OPENAI_API_KEY;

    const fallback = () => perQuestion.map((p) => {
      const sameSide = p.syncLevel === 'highly_in_sync' || p.syncLevel === 'in_sync';
      return {
        ...p,
        category: qMap.get(p.questionNumber)?.dimension || 'general',
        summaryYou: sameSide ? 'You lean the same way here.' : 'You take your own angle on this.',
        summaryThem: sameSide ? 'They land in the same place.' : 'They see it a little differently.',
      };
    });

    if (!useLLM) return fallback();

    try {
      const OpenAI = require('openai');
      const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
      const items = perQuestion.map((p) => {
        const a = mapA.get(p.questionNumber) || {};
        const b = mapB.get(p.questionNumber) || {};
        const txt = (x) => x.textAnswer || x.selectedOption || (x.selectedOptions || []).join(', ') || '';
        return { n: p.questionNumber, q: qMap.get(p.questionNumber)?.questionText || '', you: txt(a), them: txt(b) };
      });
      const completion = await openai.chat.completions.create({
        model: 'gpt-4o-mini', temperature: 0.5, response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: 'You summarize how two people answered the same question. For each item return a SHORT (max 90 chars) neutral, warm one-liner for "you" and for "them" — paraphrase the gist, NEVER quote them verbatim. Return JSON: { "items": [{ "n": number, "summaryYou": string, "summaryThem": string }] }' },
          { role: 'user', content: JSON.stringify({ items }) },
        ],
      });
      const parsed = JSON.parse(completion.choices[0].message.content);
      const byN = new Map((parsed.items || []).map((i) => [i.n, i]));
      return perQuestion.map((p) => ({
        ...p,
        category: qMap.get(p.questionNumber)?.dimension || 'general',
        summaryYou: byN.get(p.questionNumber)?.summaryYou || 'You shared your take.',
        summaryThem: byN.get(p.questionNumber)?.summaryThem || 'They shared theirs.',
      }));
    } catch (err) {
      return fallback();
    }
  }
```

- [ ] **Step 4: Run to verify it passes**

Run: `npm test -- answerSync`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add src/services/answerSync.service.js tests/unit/answerSync.service.test.js
git commit -m "feat(answer-sync): privacy-safe LLM summaries + verdict"
```

### Task 1.3: Public `getSync` (cache + assemble) + controller + route

**Files:**
- Modify: `src/services/answerSync.service.js`, `src/controllers/match.controller.js`, `src/routes/match.routes.js`

- [ ] **Step 1: Add the orchestrator to the service** (above `module.exports`)

```js
  /**
   * Full sync payload for two users, cached 10 min (per sorted pair).
   * Privacy: never includes raw answers.
   */
  static async getSync(userIdA, userIdB) {
    const cache = require('../utils/cache');
    const key = `answersync:${[userIdA.toString(), userIdB.toString()].sort().join(':')}`;
    return cache.getOrSet(key, 600, async () => {
      const base = await this.computeBuckets(userIdA, userIdB);
      if (base.totalCommon === 0) {
        return { totalCommon: 0, verdict: 'Not enough shared answers yet', buckets: base.buckets, questions: [] };
      }
      const [ansA, ansB] = await Promise.all([
        Answer.find({ userId: userIdA }).select('+embedding').lean(),
        Answer.find({ userId: userIdB }).select('+embedding').lean(),
      ]);
      const mapA = new Map(ansA.map((a) => [a.questionNumber, a]));
      const mapB = new Map(ansB.map((a) => [a.questionNumber, a]));
      const qDocs = await Question.find({ questionNumber: { $in: base.questions.map((q) => q.questionNumber) } }).lean();
      const questions = await this.summarize(base.questions, qDocs, mapA, mapB);
      // Strip the raw similarity from the wire payload (keep syncLevel + summaries only).
      const safe = questions.map(({ similarity, ...rest }) => rest);
      return { totalCommon: base.totalCommon, verdict: this.verdict(base.buckets), buckets: base.buckets, questions: safe };
    });
  }
```

- [ ] **Step 2: Add the controller handler** in `src/controllers/match.controller.js` (near `getCompatibilityDeepDive`)

```js
/**
 * @desc    Answer-sync analysis for a match (common questions bucketed by sync level)
 * @route   GET /api/v1/matches/:matchId/answer-sync
 * @access  Private
 */
const getAnswerSync = asyncHandler(async (req, res) => {
  const Match = require('../models/Match');
  const AnswerSyncService = require('../services/answerSync.service');
  const match = await Match.findById(req.params.matchId).lean();
  if (!match) { const e = new Error('Match not found'); e.statusCode = 404; throw e; }
  const me = req.user._id.toString();
  const ids = (match.users || [match.userA, match.userB]).map((u) => u.toString());
  const other = ids.find((id) => id !== me);
  if (!other) { const e = new Error('Match not found'); e.statusCode = 404; throw e; }

  const result = await AnswerSyncService.getSync(me, other);
  res.status(200).json({ success: true, statusCode: 200, message: 'Answer sync generated', data: result });
});
```

> NOTE during implementation: confirm the Match model's participant field names (`users` vs `userA/userB`) by reading `src/models/Match.js`, and match the existing pattern used by `getCompatibilityDeepDive`. Export `getAnswerSync` in the controller's `module.exports`.

- [ ] **Step 3: Add the route** in `src/routes/match.routes.js` next to the `/:matchId/compatibility` route

```js
router.get('/:matchId/answer-sync', matchController.getAnswerSync);
```

- [ ] **Step 4: Verify**

Run: `node -c src/services/answerSync.service.js && node -c src/controllers/match.controller.js && node -c src/routes/match.routes.js` → no output (OK).
Run: `npm test -- answerSync` → PASS.

- [ ] **Step 5: Commit**

```bash
git add src/services/answerSync.service.js src/controllers/match.controller.js src/routes/match.routes.js
git commit -m "feat(answer-sync): GET /matches/:matchId/answer-sync endpoint"
```

---

## Phase 2 — Frontend: Sync Analysis page

### Task 2.1: Response models

**Files:** Modify `Boop/Models/InteractionModels.swift`

- [ ] **Step 1:** Add these `Decodable` structs:

```swift
struct AnswerSyncResponse: Decodable {
    let totalCommon: Int
    let verdict: String
    let buckets: [AnswerSyncBucket]
    let questions: [AnswerSyncQuestion]
}
struct AnswerSyncBucket: Decodable, Identifiable {
    let key: String
    let label: String
    let count: Int
    var id: String { key }
}
struct AnswerSyncQuestion: Decodable, Identifiable {
    let questionNumber: Int
    let category: String
    let syncLevel: String
    let summaryYou: String
    let summaryThem: String
    var id: Int { questionNumber }
}
```

- [ ] **Step 2: Verify** — build (see Task 2.3 build command); expect SUCCESS after Task 2.3 wires usage. Commit with Task 2.3.

### Task 2.2: Endpoint + ViewModel

**Files:** Modify `Boop/Core/Network/APIEndpoint.swift`; Create `Boop/Features/Matches/ViewModels/AnswerSyncViewModel.swift`

- [ ] **Step 1:** Add the endpoint case mirroring `getCompatibilityDeepDive` — path `"/matches/\(matchId)/answer-sync"`, GET, authed. (Read the existing `getCompatibilityDeepDive` case and copy its shape exactly.)

- [ ] **Step 2:** Create the view model:

```swift
import Foundation

@Observable
final class AnswerSyncViewModel {
    let matchId: String
    var data: AnswerSyncResponse?
    var isLoading = false
    var errorMessage: String?
    var selectedBucket: String?

    init(matchId: String) { self.matchId = matchId }

    @MainActor func load() async {
        isLoading = true; defer { isLoading = false }
        do { data = try await APIClient.shared.request(.getAnswerSync(matchId: matchId)); errorMessage = nil }
        catch let e as APIError { errorMessage = e.errorDescription }
        catch { errorMessage = "Could not load." }
    }

    func questions(in bucket: String) -> [AnswerSyncQuestion] {
        (data?.questions ?? []).filter { $0.syncLevel == bucket }
    }
}
```

### Task 2.3: `AnswerSyncView`

**Files:** Create `Boop/Features/Matches/Views/AnswerSyncView.swift`; then `xcodegen generate`.

- [ ] **Step 1:** Implement the page — header (totalCommon + verdict + spectrum), the 5 tappable buckets, and a disclosure of each selected bucket's questions with `summaryYou` / `summaryThem`. Use design tokens (`BoopColors`, `BoopTypography`, `BoopSpacing`, `EyebrowLabel`, `AccentRule`). Spectrum = an `HStack` of `Rectangle`s with width `∝ count` using `BoopColors.dimensionColor`/accent ramp. Map `syncLevel` → display label/colour with a small local helper. Bucket rows toggle `viewModel.selectedBucket`; selected bucket renders its questions inline (question text from a number→text lookup is not available client-side, so show category + summaries; include the question text in the API later if needed — for now show `CATEGORY · SYNC LABEL` as the row title).

> Implementation note: the API payload does not include the question TEXT (only number/category). For v1 show the category + sync label + the two summaries. If the question text is wanted on this screen, add `questionText` to the backend `summarize` output (it already has `qMap`) — do that here rather than a second pass.

- [ ] **Step 2: Regenerate project** so the new files compile:

Run (frontend repo): `xcodegen generate`

- [ ] **Step 3: Build**

Run: `xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'platform=iOS Simulator,name=iPhone 16' -derivedDataPath /tmp/boopDD CODE_SIGNING_ALLOWED=NO build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Render-verify** — temporarily host `AnswerSyncView` with a mock `AnswerSyncResponse` via the `DebugHarness` pattern (set `BoopApp` root → harness, build, `xcrun simctl install/launch`, `xcrun simctl io 'iPhone 16' screenshot /tmp/sync.png`, Read it), confirm spectrum + buckets + expanded summaries look right, then revert the harness.

- [ ] **Step 5: Commit**

```bash
git add Boop/Models/InteractionModels.swift Boop/Core/Network/APIEndpoint.swift Boop/Features/Matches/ViewModels/AnswerSyncViewModel.swift Boop/Features/Matches/Views/AnswerSyncView.swift Boop.xcodeproj
git commit -m "feat(matches): answer-sync analysis page"
```

---

## Phase 3 — Frontend: MatchDetailView restructure

### Task 3.1: Horizontal connection-stage strip

**Files:** Create `Boop/Features/Matches/Views/ConnectionStageStrip.swift`; modify `MatchDetailView.swift`.

- [ ] **Step 1:** Build `ConnectionStageStrip` from `viewModel.stageSteps` + `viewModel.currentStageIndex` (already used by the existing vertical `stageCard`) as a horizontal stepper: nodes in an `HStack`, connectors between, current highlighted, labels under each. Include the one-line `viewModel.stageSummary` and the existing primary action(s) (Advance / Request Reveal — reuse whatever the current `stageCard`/next-move uses).
- [ ] **Step 2:** Replace the body's `stageCard` (and the separate "Recommended next move" block, if distinct) usage with `ConnectionStageStrip(...)`.
- [ ] **Step 3:** `xcodegen generate` → build → `** BUILD SUCCEEDED **`.
- [ ] **Step 4: Commit** `feat(matches): horizontal connection-stage strip`.

### Task 3.2: "Growth & Insights" page (consolidation)

**Files:** Create `Boop/Features/Matches/Views/GrowthInsightsView.swift`; modify `MatchDetailView.swift`, `MatchDetailViewModel.swift`.

- [ ] **Step 1:** Move these existing sub-views out of `MatchDetailView` into `GrowthInsightsView(matchId:)`: `comfortCard(breakdown:)`, `readinessCard(_:)`, `ScoreProgressView(...)`, and the relationship-insights block (`RelationshipInsightsCard` / `insightsPromptCard` / `Analyze Connection`). Keep their data loads on a `MatchDetailViewModel` (or a dedicated VM) the new view owns.
- [ ] **Step 2:** Humanize dimension labels: anywhere a dimension/comfort key is shown (e.g. the comfort breakdown rows), pass it through a single helper `Self.humanize(_ key:) -> String` that replaces `_` with spaces and title-cases, and FIX any camelCase keys (`Activedays` → "Active days") — verify by reading `comfortCard` and the breakdown model keys.
- [ ] **Step 3:** Ensure no `10000%` can render: the chemistry card is removed (Task 3.3); for any reused dimension score, clamp/round to a 0–100 integer before appending `%`.
- [ ] **Step 4:** `xcodegen generate` → build → SUCCEEDED.
- [ ] **Step 5: Commit** `feat(matches): consolidated Growth & Insights page`.

### Task 3.3: Trim `MatchDetailView` to 5 sections + add teasers

**Files:** Modify `MatchDetailView.swift`, `MatchDetailViewModel.swift`.

- [ ] **Step 1:** Rebuild the `body` to exactly: `heroCard` (UNCHANGED — keep `BlurredPortrait` + `FogBlur`) → `ConnectionStageStrip` → **"How you answer together" teaser** → **"Growth & insights" teaser** → `actionsCard`. Remove inline: the `chemistryCard` ("Why this could work"), `comfortCard`, `readinessCard`, `ScoreProgressView`, the inline relationship-insights, and the date-plan CTA if it belongs in Growth (keep if it's a primary action). Keep `goneQuietSection`, `boopAndStreakRow` (these live in/below the hero).
- [ ] **Step 2:** "How you answer together" teaser: a tappable `BoopCard` showing `verdict` + a mini spectrum + "N questions". Fetch via a lightweight `viewModel.loadAnswerSyncTeaser()` (calls the same endpoint; cached server-side) OR reuse `AnswerSyncViewModel`. `NavigationLink` → `AnswerSyncView(matchId:)`.
- [ ] **Step 3:** "Growth & insights" teaser: tappable card showing Comfort `score/100` + trend; `NavigationLink` → `GrowthInsightsView(matchId:)`.
- [ ] **Step 4:** `xcodegen generate` → build → SUCCEEDED. Render-verify the trimmed page via `DebugHarness` (mock the VM enough to render the teasers + stage), screenshot, confirm ~5 calm sections, revert harness.
- [ ] **Step 5: Commit** `feat(matches): slim connection page to five sections + teasers`.

---

## Phase 4 — Frontend: About-person privacy hardening

**Files:** Modify `Boop/Features/Matches/Views/PartnerProfileView.swift`.

- [ ] **Step 1:** Read `PartnerProfileView` end-to-end. Confirm it renders ONLY: voice intro (player), personality type (archetype), numerology. If any branch renders the other user's written/text answers or raw Q&A, remove it.
- [ ] **Step 2:** If the backend endpoint feeding it returns raw answers, stop requesting/decoding them (defense in depth) — note the endpoint in the commit.
- [ ] **Step 3:** `xcodegen generate` (if files added) → build → SUCCEEDED.
- [ ] **Step 4: Commit** `fix(matches): never expose a partner's written answers on their About page`.

---

## Phase 5 — Verification & ship

- [ ] **Step 1:** Backend: `npm test` → all pass (incl. `answerSync`).
- [ ] **Step 2:** Frontend: full build `** BUILD SUCCEEDED **`, no warnings in touched files.
- [ ] **Step 3:** Manual on-device/sim sanity via render harness for `AnswerSyncView`, trimmed `MatchDetailView`, `GrowthInsightsView`.
- [ ] **Step 4:** Commit any cleanup; push backend `main` (deploys), push frontend branch + fast-forward `main`.
- [ ] **Step 5:** Bump build, archive → export (verify production APNs) → upload to TestFlight (per `unmutee-testflight-upload-recipe`).

---

## Self-review notes

- **Spec coverage:** Hero unchanged (3.3 Step 1) ✓; horizontal stage (3.1) ✓; sync teaser + page (2.x, 3.3) ✓; Growth & Insights consolidation incl. chart + insights (3.2) ✓; comfort as a number + deeper page (3.2/3.3) ✓; About privacy (4) ✓; bucket wording (1.1 labels) ✓; privacy summaries only (1.2/1.3) ✓; bug fixes — labels (3.2 Step 2), 10000% (3.2 Step 3) ✓.
- **Open spec questions** are resolved as: thresholds in 1.1 (tunable in code), growth chart lives in Growth & Insights (3.2), summaries shown for both parties (1.2). Revisit if render review suggests otherwise.
