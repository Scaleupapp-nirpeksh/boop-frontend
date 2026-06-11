# First-Time Flow + Personality Experience — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure onboarding to deliver a personality reveal in ~3 minutes (reward-first), add a fixed 8-question onboarding set + a "Deepen" confidence engine + daily nudge, introduce a fixed personality-archetype catalog ("Coded & Rare" + share card), gate Connect behind a deferred voice+photos setup, and fix/redesign the profile surfaces. Implements `docs/superpowers/specs/2026-06-11-onboarding-flow-and-personality-experience.md`.

**Architecture:** Cross-stack. Backend (`/Users/nirpekshnandan/My Products/boop-backend`, Node/Express/Mongoose/Jest) adds a `preview` stage, an `isOnboarding` question flag, new stage predicates, a requester gate on Connect, a match-confidence value, an archetype catalog + classification, and a Set-Main S3 fix. iOS (`/Users/nirpekshnandan/My Products/boop-frontend`, SwiftUI, Cinematic Dark) reorders onboarding, adds a Reveal screen + preview-browse + connect-setup, and redesigns the question-progress / personality / badges / voice / my-answers surfaces.

**Tech Stack:** Node 20 / Express / Mongoose / Jest (backend); SwiftUI iOS 17 / xcodegen / the Cinematic Dark design system (backend repo `npx jest tests/unit`; iOS `xcodebuild ... build`).

**Method:** Backend tasks are TDD with exact code (jest unit tests, mocked models — see `tests/unit/cache.test.js` style). iOS *logic* changes (stage enum, RootView gate, audio progress, model fields) get exact code; iOS *visual* screens (Reveal, confidence engine, personality redesign, badges shelf) get precise redesign briefs naming the exact Cinematic Dark components/tokens + acceptance criteria — the implementer reads the current screen and re-expresses it, preserving behavior. No emoji in chrome; use tokens/components.

**Verification:** Backend `cd "/Users/nirpekshnandan/My Products/boop-backend" && npx jest tests/unit --forceExit` (a pre-existing `tests/integration/health.test.js` failure from a missing `supertest` dep is expected — ignore; no NEW failures). iOS `cd "/Users/nirpekshnandan/My Products/boop-frontend" && xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -6` → `BUILD SUCCEEDED` + named visual checks. Run `xcodegen generate` + `git add` the pbxproj when iOS files are added.

**Phases:** 1 Backend foundation (Tasks 1–4) · 2 Backend archetypes (Task 5) · 3 iOS flow (6–8) · 4 iOS question experience (9) · 5 iOS personality/profile/polish (10–13).

**Branches:** backend work on a `flow-personality` branch in boop-backend; iOS work on a `flow-personality` branch in boop-frontend.

---

## Task 1: Backend models — preview stage, isOnboarding, voice transcript

**Files:**
- Modify: `src/models/User.js` (profileStage enum + `preview`)
- Modify: `src/models/Question.js` (`isOnboarding`)
- Modify: `src/models/Answer.js` (`voiceAnswerTranscript`)
- Test: `tests/unit/flow.models.test.js`

- [ ] **Step 1: Write the failing test**
```js
// tests/unit/flow.models.test.js
const User = require('../../src/models/User');
const Question = require('../../src/models/Question');
const Answer = require('../../src/models/Answer');
const mongoose = require('mongoose');

describe('flow model fields', () => {
  it('User.profileStage accepts preview', () => {
    const u = new User({ phone: '+919876543210', profileStage: 'preview' });
    const err = u.validateSync();
    expect(err?.errors?.profileStage).toBeUndefined();
  });
  it('User.profileStage rejects an unknown stage', () => {
    const u = new User({ phone: '+919876543210', profileStage: 'nope' });
    expect(u.validateSync()?.errors?.profileStage).toBeDefined();
  });
  it('Question has an isOnboarding boolean defaulting false', () => {
    const q = new Question({ questionNumber: 1, dimension: 'life_vision', depthLevel: 'surface', questionText: 'x', questionType: 'single_choice', dayAvailable: 1, order: 1 });
    expect(q.isOnboarding).toBe(false);
  });
  it('Answer has a voiceAnswerTranscript field', () => {
    const a = new Answer({ userId: new mongoose.Types.ObjectId(), questionId: new mongoose.Types.ObjectId(), questionNumber: 1, voiceAnswerTranscript: 'hello' });
    expect(a.voiceAnswerTranscript).toBe('hello');
  });
});
```

- [ ] **Step 2: Run it — FAIL** (`preview` invalid / `isOnboarding` undefined). `npx jest tests/unit/flow.models.test.js`

- [ ] **Step 3: Implement**
- `User.js` — add `'preview'` to the profileStage enum values: `values: ['incomplete', 'voice_pending', 'questions_pending', 'preview', 'ready']`.
- `Question.js` — add before the closing schema brace: `isOnboarding: { type: Boolean, default: false },`
- `Answer.js` — add after `transcriptionPending`: `voiceAnswerTranscript: { type: String, default: null },`

- [ ] **Step 4: Run it — PASS** (4 tests).

- [ ] **Step 5: Commit**
```bash
cd "/Users/nirpekshnandan/My Products/boop-backend"
git add src/models/User.js src/models/Question.js src/models/Answer.js tests/unit/flow.models.test.js
git commit -m "feat(flow): preview stage, isOnboarding flag, voice transcript field"
```

---

## Task 2: Backend — new stage predicates + onboarding question seed

**Files:**
- Modify: `src/services/profile.service.js` (`_checkAndAdvanceStage` ~588-605)
- Modify: `src/services/question.service.js` (stage advance ~123-127; onboarding question fetch)
- Modify: `src/scripts/seedQuestions.js` (flag 8 onboarding questions)
- Test: `tests/unit/flow.stages.test.js`

New stage rules: `incomplete → preview` when basic info present AND `questionsAnswered >= 8`; `preview → ready` when voice present AND photos ≥ 3. The old `voice_pending`/`questions_pending` paths are replaced.

- [ ] **Step 1: Write the failing test**
```js
// tests/unit/flow.stages.test.js
jest.mock('../../src/utils/logger', () => ({ debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn() }));
const ProfileService = require('../../src/services/profile.service');

function makeUser(over = {}) {
  return { _id: 'u1', firstName: 'A', dateOfBirth: new Date('2000-01-01'), gender: 'male', interestedIn: 'women',
    questionsAnswered: 0, voiceIntro: {}, photos: { items: [] }, profileStage: 'incomplete', ...over };
}

describe('_checkAndAdvanceStage (reward-first)', () => {
  it('incomplete → preview at 8 answers with basic info', async () => {
    const u = makeUser({ questionsAnswered: 8 });
    await ProfileService._checkAndAdvanceStage(u);
    expect(u.profileStage).toBe('preview');
  });
  it('stays incomplete below 8 answers', async () => {
    const u = makeUser({ questionsAnswered: 7 });
    await ProfileService._checkAndAdvanceStage(u);
    expect(u.profileStage).toBe('incomplete');
  });
  it('preview → ready with voice + 3 photos', async () => {
    const u = makeUser({ profileStage: 'preview', questionsAnswered: 8,
      voiceIntro: { audioUrl: 'a' }, photos: { items: [{}, {}, {}] } });
    await ProfileService._checkAndAdvanceStage(u);
    expect(u.profileStage).toBe('ready');
  });
  it('preview stays preview with voice but only 2 photos', async () => {
    const u = makeUser({ profileStage: 'preview', questionsAnswered: 8,
      voiceIntro: { audioUrl: 'a' }, photos: { items: [{}, {}] } });
    await ProfileService._checkAndAdvanceStage(u);
    expect(u.profileStage).toBe('preview');
  });
});
```

- [ ] **Step 2: Run — FAIL.** `npx jest tests/unit/flow.stages.test.js`

- [ ] **Step 3: Implement the new predicates** — replace the body of `_checkAndAdvanceStage` in `profile.service.js`:
```js
  static async _checkAndAdvanceStage(user) {
    const hasBasicInfo = !!(user.firstName && user.dateOfBirth && user.gender && user.interestedIn);
    const hasVoice = !!user.voiceIntro?.audioUrl;
    const photoCount = user.photos?.items?.length || 0;
    const hasMinPhotos = photoCount >= 3;
    const answered = user.questionsAnswered || 0;

    // incomplete → preview: basic info + the 8 onboarding answers (reward-first)
    if (user.profileStage === 'incomplete' && hasBasicInfo && answered >= 8) {
      user.profileStage = 'preview';
      logger.info(`User ${user._id} stage: incomplete → preview (${answered} answers)`);
    }
    // preview → ready: voice + 3 photos (connect-setup)
    if (user.profileStage === 'preview' && hasVoice && hasMinPhotos) {
      user.profileStage = 'ready';
      logger.info(`User ${user._id} stage: preview → ready`);
    }
    // Legacy safety: any user with voice + photos + 8 answers is ready
    if (['voice_pending', 'questions_pending'].includes(user.profileStage) && hasVoice && hasMinPhotos && answered >= 8) {
      user.profileStage = 'ready';
    }
  }
```

- [ ] **Step 4: Update `question.service.js` stage advance** (~123-127) — replace the `>= 15 → ready` block with a call to the same predicate path. Since question.service doesn't import ProfileService, inline the preview/ready logic there using the same rules (basic info + 8 → preview; voice + 3 photos + 8 → ready). After incrementing `questionsAnswered`:
```js
    const hasBasicInfo = !!(user.firstName && user.dateOfBirth && user.gender && user.interestedIn);
    if (user.profileStage === 'incomplete' && hasBasicInfo && user.questionsAnswered >= 8) {
      user.profileStage = 'preview';
    }
    const hasVoice = !!user.voiceIntro?.audioUrl;
    const photoCount = user.photos?.items?.length || 0;
    if (user.profileStage === 'preview' && hasVoice && photoCount >= 3) {
      user.profileStage = 'ready';
    }
```

- [ ] **Step 5: Flag 8 onboarding questions in the seed** — In `src/scripts/seedQuestions.js`, set `isOnboarding: true` on exactly **8 questions, one per dimension**, all `dayAvailable: 1`, biased to surface/moderate depth + fast types (single_choice preferred). Pick the lowest-friction existing question for each of: emotional_vulnerability, attachment_patterns, life_vision, conflict_resolution, love_expression, intimacy_comfort, lifestyle_rhythm, growth_mindset. (Read the seed data; choose the surface/single_choice question per dimension. Add `isOnboarding: true` to those 8 objects.) Add a console summary line printing the 8 chosen question numbers.

- [ ] **Step 6: Run — PASS** + `npx jest tests/unit` (no new failures).

- [ ] **Step 7: Commit**
```bash
git add src/services/profile.service.js src/services/question.service.js src/scripts/seedQuestions.js tests/unit/flow.stages.test.js
git commit -m "feat(flow): reward-first stage predicates + 8-question onboarding seed"
```

---

## Task 3: Backend — Set-Main bug fix (re-process from S3 key)

**Files:**
- Modify: `src/services/upload.service.js` (add `getObjectBuffer(s3Key)`)
- Modify: `src/services/profile.service.js` (`_rebuildProfilePhotoFromGalleryItem`)
- Test: `tests/unit/setmain.test.js`

Root cause: `_rebuildProfilePhotoFromGalleryItem` does `fetch(item.url)` on a stored **presigned** URL that expires (~1h) → 403. Fix: fetch the bytes from S3 by **`s3Key`** via the authenticated client.

- [ ] **Step 1: Write the failing test**
```js
// tests/unit/setmain.test.js
const mockSend = jest.fn();
jest.mock('../../src/config/s3', () => ({ s3Client: { send: (...a) => mockSend(...a) }, S3_BUCKET: 'b', S3_BASE_URL: 'https://b.s3.amazonaws.com' }));
jest.mock('@aws-sdk/s3-request-presigner', () => ({ getSignedUrl: jest.fn() }));
jest.mock('sharp', () => jest.fn());
jest.mock('../../src/utils/logger', () => ({ debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn() }));
const UploadService = require('../../src/services/upload.service');

describe('UploadService.getObjectBuffer', () => {
  it('fetches bytes from S3 by key (not a URL)', async () => {
    const chunks = async function* () { yield Buffer.from('img'); };
    mockSend.mockResolvedValue({ Body: chunks() });
    const buf = await UploadService.getObjectBuffer('users/u1/gallery/x.webp');
    expect(buf).toBeInstanceOf(Buffer);
    expect(buf.toString()).toBe('img');
    expect(mockSend).toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run — FAIL** (`getObjectBuffer` undefined).

- [ ] **Step 3: Implement `getObjectBuffer`** in `upload.service.js` (`GetObjectCommand` is already imported):
```js
  /** Fetch an object's raw bytes from S3 by key via the authenticated client. */
  static async getObjectBuffer(s3Key) {
    const res = await s3Client.send(new GetObjectCommand({ Bucket: S3_BUCKET, Key: s3Key }));
    const chunks = [];
    for await (const chunk of res.Body) chunks.push(chunk);
    return Buffer.concat(chunks);
  }
```

- [ ] **Step 4: Fix the rebuild** — in `profile.service.js` `_rebuildProfilePhotoFromGalleryItem`, replace the `fetch(item.url)` body:
```js
  static async _rebuildProfilePhotoFromGalleryItem(item, userId) {
    const s3Key = item.s3Key || UploadService._extractS3Key(item.url);
    if (!s3Key) {
      const error = new Error('Could not locate the selected photo for profile processing');
      error.statusCode = 400;
      throw error;
    }
    const buffer = await UploadService.getObjectBuffer(s3Key);
    return UploadService.processProfilePhoto(buffer, userId);
  }
```

- [ ] **Step 5: Run — PASS** + `npx jest tests/unit`.

- [ ] **Step 6: Commit**
```bash
git add src/services/upload.service.js src/services/profile.service.js tests/unit/setmain.test.js
git commit -m "fix(profile): set-main re-processes from S3 key, not expiring presigned URL"
```

---

## Task 4: Backend — connect gate + match-confidence + history voice + milestone

**Files:**
- Modify: `src/services/discover.service.js` (`likeUser` requester gate)
- Modify: `src/services/question.service.js` (`getUserProgress` → add `matchConfidence`; history voice fields)
- Modify: `src/services/personality.service.js` (`MILESTONES` 6→8)
- Test: `tests/unit/flow.gate.test.js`, `tests/unit/flow.confidence.test.js`

- [ ] **Step 1: Connect gate test**
```js
// tests/unit/flow.gate.test.js
jest.mock('../../src/models/User');
jest.mock('../../src/services/safety.service', () => ({ isBlockedEither: jest.fn().mockResolvedValue(false) }));
jest.mock('../../src/utils/logger', () => ({ debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn() }));
const User = require('../../src/models/User');
const DiscoverService = require('../../src/services/discover.service');

const lean = (v) => ({ lean: () => Promise.resolve(v) });

beforeEach(() => jest.clearAllMocks());

it('blocks Connect when requester is not ready (preview) with complete_setup signal', async () => {
  // target lookup then requester lookup
  User.findById
    .mockReturnValueOnce(lean({ _id: 'target', isActive: true, isBanned: false }))   // target
    .mockReturnValueOnce(lean({ _id: 'me', profileStage: 'preview' }));               // requester
  await expect(DiscoverService.likeUser('me', 'target')).rejects.toMatchObject({ statusCode: 403, code: 'complete_setup_required' });
});
```
(Adjust the `User.findById` call-order mock to match the real sequence in `likeUser` — read it; the gate is added right after the target-validity check.)

- [ ] **Step 2: Run — FAIL.**

- [ ] **Step 3: Add the requester gate** in `discover.service.js` `likeUser`, immediately after the target-user validity check (~line 165):
```js
    // Connect requires a completed profile (voice + photos → ready)
    const requester = await User.findById(fromUserId).lean();
    if (!requester || requester.profileStage !== 'ready') {
      const error = new Error('Add your voice and photos to start connecting');
      error.statusCode = 403;
      error.code = 'complete_setup_required';
      throw error;
    }
```
Ensure the error `code` survives to the HTTP layer: confirm `src/middleware/errorHandler.js` passes a custom `err.code` into the JSON body as `code` (if it doesn't, add `code: err.code` to the error response shape — quote the handler and adjust minimally so the app can detect it).

- [ ] **Step 4: Confidence test**
```js
// tests/unit/flow.confidence.test.js
const { matchConfidence } = require('../../src/services/question.service');
it('confidence is monotonic and 0..100', () => {
  expect(matchConfidence(0, 8)).toBe(0);
  expect(matchConfidence(8, 8)).toBeGreaterThan(0);
  expect(matchConfidence(8, 8)).toBeLessThan(matchConfidence(20, 8));
  expect(matchConfidence(200, 8)).toBeLessThanOrEqual(100);
});
```
(If `matchConfidence` isn't exported standalone, export a pure helper from question.service for testability.)

- [ ] **Step 5: Implement `matchConfidence` + add to progress** — in `question.service.js`, add and export a pure helper, and include it in `getUserProgress`'s return:
```js
// Pure: answers → match confidence 0..100. Front-loads early gains, asymptotes.
function matchConfidence(totalAnswered, dimensionsCovered) {
  const a = Math.max(0, totalAnswered);
  // 8 onboarding answers ≈ 50%, ~30 answers ≈ 90%, caps at 100.
  const base = Math.round(100 * (1 - Math.exp(-a / 14)));
  return Math.min(100, base);
}
module.exports.matchConfidence = matchConfidence; // or attach to the class statics consistently
```
In `getUserProgress`'s returned object add: `matchConfidence: matchConfidence(totalAnswered, Object.keys(dimensionProgress).length),` and change `readyThreshold`/`isReady` semantics to reflect the new model — keep `readyThreshold: 8` (the onboarding bar) and `isReady: totalAnswered >= 8` for the preview gate (the report still deepens past 8). Add `onboardingComplete: totalAnswered >= 8`.

- [ ] **Step 6: History voice fields** — find the `getQuestionHistory`/answer-history method (the endpoint `getQuestionHistory` maps to). Include `voiceAnswerUrl` and `voiceAnswerTranscript` (and a `isVoice` flag) on each history item so the app can play + show transcript. Quote the method and add the fields to its projection/mapping.

- [ ] **Step 7: Milestone 6→8** — in `personality.service.js` line 8: `const MILESTONES = [8, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60];` and update the `isPreliminary` boundary if it referenced 6 (it uses `< 15`, fine). Confirm the analysis trigger fires at 8.

- [ ] **Step 8: Run both tests + full unit suite — PASS / no new failures.**

- [ ] **Step 9: Commit**
```bash
git add src/services/discover.service.js src/services/question.service.js src/services/personality.service.js src/middleware/errorHandler.js tests/unit/flow.gate.test.js tests/unit/flow.confidence.test.js
git commit -m "feat(flow): connect gate, match-confidence, history voice fields, reveal milestone at 8"
```

---

## Task 5: Backend — personality archetype catalog + classification + rarity

**Files:**
- Create: `src/utils/archetypes.js` (the fixed catalog)
- Modify: `src/services/personality.service.js` (classify into catalog; store archetype; rarity)
- Modify: `src/models/PersonalityAnalysis.js` (archetype fields)
- Test: `tests/unit/archetypes.test.js`

- [ ] **Step 1: Create the catalog** — `src/utils/archetypes.js`: an array of ~14 archetypes, each `{ code: 'ARCH_01', number: 1, name: 'The Gentle Adventurer', essence: 'A heart that wanders carefully.', signature: '<one line describing the trait profile that maps here> ' }`. Export `ARCHETYPES` + a `findByCode(code)` helper + the list of valid codes. (Author 14 distinct, warm archetype names spanning the personality space — e.g. Gentle Adventurer, Steady Anchor, Bright Catalyst, Quiet Deep, Open Romantic, Free Spirit, Devoted Builder, Playful Sage, Tender Realist, Bold Dreamer, Warm Strategist, Curious Wanderer, Loyal Flame, Soft Rebel.)

- [ ] **Step 2: Test**
```js
// tests/unit/archetypes.test.js
const { ARCHETYPES, findByCode, ARCHETYPE_CODES } = require('../../src/utils/archetypes');
it('has ~14 archetypes with unique codes + numbers', () => {
  expect(ARCHETYPES.length).toBeGreaterThanOrEqual(12);
  expect(new Set(ARCHETYPES.map(a => a.code)).size).toBe(ARCHETYPES.length);
  expect(new Set(ARCHETYPES.map(a => a.number)).size).toBe(ARCHETYPES.length);
});
it('findByCode returns the archetype or null', () => {
  expect(findByCode(ARCHETYPE_CODES[0]).code).toBe(ARCHETYPE_CODES[0]);
  expect(findByCode('NOPE')).toBeNull();
});
```
Run — FAIL → implement → PASS.

- [ ] **Step 3: Classify in the AI prompt** — in `personality.service.js` `_buildAnalysisPrompt`, append the archetype list (codes + names + signatures) and instruct GPT-4o to **return `archetypeCode` (exactly one of the catalog codes)** alongside the existing JSON. In `generateAnalysis`, after parsing: validate `result.archetypeCode` against `findByCode`; if invalid/missing, fall back to a deterministic pick from the top facet (documented). Store `analysis.archetypeCode`, and derive `archetypeName`/`archetypeNumber`/`essence` from the catalog. Keep `personalityType` set to the archetype name for backward-compat.

- [ ] **Step 4: Model fields** — `PersonalityAnalysis.js`: add `archetypeCode: { type: String, default: null }`, `archetypeNumber: { type: Number, default: null }`. (Name/essence resolve from the catalog at read time; don't duplicate.)

- [ ] **Step 5: Rarity** — add a method `PersonalityService.getArchetypeRarity(code)` returning a percentage = `round(100 * countWithCode / max(1, totalCompletedAnalyses))`, from a cached aggregate (use the existing `cache.getOrSet('archetype:distribution', 600, …)` to count completed analyses grouped by `archetypeCode`). The personality **response** (the controller that serves `getPersonalityAnalysis`) includes `archetypeCode`, `archetypeNumber`, `archetypeName`, `essence`, and `rarityPercent`. (Scope dial per spec §7: if rarity is cut, omit `rarityPercent` only — keep the catalog fields.)

- [ ] **Step 6: Run unit suite — no new failures. Commit**
```bash
git add src/utils/archetypes.js src/services/personality.service.js src/models/PersonalityAnalysis.js tests/unit/archetypes.test.js
git commit -m "feat(personality): fixed archetype catalog, AI classification, rarity"
```

- [ ] **Step 7: Deploy note** — these backend changes ship via the boop-backend deploy Action (push to `main`). The question reseed (`node src/scripts/seedQuestions.js`) must run on the box after deploy to apply `isOnboarding`. Flag this in the final report.

---

## Task 6: iOS — preview stage, entry gate, onboarding reorder

**Files:**
- Modify: `Boop/Models/User.swift` (ProfileStage `.preview`)
- Modify: `Boop/App/RootView.swift` (entry gate)
- Modify: `Boop/Features/Onboarding/Views/OnboardingContainerView.swift` + `ViewModels/OnboardingViewModel.swift` (reorder: basicInfo → questions → (reveal); defer voice/photos)

**Brief:** Preserve behavior; reorder the flow.
- `User.swift` `ProfileStage` enum: add `case preview`.
- `RootView.swift` entry gate (lines 72-76): enter `.main` when `profileStage == .ready || profileStage == .preview`. (Preview users are in the app, browsing.) Remove the old `questionsPending && >= 6` clause.
- `OnboardingStep` enum + container: the onboarding flow is now **basicInfo → questions** (the 8 onboarding questions) → the **Reveal** (Task 7). **Remove `location`, `bio`, `voiceIntro`, `photos` from the onboarding step sequence** (voice + photos move to connect-setup; bio/location move to profile editing later — keep their views, just not in the onboarding path). Trim BasicInfo to the matching essentials (name, DOB, gender, interested-in, city — city can stay on basic info or be inferred; keep it minimal). Onboarding completes (markComplete) when the user has answered the 8 and the reveal is dismissed → app enters in `preview`.
- The onboarding QuestionsView fetches the onboarding set: ensure `getQuestions` returns the 8 `isOnboarding` questions during onboarding (the backend onboarding-context fetch). If the existing `.getQuestions` returns day-drip, add/observe an onboarding flag so onboarding shows exactly the 8. (Coordinate with Task 2's fetch; if backend returns all unlocked, the app filters to the onboarding ordering — but prefer the backend returning the 8.)

- [ ] Build (`xcodegen generate` if files added) → `BUILD SUCCEEDED`. Visual-check: a fresh user does basic info → 8 questions only (no voice/photo steps). Commit:
```bash
cd "/Users/nirpekshnandan/My Products/boop-frontend"
git add Boop/Models/User.swift Boop/App/RootView.swift Boop/Features/Onboarding/Views/OnboardingContainerView.swift Boop/Features/Onboarding/ViewModels/OnboardingViewModel.swift Boop.xcodeproj/project.pbxproj
git commit -m "feat(flow): preview stage, reward-first onboarding reorder (basic info + 8 questions)"
```

---

## Task 7: iOS — the Reveal screen

**Files:**
- Create: `Boop/Features/Onboarding/Views/RevealView.swift`
- Modify: onboarding flow to present it after the 8th onboarding answer.

**Brief (Cinematic Dark, "The Clearing"-style):** After the 8 onboarding questions, present a full-screen reveal. Content: `EyebrowLabel` "YOUR TYPE", the archetype in the **Coded & Rare** treatment (`TYPE 0N` + `N% RARE` + the name in `cineDisplay` + essence line + `AccentRule`), 2-3 signature traits as tracked lines, then the pull: a coral `BoopButton` **"See who fits you →"** that completes onboarding and enters the app (preview/Discover). The personality analysis is async — on appear, load `.getPersonalityAnalysis`; if still generating (pending), show a brief cinematic "reading your answers…" state and poll once/twice (the analysis fires at 8). The "N people fit you" count: use a discover stats/count call (`.getDiscoverStats` or candidate count) for N; if unavailable, omit the number and say "See who fits you". Reuse `RemoteAudioPlayer`/components as needed. No emoji.

- [ ] Build → `BUILD SUCCEEDED`. Visual-check: completing the 8th question plays the Reveal with the archetype + rarity + a CTA into the app. Commit:
```bash
git add Boop/Features/Onboarding/Views/RevealView.swift Boop/Features/Onboarding/Views/OnboardingContainerView.swift Boop/Features/Onboarding/ViewModels/QuestionsViewModel.swift Boop.xcodeproj/project.pbxproj
git commit -m "feat(flow): the personality Reveal screen"
```

---

## Task 8: iOS — preview-browse + connect-setup gate

**Files:**
- Modify: `Boop/Features/Discover/Views/DiscoverView.swift` + `ViewModels/DiscoverViewModel.swift`
- Create: `Boop/Features/Onboarding/Views/ConnectSetupView.swift` (reuses voice + photo screens)
- Modify: `Boop/Core/Network/APIError.swift` (detect the `complete_setup_required` code) if needed

**Brief:** Preserve behavior.
- A `preview` user can browse Discover (already works once they're `.main`). Add a quiet persistent banner in Discover when `currentUser.profileStage == .preview`: "Add your voice + photos to start connecting →" opening `ConnectSetupView`.
- `sendConnect`: when the backend returns the `complete_setup_required` error (Task 4 — surfaced via `APIError`; check `errorDescription`/a parsed code), instead of showing a generic error, present `ConnectSetupView` (record voice → add 3 photos, reusing `VoiceIntroView`/`PhotoUploadView` logic recontextualized). On completion the user becomes `ready` (server transitions on voice+photos); refresh the user, then retry the pending like automatically and continue the normal match flow.
- `APIError`: ensure the server's `code: "complete_setup_required"` is decodable — if the current decoding only keeps `message`, extend the error parse to capture an optional `code` so the app can branch reliably (not string-matching the message).

- [ ] Build → `BUILD SUCCEEDED`. Visual-check: a preview user sees the banner; tapping Connect launches connect-setup; finishing it sends the like. Commit:
```bash
git add Boop/Features/Discover/Views/DiscoverView.swift Boop/Features/Discover/ViewModels/DiscoverViewModel.swift Boop/Features/Onboarding/Views/ConnectSetupView.swift Boop/Core/Network/APIError.swift Boop.xcodeproj/project.pbxproj
git commit -m "feat(flow): preview browse + connect-setup gate"
```

---

## Task 9: iOS — "Deepen" confidence engine + daily nudge

**Files:**
- Modify: `Boop/Features/Questions/Views/QuestionsProgressView.swift` + `ViewModels/QuestionsProgressViewModel.swift`
- Modify: `Boop/Models/APIModels.swift` (`QuestionsProgressResponse` add `matchConfidence`, `onboardingComplete`)
- Modify: `Boop/Features/Home/Views/DailyQuestionBand.swift` (recontextualize the nudge)

**Brief (the approved confidence-engine mockup):** Add `matchConfidence: Int` and `onboardingComplete: Bool` to `QuestionsProgressResponse` (Task 4 provides them). Redesign `QuestionsProgressView` to the confidence engine: a prominent **match-confidence ring** (a circular `Gauge`/`Circle().trim` at `matchConfidence/100`, coral on hairline, the % large light-weight in the center, "MATCH CONFIDENCE" eyebrow), a line "answer N more to reach M%" (compute a sensible next target), the per-dimension coverage as hairline rows with thin coral bars (already have `dimensions`), and a coral "Answer more" `BoopButton` that opens the question flow (`QuestionsFullView`). The Home `DailyQuestionBand` copy reframes to "a new question to sharpen your matches" and shows the confidence delta if available. No emoji.

- [ ] Build → `BUILD SUCCEEDED`. Visual-check: progress page shows the climbing confidence ring + coverage + Answer more; Home nudge reframed. Commit:
```bash
git add Boop/Features/Questions/Views/QuestionsProgressView.swift Boop/Features/Questions/ViewModels/QuestionsProgressViewModel.swift Boop/Models/APIModels.swift Boop/Features/Home/Views/DailyQuestionBand.swift
git commit -m "feat(questions): Deepen confidence engine + daily nudge"
```

---

## Task 10: iOS — Personality "Coded & Rare" redesign + Share card

**Files:**
- Modify: `Boop/Features/Profile/Views/PersonalityReportView.swift`
- Modify: `Boop/Models/APIModels.swift` (`PersonalityAnalysis` add `archetypeCode/archetypeNumber/archetypeName/essence/rarityPercent`)
- Create: `Boop/Features/Profile/Views/PersonalityShareCard.swift`

**Brief (the approved "Coded & Rare" + radar-led mockup):** Add the archetype fields to the `PersonalityAnalysis` model (decoded from Task 5's response; all optional for back-compat). Redesign `PersonalityReportView`: lead with the **Coded & Rare** hero — `TYPE 0N` (archetypeNumber) + `N% RARE` (rarityPercent, omit gracefully if nil) + the name (`cineDisplay`) + essence (`cineBodyLight`) + `AccentRule`. Then the existing radar (`PersonalityRadarChartView`), then animated facet bars (the existing facet rows, keep), the AI summary, numerology quiet below. Add a **"Share card"** `BoopButton` next to "Full read": `PersonalityShareCard` renders the archetype + radar (+ rarity) into a compact view, snapshot to `UIImage` (`ImageRenderer`), and present a share sheet. No emoji.

- [ ] Build → `BUILD SUCCEEDED`. Visual-check: personality page leads with the coded/rare archetype; Share card produces a shareable image. Commit:
```bash
git add Boop/Features/Profile/Views/PersonalityReportView.swift Boop/Models/APIModels.swift Boop/Features/Profile/Views/PersonalityShareCard.swift Boop.xcodeproj/project.pbxproj
git commit -m "feat(personality): Coded & Rare archetype redesign + share card"
```

---

## Task 11: iOS — Badges trophy shelf

**Files:**
- Modify: `Boop/Features/Profile/Views/BadgesView.swift`

**Brief (the approved trophy-shelf mockup):** Preserve the badge data (`BadgeCatalogItem`: key/title/description/category/earned/earnedAt). Redesign from the hairline list to a **grid of progress-ring medallions**: each badge = a circular ring (earned = full coral `Circle().trim`/stroke + a thin SF-Symbol glyph mapped per badge key, **no emoji**; in-progress badges that have a derivable count = partial ring + count; locked = dim hairline ring + muted glyph), the badge title as a tracked `cineCaption` below. An overall **"7 of 14" arc** header + a **"closest to earning"** line. Map each badge key → a thin SF Symbol (e.g. voice→`waveform`, questions→`text.alignleft`, streak→`flame`, games→`gamecontroller`, photo→`person.crop.square`, special→`sparkle`); drop the `emoji` field usage. No emoji.

- [ ] Build → `BUILD SUCCEEDED`. Visual-check: badges render as a ringed trophy grid; earned/locked clear. Commit:
```bash
git add Boop/Features/Profile/Views/BadgesView.swift
git commit -m "feat(profile): badges trophy shelf"
```

---

## Task 12: iOS — voice progress bar + My Answers voice/transcript + photo-reorder labels

**Files:**
- Modify: `Boop/Core/Audio/RemoteAudioPlayer.swift` (expose elapsed/duration/progress)
- Modify: `Boop/DesignSystem/Components/CinematicComponents.swift` (`VoiceLine` progress)
- Modify: `Boop/Features/Profile/Views/MyAnswersView.swift` + `ViewModels/MyAnswersViewModel.swift` + `Boop/Models/APIModels.swift` (`AnswerHistoryItem` voice fields)
- Modify: `Boop/Features/Profile/Views/ProfileView.swift` (photo-reorder accessibility labels)

**Brief:**
- **`RemoteAudioPlayer`**: add an AVPlayer periodic time observer; expose `private(set) var elapsed: Double = 0`, `duration: Double = 0`, and `var progress: Double { duration > 0 ? elapsed/duration : 0 }` (observable). Reset on stop/track-change; remove the observer in `stop`.
- **`VoiceLine`**: add `var progress: Double = 0` and `var elapsedText: String? = nil`; replace the static middle hairline with `HairlineProgress(progress: progress)`; show elapsed/duration. Update call sites (ProfileView, VoiceReRecordView, etc.) to pass `progress: audioPlayer.currentURL == url ? audioPlayer.progress : 0`.
- **My Answers voice+transcript**: add `voiceAnswerUrl: String?`, `voiceAnswerTranscript: String?`, `isVoice: Bool?` to `AnswerHistoryItem` (decoded from Task 4's history fields). In `MyAnswersView.answerContent`, when a voice answer: render a `VoiceLine` (play via the audio player) **and** the transcript text (`cineBodyLight`). Text answers unchanged.
- **Photo-reorder labels**: in `ProfileView`'s `photoOrderButton` arrows, add `.accessibilityLabel("Move earlier")` / `.accessibilityLabel("Move later")` and a tiny tracked caption or clearer affordance so the reorder reads obviously.

- [ ] Build → `BUILD SUCCEEDED`. Visual-check: voice intro shows a real progress bar that advances; My Answers plays voice + shows transcript; reorder arrows are labeled. Commit:
```bash
git add Boop/Core/Audio/RemoteAudioPlayer.swift Boop/DesignSystem/Components/CinematicComponents.swift Boop/Features/Profile/Views/MyAnswersView.swift Boop/Features/Profile/ViewModels/MyAnswersViewModel.swift Boop/Models/APIModels.swift Boop/Features/Profile/Views/ProfileView.swift
git commit -m "feat(profile): voice playback progress, my-answers voice+transcript, reorder labels"
```

---

## Task 13: iOS — build 14 + full verification

**Files:** Modify `project.yml`.

- [ ] **Step 1: Bump build to 14** — `project.yml`: `CURRENT_PROJECT_VERSION` "13"→"14" and `CFBundleVersion` "13"→"14".
- [ ] **Step 2: Build** — `xcodegen generate` + build → `BUILD SUCCEEDED`.
- [ ] **Step 3: Full verification (dark + light)** — walk the new flow end-to-end in the simulator: fresh user → basic info → 8 questions → Reveal (archetype + rarity) → app in preview → Discover banner → Connect launches connect-setup → finishing makes you ready → like sends. Then: Question Progress confidence ring, Personality Coded&Rare + share card, Badges trophy shelf, voice progress bar, My Answers voice+transcript, Set-Main works. No emoji in chrome; cinematic throughout. Fix any leftover inline.
- [ ] **Step 4: Commit**
```bash
git add project.yml Boop.xcodeproj/project.pbxproj
git commit -m "chore: build 14 (flow + personality experience)"
```

---

## Out of scope / notes
- Real-user migration: no users yet; clean cutover + `seedQuestions.js` reseed on the box after backend deploy.
- The comfort/reveal mechanic, games, chat, trust-safety, dates, Cinematic Dark visuals — unchanged.
- Rarity % is scope-dialable (Task 5 §5) — ship catalog + code without live rarity if cut.

## Post-implementation
- Backend: merge to `main` → deploy Action runs → **run `node src/scripts/seedQuestions.js` on the box** (SSM) to apply `isOnboarding`.
- iOS: ship build 14 to TestFlight via the saved recipe (memory `unmutee-testflight-upload-recipe`).
