# Trust & Safety + Comfort Hardening + Crash Reporting — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the App-Store-blocking trust & safety minimum bar (block/report/account deletion/moderation/review queue), harden the comfort score against gaming, and add crash reporting.

**Architecture:** Backend (Node/Express/Mongoose at `/Users/nirpekshnandan/My Products/boop-backend`) gets three new models (Block, Report, ModerationFlag), a SafetyService + ModerationService, enforcement hooks in discover/like/message paths, an admin review-queue API guarded by a static key, account deletion, and per-day caps + quality thresholds in the comfort score. iOS (`/Users/nirpekshnandan/My Products/boop-frontend`) gets Firebase Crashlytics, safety API endpoints, a reusable ReportUserSheet, block/report menus in chat + match detail, and a Delete Account flow in Profile.

**Tech Stack:** Express/Mongoose/Joi/Bull/Jest (backend); SwiftUI/xcodegen/Firebase SPM (iOS); OpenAI `omni-moderation-latest` for text+image moderation (the moderation endpoint is free).

**Two repos:** Tasks 1–11 commit in `boop-backend`. Tasks 12–17 commit in `boop-frontend`. Run backend tests with `npm test` from the backend root.

**Discovery note (already done — do NOT re-do):** The "wire unwired notifications" item from the June 9 strategy doc is stale. `streak_milestone` (message.service.js:292-308), `badge_earned` (badge.service.js:243-257), `reveal_request` / `photos_revealed` (match.service.js requestReveal) are all already wired. The crash-reporting workstream is therefore Crashlytics only (Task 12).

**Existing conventions to follow:**
- Services are classes with static methods that throw `Error` with `.statusCode`.
- Controllers use `asyncHandler` and respond `{ success, statusCode, message, data }`.
- Routes use `authenticate` from `src/middleware/auth.middleware` and Joi `validate(schema)` from the validator files.
- Unit tests mock every model/util with `jest.mock(...)` (see `tests/unit/cache.test.js`), no DB.

---

## Task 1: Safety models (Block, Report, ModerationFlag) + REPORT_REASONS constant

**Files:**
- Modify: `boop-backend/src/utils/constants.js`
- Create: `boop-backend/src/models/Block.js`
- Create: `boop-backend/src/models/Report.js`
- Create: `boop-backend/src/models/ModerationFlag.js`
- Test: `boop-backend/tests/unit/safety.models.test.js`

- [ ] **Step 1: Write the failing test**

```js
// tests/unit/safety.models.test.js
const mongoose = require('mongoose');
const Block = require('../../src/models/Block');
const Report = require('../../src/models/Report');
const ModerationFlag = require('../../src/models/ModerationFlag');
const { REPORT_REASONS } = require('../../src/utils/constants');

const oid = () => new mongoose.Types.ObjectId();

describe('safety models', () => {
  it('Block requires blocker and blocked', () => {
    const err = new Block({}).validateSync();
    expect(err.errors.blocker).toBeDefined();
    expect(err.errors.blocked).toBeDefined();
  });

  it('REPORT_REASONS includes the core reasons', () => {
    expect(REPORT_REASONS).toEqual(
      expect.arrayContaining(['harassment', 'fake_profile', 'underage', 'spam', 'other'])
    );
  });

  it('Report rejects unknown reasons', () => {
    const err = new Report({ reporter: oid(), reported: oid(), reason: 'not_a_reason' }).validateSync();
    expect(err.errors.reason).toBeDefined();
  });

  it('Report defaults to pending', () => {
    const report = new Report({ reporter: oid(), reported: oid(), reason: 'spam' });
    expect(report.validateSync()).toBeUndefined();
    expect(report.status).toBe('pending');
  });

  it('ModerationFlag requires contentType and userId', () => {
    const err = new ModerationFlag({}).validateSync();
    expect(err.errors.contentType).toBeDefined();
    expect(err.errors.userId).toBeDefined();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd "/Users/nirpekshnandan/My Products/boop-backend" && npx jest tests/unit/safety.models.test.js`
Expected: FAIL — `Cannot find module '../../src/models/Block'`

- [ ] **Step 3: Add REPORT_REASONS to constants**

In `src/utils/constants.js`, after the `REACTION_EMOJIS` declaration add:

```js
// User report reasons (trust & safety)
const REPORT_REASONS = [
  'harassment',
  'inappropriate_messages',
  'inappropriate_photos',
  'fake_profile',
  'underage',
  'spam',
  'safety_concern',
  'other',
];
```

And add `REPORT_REASONS,` to the `module.exports` object.

- [ ] **Step 4: Create the three models**

```js
// src/models/Block.js
const mongoose = require('mongoose');

const blockSchema = new mongoose.Schema(
  {
    blocker: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    blocked: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  },
  { timestamps: true }
);

blockSchema.index({ blocker: 1, blocked: 1 }, { unique: true });
blockSchema.index({ blocked: 1 });

module.exports = mongoose.model('Block', blockSchema);
```

```js
// src/models/Report.js
const mongoose = require('mongoose');
const { REPORT_REASONS } = require('../utils/constants');

const reportSchema = new mongoose.Schema(
  {
    reporter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    reported: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    reason: { type: String, enum: REPORT_REASONS, required: true },
    details: { type: String, maxlength: 1000 },
    contentType: { type: String, enum: ['profile', 'message', 'photo'], default: 'profile' },
    messageId: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
    status: { type: String, enum: ['pending', 'dismissed', 'actioned'], default: 'pending' },
    reviewNote: { type: String, default: null },
    resolvedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

reportSchema.index({ status: 1, createdAt: -1 });
reportSchema.index({ reported: 1 });

module.exports = mongoose.model('Report', reportSchema);
```

```js
// src/models/ModerationFlag.js
const mongoose = require('mongoose');

const moderationFlagSchema = new mongoose.Schema(
  {
    contentType: { type: String, enum: ['message', 'photo'], required: true },
    // Owner of the flagged content
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    messageId: { type: mongoose.Schema.Types.ObjectId, ref: 'Message', default: null },
    conversationId: { type: mongoose.Schema.Types.ObjectId, ref: 'Conversation', default: null },
    categories: [String],
    severe: { type: Boolean, default: false },
    autoHidden: { type: Boolean, default: false },
    excerpt: { type: String, maxlength: 300 },
    status: { type: String, enum: ['pending', 'dismissed', 'actioned'], default: 'pending' },
    reviewNote: { type: String, default: null },
    resolvedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

moderationFlagSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('ModerationFlag', moderationFlagSchema);
```

- [ ] **Step 5: Run test to verify it passes**

Run: `npx jest tests/unit/safety.models.test.js`
Expected: PASS (5 tests)

- [ ] **Step 6: Commit**

```bash
git add src/utils/constants.js src/models/Block.js src/models/Report.js src/models/ModerationFlag.js tests/unit/safety.models.test.js
git commit -m "feat(safety): Block, Report, ModerationFlag models + report reasons"
```

---

## Task 2: SafetyService (block / unblock / report / lookup helpers)

**Files:**
- Create: `boop-backend/src/services/safety.service.js`
- Test: `boop-backend/tests/unit/safety.service.test.js`

- [ ] **Step 1: Write the failing test**

```js
// tests/unit/safety.service.test.js
jest.mock('../../src/models/Block');
jest.mock('../../src/models/Report');
jest.mock('../../src/models/User');
jest.mock('../../src/models/Match');
jest.mock('../../src/models/Conversation');
jest.mock('../../src/utils/logger', () => ({
  debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn(),
}));

const Block = require('../../src/models/Block');
const Report = require('../../src/models/Report');
const User = require('../../src/models/User');
const Match = require('../../src/models/Match');
const Conversation = require('../../src/models/Conversation');
const SafetyService = require('../../src/services/safety.service');

const A = 'aaaaaaaaaaaaaaaaaaaaaaaa';
const B = 'bbbbbbbbbbbbbbbbbbbbbbbb';

const userChain = (result) => ({
  select: jest.fn().mockReturnValue({ lean: jest.fn().mockResolvedValue(result) }),
});

beforeEach(() => jest.clearAllMocks());

describe('blockUser', () => {
  it('rejects blocking yourself', async () => {
    await expect(SafetyService.blockUser(A, A)).rejects.toMatchObject({ statusCode: 400 });
  });

  it('404s when the target does not exist', async () => {
    User.findById.mockReturnValue(userChain(null));
    await expect(SafetyService.blockUser(A, B)).rejects.toMatchObject({ statusCode: 404 });
  });

  it('upserts the block and archives any active match', async () => {
    User.findById.mockReturnValue(userChain({ _id: B }));
    Block.updateOne.mockResolvedValue({});
    const match = { _id: 'm1', stage: 'connecting', isActive: true, save: jest.fn() };
    Match.findOne.mockResolvedValue(match);
    Conversation.updateOne.mockResolvedValue({});

    await SafetyService.blockUser(A, B);

    expect(Block.updateOne).toHaveBeenCalledWith(
      { blocker: A, blocked: B },
      { $setOnInsert: { blocker: A, blocked: B } },
      { upsert: true }
    );
    expect(match.stage).toBe('archived');
    expect(match.isActive).toBe(false);
    expect(match.archiveReason).toBe('blocked');
    expect(match.archivedBy).toBe(A);
    expect(match.save).toHaveBeenCalled();
    expect(Conversation.updateOne).toHaveBeenCalledWith({ matchId: 'm1' }, { isActive: false });
  });

  it('works when there is no match between the users', async () => {
    User.findById.mockReturnValue(userChain({ _id: B }));
    Block.updateOne.mockResolvedValue({});
    Match.findOne.mockResolvedValue(null);
    await expect(SafetyService.blockUser(A, B)).resolves.toMatchObject({ blockedUserId: B });
  });
});

describe('isBlockedEither', () => {
  it('is true when either direction exists', async () => {
    Block.exists.mockResolvedValue({ _id: 'x' });
    expect(await SafetyService.isBlockedEither(A, B)).toBe(true);
  });
  it('is false when no block exists', async () => {
    Block.exists.mockResolvedValue(null);
    expect(await SafetyService.isBlockedEither(A, B)).toBe(false);
  });
});

describe('getBlockedIdSet', () => {
  it('returns ids from both directions', async () => {
    Block.find.mockReturnValue({
      lean: jest.fn().mockResolvedValue([
        { blocker: A, blocked: B },
        { blocker: 'cccccccccccccccccccccccc', blocked: A },
      ]),
    });
    const set = await SafetyService.getBlockedIdSet(A);
    expect(set.has(B)).toBe(true);
    expect(set.has('cccccccccccccccccccccccc')).toBe(true);
    expect(set.size).toBe(2);
  });
});

describe('reportUser', () => {
  it('rejects self-reports', async () => {
    await expect(
      SafetyService.reportUser(A, { reportedUserId: A, reason: 'spam' })
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it('rejects unknown reasons', async () => {
    await expect(
      SafetyService.reportUser(A, { reportedUserId: B, reason: 'nope' })
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it('creates a pending report', async () => {
    Report.create.mockResolvedValue({ _id: 'r1', status: 'pending' });
    const result = await SafetyService.reportUser(A, {
      reportedUserId: B,
      reason: 'harassment',
      details: 'said awful things',
    });
    expect(Report.create).toHaveBeenCalledWith(
      expect.objectContaining({ reporter: A, reported: B, reason: 'harassment' })
    );
    expect(result).toEqual({ reportId: 'r1', status: 'pending' });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx jest tests/unit/safety.service.test.js`
Expected: FAIL — `Cannot find module '../../src/services/safety.service'`

- [ ] **Step 3: Implement the service**

```js
// src/services/safety.service.js
const Block = require('../models/Block');
const Report = require('../models/Report');
const User = require('../models/User');
const Match = require('../models/Match');
const Conversation = require('../models/Conversation');
const { CONNECTION_STAGES, REPORT_REASONS } = require('../utils/constants');
const logger = require('../utils/logger');

// MARK: - Safety Service

/**
 * Blocking, reporting, and block-lookup helpers used by discover,
 * matching, and messaging to enforce user blocks platform-wide.
 */
class SafetyService {
  /**
   * Block a user. Idempotent. Also archives any active match between
   * the pair and deactivates its conversation. The blocked user is
   * never notified.
   */
  static async blockUser(blockerId, blockedId) {
    if (blockerId.toString() === blockedId.toString()) {
      const error = new Error('You cannot block yourself');
      error.statusCode = 400;
      throw error;
    }

    const target = await User.findById(blockedId).select('_id').lean();
    if (!target) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    // Upsert so double-blocking is a no-op instead of a duplicate-key error
    await Block.updateOne(
      { blocker: blockerId, blocked: blockedId },
      { $setOnInsert: { blocker: blockerId, blocked: blockedId } },
      { upsert: true }
    );

    // Archive any active match between the pair and deactivate its conversation
    const match = await Match.findOne({
      users: { $all: [blockerId, blockedId] },
      isActive: true,
    });

    if (match) {
      match.stage = CONNECTION_STAGES.ARCHIVED;
      match.isActive = false;
      match.archivedBy = blockerId;
      match.archivedAt = new Date();
      match.archiveReason = 'blocked';
      await match.save();
      await Conversation.updateOne({ matchId: match._id }, { isActive: false });
    }

    logger.info(`Safety: user ${blockerId} blocked ${blockedId}`);
    return { blockedUserId: blockedId };
  }

  /** Remove a block. Does NOT restore an archived match. */
  static async unblockUser(blockerId, blockedId) {
    await Block.deleteOne({ blocker: blockerId, blocked: blockedId });
    logger.info(`Safety: user ${blockerId} unblocked ${blockedId}`);
    return { unblockedUserId: blockedId };
  }

  /** List users this user has blocked (for a settings screen). */
  static async getBlockedUsers(blockerId) {
    const blocks = await Block.find({ blocker: blockerId })
      .populate('blocked', 'firstName')
      .sort({ createdAt: -1 })
      .lean();

    return blocks.map((b) => ({
      userId: b.blocked?._id,
      firstName: b.blocked?.firstName || 'Deleted user',
      blockedAt: b.createdAt,
    }));
  }

  /** True if either user has blocked the other. */
  static async isBlockedEither(userIdA, userIdB) {
    const block = await Block.exists({
      $or: [
        { blocker: userIdA, blocked: userIdB },
        { blocker: userIdB, blocked: userIdA },
      ],
    });
    return Boolean(block);
  }

  /**
   * Set of user-id strings involved in a block with this user (either
   * direction). Used to exclude blocked users from Discover.
   */
  static async getBlockedIdSet(userId) {
    const blocks = await Block.find(
      { $or: [{ blocker: userId }, { blocked: userId }] },
      { blocker: 1, blocked: 1 }
    ).lean();

    const ids = new Set();
    blocks.forEach((b) => {
      const other =
        b.blocker.toString() === userId.toString() ? b.blocked : b.blocker;
      ids.add(other.toString());
    });
    return ids;
  }

  /** File a report against a user. Reports land in the admin review queue. */
  static async reportUser(
    reporterId,
    { reportedUserId, reason, details = null, contentType = 'profile', messageId = null }
  ) {
    if (reporterId.toString() === reportedUserId.toString()) {
      const error = new Error('You cannot report yourself');
      error.statusCode = 400;
      throw error;
    }

    if (!REPORT_REASONS.includes(reason)) {
      const error = new Error(`Invalid reason. Allowed: ${REPORT_REASONS.join(', ')}`);
      error.statusCode = 400;
      throw error;
    }

    const report = await Report.create({
      reporter: reporterId,
      reported: reportedUserId,
      reason,
      details,
      contentType,
      messageId,
    });

    logger.info(`Safety: user ${reporterId} reported ${reportedUserId} (${reason})`);
    return { reportId: report._id, status: report.status };
  }
}

module.exports = SafetyService;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx jest tests/unit/safety.service.test.js`
Expected: PASS (9 tests)

- [ ] **Step 5: Commit**

```bash
git add src/services/safety.service.js tests/unit/safety.service.test.js
git commit -m "feat(safety): SafetyService — block/unblock/report + lookup helpers"
```

---

## Task 3: Safety routes, controller, validator + mount

**Files:**
- Create: `boop-backend/src/validators/safety.validator.js`
- Create: `boop-backend/src/controllers/safety.controller.js`
- Create: `boop-backend/src/routes/safety.routes.js`
- Modify: `boop-backend/src/routes/index.js`

- [ ] **Step 1: Create the validator**

Note: reuse the existing `validate` helper exported from `src/validators/profile.validator.js` (line ~106) — import it in the routes file, don't duplicate it.

```js
// src/validators/safety.validator.js
const Joi = require('joi');
const { REPORT_REASONS } = require('../utils/constants');

const blockUserSchema = Joi.object({
  userId: Joi.string().hex().length(24).required().messages({
    'any.required': 'userId is required',
  }),
});

const reportUserSchema = Joi.object({
  userId: Joi.string().hex().length(24).required(),
  reason: Joi.string().valid(...REPORT_REASONS).required(),
  details: Joi.string().trim().max(1000).allow('', null),
  contentType: Joi.string().valid('profile', 'message', 'photo').default('profile'),
  messageId: Joi.string().hex().length(24).allow(null),
});

module.exports = { blockUserSchema, reportUserSchema };
```

- [ ] **Step 2: Create the controller**

```js
// src/controllers/safety.controller.js
const asyncHandler = require('../utils/asyncHandler');
const SafetyService = require('../services/safety.service');

/**
 * @desc    Block a user
 * @route   POST /api/v1/safety/block
 * @access  Private
 */
const blockUser = asyncHandler(async (req, res) => {
  const result = await SafetyService.blockUser(req.user._id, req.body.userId);
  res.status(200).json({ success: true, statusCode: 200, message: 'User blocked', data: result });
});

/**
 * @desc    Unblock a user
 * @route   DELETE /api/v1/safety/block/:userId
 * @access  Private
 */
const unblockUser = asyncHandler(async (req, res) => {
  const result = await SafetyService.unblockUser(req.user._id, req.params.userId);
  res.status(200).json({ success: true, statusCode: 200, message: 'User unblocked', data: result });
});

/**
 * @desc    List blocked users
 * @route   GET /api/v1/safety/blocked
 * @access  Private
 */
const getBlockedUsers = asyncHandler(async (req, res) => {
  const blocked = await SafetyService.getBlockedUsers(req.user._id);
  res.status(200).json({ success: true, statusCode: 200, message: 'Blocked users retrieved', data: { blocked } });
});

/**
 * @desc    Report a user
 * @route   POST /api/v1/safety/report
 * @access  Private
 */
const reportUser = asyncHandler(async (req, res) => {
  const result = await SafetyService.reportUser(req.user._id, {
    reportedUserId: req.body.userId,
    reason: req.body.reason,
    details: req.body.details || null,
    contentType: req.body.contentType || 'profile',
    messageId: req.body.messageId || null,
  });
  res.status(201).json({ success: true, statusCode: 201, message: 'Report submitted', data: result });
});

module.exports = { blockUser, unblockUser, getBlockedUsers, reportUser };
```

- [ ] **Step 3: Create the routes and mount them**

```js
// src/routes/safety.routes.js
const express = require('express');
const router = express.Router();
const safetyController = require('../controllers/safety.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { validate } = require('../validators/profile.validator');
const { blockUserSchema, reportUserSchema } = require('../validators/safety.validator');

// All safety routes require authentication
router.use(authenticate);

// POST /safety/block — Block a user
router.post('/block', validate(blockUserSchema), safetyController.blockUser);

// DELETE /safety/block/:userId — Unblock a user
router.delete('/block/:userId', safetyController.unblockUser);

// GET /safety/blocked — List blocked users
router.get('/blocked', safetyController.getBlockedUsers);

// POST /safety/report — Report a user
router.post('/report', validate(reportUserSchema), safetyController.reportUser);

module.exports = router;
```

In `src/routes/index.js`: add `const safetyRoutes = require('./safety.routes');` next to the other imports, and `router.use('/safety', safetyRoutes);` after the `/public` mount.

Note: verify `validate` is actually exported from `src/validators/profile.validator.js` (`module.exports` at the bottom, line ~132). If it isn't, copy the `validate` function (line ~106) into `safety.validator.js` and export it from there instead.

- [ ] **Step 4: Verify the app still boots and tests pass**

Run: `node -e "require('./src/routes/index.js'); console.log('routes OK')"`
Expected: `routes OK`
Run: `npm test`
Expected: all suites PASS

- [ ] **Step 5: Commit**

```bash
git add src/validators/safety.validator.js src/controllers/safety.controller.js src/routes/safety.routes.js src/routes/index.js
git commit -m "feat(safety): /safety routes — block, unblock, blocked list, report"
```

---

## Task 4: Block enforcement in discover, like, and messaging

**Files:**
- Modify: `boop-backend/src/services/discover.service.js` (getCandidates ~line 50; likeUser ~line 139)
- Modify: `boop-backend/src/services/message.service.js` (sendMessage ~line 177)
- Test: `boop-backend/tests/unit/safety.enforcement.test.js`

- [ ] **Step 1: Write the failing test**

```js
// tests/unit/safety.enforcement.test.js
jest.mock('../../src/models/Conversation');
jest.mock('../../src/models/Message');
jest.mock('../../src/models/Match');
jest.mock('../../src/services/upload.service');
jest.mock('../../src/services/safety.service');
jest.mock('../../src/utils/logger', () => ({
  debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn(),
}));

const Conversation = require('../../src/models/Conversation');
const SafetyService = require('../../src/services/safety.service');
const MessageService = require('../../src/services/message.service');

beforeEach(() => jest.clearAllMocks());

describe('sendMessage block enforcement', () => {
  it('403s when either user has blocked the other', async () => {
    Conversation.findOne.mockResolvedValue({
      _id: 'c1',
      participants: ['u1', 'u2'],
      getOtherParticipantId: () => 'u2',
    });
    SafetyService.isBlockedEither.mockResolvedValue(true);

    await expect(
      MessageService.sendMessage('u1', 'c1', { type: 'text', text: 'hello there friend' })
    ).rejects.toMatchObject({ statusCode: 403 });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx jest tests/unit/safety.enforcement.test.js`
Expected: FAIL (no 403 thrown — message creation proceeds into mocked models)

- [ ] **Step 3: Enforce in message.service.js**

Add `const SafetyService = require('./safety.service');` to the imports at the top of `src/services/message.service.js`.

In `sendMessage`, directly after the `if (!conversation) { ... }` block (after ~line 187) and **before** content validation, insert:

```js
    // ─── Block enforcement ────────────────────────────────────────
    const otherParticipantId = conversation.getOtherParticipantId(senderId);
    if (await SafetyService.isBlockedEither(senderId, otherParticipantId)) {
      const error = new Error('You cannot message this user');
      error.statusCode = 403;
      throw error;
    }
```

- [ ] **Step 4: Enforce in discover.service.js**

Add `const SafetyService = require('./safety.service');` to the imports at the top.

In `getCandidates`, after `excludeIds.push(currentUser._id); // Exclude self` (~line 55), insert:

```js
    // Exclude anyone involved in a block with this user (either direction)
    const blockedIds = await SafetyService.getBlockedIdSet(userId);
    blockedIds.forEach((id) => excludeIds.push(id));
```

In `likeUser` (~line 139), after the self-like check and before the target-user lookup, insert:

```js
    // Blocked pairs can't interact — present as not-found to avoid revealing the block
    if (await SafetyService.isBlockedEither(fromUserId, toUserId)) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }
```

- [ ] **Step 5: Run tests**

Run: `npx jest tests/unit/safety.enforcement.test.js && npm test`
Expected: new test PASS, full suite PASS

- [ ] **Step 6: Commit**

```bash
git add src/services/message.service.js src/services/discover.service.js tests/unit/safety.enforcement.test.js
git commit -m "feat(safety): enforce blocks in discover, like, and messaging"
```

---

## Task 5: ModerationService (OpenAI text + image moderation)

**Files:**
- Create: `boop-backend/src/services/moderation.service.js`
- Test: `boop-backend/tests/unit/moderation.service.test.js`

The moderation endpoint (`omni-moderation-latest`) is **free** and supports both text and images. The installed `openai@^4.20.1` SDK passes request bodies through, so no SDK upgrade is needed.

- [ ] **Step 1: Write the failing test**

```js
// tests/unit/moderation.service.test.js
const mockCreate = jest.fn();
jest.mock('openai', () =>
  jest.fn().mockImplementation(() => ({
    moderations: { create: mockCreate },
  }))
);
jest.mock('../../src/models/ModerationFlag');
jest.mock('../../src/models/Message');
jest.mock('../../src/utils/logger', () => ({
  debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn(),
}));

const ModerationFlag = require('../../src/models/ModerationFlag');
const Message = require('../../src/models/Message');
const ModerationService = require('../../src/services/moderation.service');

beforeEach(() => jest.clearAllMocks());

describe('moderateText', () => {
  it('maps flagged categories', async () => {
    mockCreate.mockResolvedValue({
      results: [{ flagged: true, categories: { harassment: true, sexual: false } }],
    });
    const result = await ModerationService.moderateText('abusive text');
    expect(result.flagged).toBe(true);
    expect(result.categories).toEqual(['harassment']);
    expect(result.severe).toBe(false);
  });

  it('marks severe categories', async () => {
    mockCreate.mockResolvedValue({
      results: [{ flagged: true, categories: { 'sexual/minors': true } }],
    });
    const result = await ModerationService.moderateText('x');
    expect(result.severe).toBe(true);
  });

  it('fails open when the API errors', async () => {
    mockCreate.mockRejectedValue(new Error('api down'));
    const result = await ModerationService.moderateText('x');
    expect(result.flagged).toBe(false);
    expect(result.failedOpen).toBe(true);
  });
});

describe('shouldBlockPhoto', () => {
  it('blocks sexual content', () => {
    expect(ModerationService.shouldBlockPhoto({ flagged: true, categories: ['sexual'] })).toBe(true);
  });
  it('does not block non-listed categories', () => {
    expect(ModerationService.shouldBlockPhoto({ flagged: true, categories: ['harassment'] })).toBe(false);
  });
  it('never blocks unflagged results', () => {
    expect(ModerationService.shouldBlockPhoto({ flagged: false, categories: [] })).toBe(false);
  });
});

describe('reviewMessage', () => {
  const message = {
    _id: 'm1',
    senderId: 'u1',
    conversationId: 'c1',
    content: { text: 'some text' },
  };

  it('creates a flag and hides severe messages', async () => {
    mockCreate.mockResolvedValue({
      results: [{ flagged: true, categories: { 'sexual/minors': true } }],
    });
    ModerationFlag.create.mockResolvedValue({});
    Message.findByIdAndUpdate.mockResolvedValue({});

    await ModerationService.reviewMessage(message);

    expect(ModerationFlag.create).toHaveBeenCalledWith(
      expect.objectContaining({ severe: true, autoHidden: true, messageId: 'm1' })
    );
    expect(Message.findByIdAndUpdate).toHaveBeenCalledWith('m1', { isDeleted: true });
  });

  it('flags but does not hide non-severe content', async () => {
    mockCreate.mockResolvedValue({
      results: [{ flagged: true, categories: { harassment: true } }],
    });
    ModerationFlag.create.mockResolvedValue({});

    await ModerationService.reviewMessage(message);

    expect(ModerationFlag.create).toHaveBeenCalled();
    expect(Message.findByIdAndUpdate).not.toHaveBeenCalled();
  });

  it('does nothing for clean messages', async () => {
    mockCreate.mockResolvedValue({ results: [{ flagged: false, categories: {} }] });
    await ModerationService.reviewMessage(message);
    expect(ModerationFlag.create).not.toHaveBeenCalled();
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx jest tests/unit/moderation.service.test.js`
Expected: FAIL — module not found

- [ ] **Step 3: Implement the service**

```js
// src/services/moderation.service.js
const OpenAI = require('openai');
const logger = require('../utils/logger');

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// Categories that auto-hide content immediately (review still happens)
const SEVERE_CATEGORIES = [
  'sexual/minors',
  'self-harm/intent',
  'self-harm/instructions',
  'violence/graphic',
];

// Categories that block a photo upload outright
const PHOTO_BLOCK_CATEGORIES = ['sexual', 'sexual/minors', 'violence', 'violence/graphic'];

// MARK: - Moderation Service

/**
 * Content moderation via OpenAI omni-moderation (free endpoint).
 * Text moderation FAILS OPEN (chat must not break if the API is down);
 * flagged content lands in the ModerationFlag review queue, and severe
 * categories are auto-hidden.
 */
class ModerationService {
  /** Moderate a text snippet. */
  static async moderateText(text) {
    try {
      const response = await openai.moderations.create({
        model: 'omni-moderation-latest',
        input: text,
      });
      return ModerationService._toResult(response);
    } catch (err) {
      logger.error('Moderation (text) failed — failing open:', err.message);
      return { flagged: false, severe: false, categories: [], failedOpen: true };
    }
  }

  /** Moderate an image buffer (profile photos, chat images). */
  static async moderateImage(buffer, mimeType = 'image/webp') {
    try {
      const response = await openai.moderations.create({
        model: 'omni-moderation-latest',
        input: [
          {
            type: 'image_url',
            image_url: { url: `data:${mimeType};base64,${buffer.toString('base64')}` },
          },
        ],
      });
      return ModerationService._toResult(response);
    } catch (err) {
      logger.error('Moderation (image) failed — failing open:', err.message);
      return { flagged: false, severe: false, categories: [], failedOpen: true };
    }
  }

  /** True when a photo moderation result should block the upload. */
  static shouldBlockPhoto(result) {
    if (!result.flagged) return false;
    return result.categories.some((c) => PHOTO_BLOCK_CATEGORIES.includes(c));
  }

  /**
   * Review a just-sent chat message in the background (fire-and-forget
   * from message.service). Flags to the review queue; auto-hides severe.
   */
  static async reviewMessage(message) {
    if (!message?.content?.text) return;

    const result = await ModerationService.moderateText(message.content.text);
    if (!result.flagged) return;

    const ModerationFlag = require('../models/ModerationFlag');
    await ModerationFlag.create({
      contentType: 'message',
      userId: message.senderId?._id || message.senderId,
      messageId: message._id,
      conversationId: message.conversationId,
      categories: result.categories,
      severe: result.severe,
      autoHidden: result.severe,
      excerpt: message.content.text.slice(0, 300),
    });

    if (result.severe) {
      const Message = require('../models/Message');
      await Message.findByIdAndUpdate(message._id, { isDeleted: true });
      logger.warn(`Moderation: auto-hid severe message ${message._id}`);
    }
  }

  /** Normalize an OpenAI moderation response. */
  static _toResult(response) {
    const r = response?.results?.[0];
    if (!r) return { flagged: false, severe: false, categories: [] };

    const categories = Object.entries(r.categories || {})
      .filter(([, v]) => v === true)
      .map(([k]) => k);

    return {
      flagged: Boolean(r.flagged),
      severe: categories.some((c) => SEVERE_CATEGORIES.includes(c)),
      categories,
    };
  }
}

module.exports = ModerationService;
```

- [ ] **Step 4: Run test to verify it passes**

Run: `npx jest tests/unit/moderation.service.test.js`
Expected: PASS (9 tests)

- [ ] **Step 5: Commit**

```bash
git add src/services/moderation.service.js tests/unit/moderation.service.test.js
git commit -m "feat(moderation): OpenAI omni-moderation service — text, image, message review"
```

---

## Task 6: Hook moderation into the message send path

**Files:**
- Modify: `boop-backend/src/services/message.service.js` (sendMessage, after message creation ~line 219)

- [ ] **Step 1: Add the fire-and-forget hook**

In `sendMessage`, directly after `await message.populate('senderId', 'firstName');` (~line 219), insert:

```js
    // ─── Content moderation (async, never blocks send) ───────────
    if (type === 'text') {
      try {
        const ModerationService = require('./moderation.service');
        ModerationService.reviewMessage(message).catch(() => {});
      } catch (_) {
        // Non-critical
      }
    }
```

- [ ] **Step 2: Verify nothing broke**

Run: `npm test`
Expected: all suites PASS (reviewMessage behavior is already covered by Task 5's tests)

- [ ] **Step 3: Commit**

```bash
git add src/services/message.service.js
git commit -m "feat(moderation): review every text message asynchronously"
```

---

## Task 7: Photo moderation at upload (profile photos + chat images)

**Files:**
- Modify: `boop-backend/src/services/profile.service.js` (uploadPhotos ~line 189, before processing)
- Modify: `boop-backend/src/controllers/message.controller.js` (uploadMedia ~line 123, before S3 upload)

- [ ] **Step 1: Moderate profile photos before processing**

Add `const ModerationService = require('./moderation.service');` to the imports at the top of `src/services/profile.service.js`.

In `uploadPhotos`, after the photo-count check (`if (currentCount + files.length > 6) { ... }`) and **before** `const uploadPromises = files.map(...)`, insert:

```js
    // Moderate every photo before any processing or S3 upload
    for (const file of files) {
      const moderation = await ModerationService.moderateImage(file.buffer, file.mimetype);
      if (ModerationService.shouldBlockPhoto(moderation)) {
        const error = new Error(
          'One of your photos does not meet our content guidelines. Please choose a different photo.'
        );
        error.statusCode = 422;
        throw error;
      }
    }
```

- [ ] **Step 2: Moderate chat images before upload**

In `src/controllers/message.controller.js` `uploadMedia` (~line 123), after the conversation check and **before** the `const ext = ...` line, insert:

```js
  // Moderate images before they reach S3 (voice notes are not image-moderated)
  if (type === 'image') {
    const ModerationService = require('../services/moderation.service');
    const moderation = await ModerationService.moderateImage(req.file.buffer, req.file.mimetype);
    if (ModerationService.shouldBlockPhoto(moderation)) {
      const error = new Error('This image does not meet our content guidelines');
      error.statusCode = 422;
      throw error;
    }
  }
```

- [ ] **Step 3: Verify**

Run: `npm test`
Expected: all suites PASS

- [ ] **Step 4: Commit**

```bash
git add src/services/profile.service.js src/controllers/message.controller.js
git commit -m "feat(moderation): block disallowed photos at upload (profile + chat)"
```

---

## Task 8: Admin review queue (reports, flags, ban/unban)

**Files:**
- Create: `boop-backend/src/middleware/adminAuth.js`
- Create: `boop-backend/src/controllers/admin.controller.js`
- Create: `boop-backend/src/routes/admin.routes.js`
- Modify: `boop-backend/src/routes/index.js`

- [ ] **Step 1: Create the admin auth middleware**

```js
// src/middleware/adminAuth.js
/**
 * Guards admin endpoints with a static API key.
 * Set ADMIN_API_KEY in the environment; requests must send it as the
 * `x-admin-key` header. Fails closed if the env var is missing.
 */
const adminAuth = (req, res, next) => {
  const configured = process.env.ADMIN_API_KEY;
  const provided = req.headers['x-admin-key'];

  if (!configured || !provided || provided !== configured) {
    return res.status(401).json({
      success: false,
      statusCode: 401,
      message: 'Unauthorized',
    });
  }

  next();
};

module.exports = { adminAuth };
```

- [ ] **Step 2: Create the admin controller**

```js
// src/controllers/admin.controller.js
const asyncHandler = require('../utils/asyncHandler');
const Report = require('../models/Report');
const ModerationFlag = require('../models/ModerationFlag');
const User = require('../models/User');

/**
 * @desc    List reports (default: pending)
 * @route   GET /api/v1/admin/reports?status=pending
 * @access  Admin (x-admin-key)
 */
const getReports = asyncHandler(async (req, res) => {
  const status = req.query.status || 'pending';
  const reports = await Report.find({ status })
    .populate('reporter', 'firstName phone')
    .populate('reported', 'firstName phone isBanned')
    .sort({ createdAt: -1 })
    .limit(100)
    .lean();
  res.status(200).json({ success: true, statusCode: 200, message: 'Reports retrieved', data: { reports } });
});

/**
 * @desc    Resolve a report
 * @route   PATCH /api/v1/admin/reports/:id  { action: 'dismissed'|'actioned', note? }
 * @access  Admin
 */
const resolveReport = asyncHandler(async (req, res) => {
  const { action, note } = req.body;
  if (!['dismissed', 'actioned'].includes(action)) {
    const error = new Error('action must be "dismissed" or "actioned"');
    error.statusCode = 400;
    throw error;
  }
  const report = await Report.findByIdAndUpdate(
    req.params.id,
    { status: action, reviewNote: note || null, resolvedAt: new Date() },
    { new: true }
  );
  if (!report) {
    const error = new Error('Report not found');
    error.statusCode = 404;
    throw error;
  }
  res.status(200).json({ success: true, statusCode: 200, message: 'Report resolved', data: { report } });
});

/**
 * @desc    List moderation flags (default: pending)
 * @route   GET /api/v1/admin/moderation-flags?status=pending
 * @access  Admin
 */
const getModerationFlags = asyncHandler(async (req, res) => {
  const status = req.query.status || 'pending';
  const flags = await ModerationFlag.find({ status })
    .populate('userId', 'firstName phone isBanned')
    .sort({ createdAt: -1 })
    .limit(100)
    .lean();
  res.status(200).json({ success: true, statusCode: 200, message: 'Moderation flags retrieved', data: { flags } });
});

/**
 * @desc    Resolve a moderation flag
 * @route   PATCH /api/v1/admin/moderation-flags/:id  { action: 'dismissed'|'actioned', note? }
 * @access  Admin
 */
const resolveModerationFlag = asyncHandler(async (req, res) => {
  const { action, note } = req.body;
  if (!['dismissed', 'actioned'].includes(action)) {
    const error = new Error('action must be "dismissed" or "actioned"');
    error.statusCode = 400;
    throw error;
  }
  const flag = await ModerationFlag.findByIdAndUpdate(
    req.params.id,
    { status: action, reviewNote: note || null, resolvedAt: new Date() },
    { new: true }
  );
  if (!flag) {
    const error = new Error('Flag not found');
    error.statusCode = 404;
    throw error;
  }
  res.status(200).json({ success: true, statusCode: 200, message: 'Flag resolved', data: { flag } });
});

/**
 * @desc    Ban a user (auth middleware already rejects banned users)
 * @route   POST /api/v1/admin/users/:id/ban  { reason? }
 * @access  Admin
 */
const banUser = asyncHandler(async (req, res) => {
  const user = await User.findByIdAndUpdate(
    req.params.id,
    {
      $set: { isBanned: true, banReason: req.body.reason || 'Terms of service violation' },
      $unset: { fcmToken: 1, refreshToken: 1 },
    },
    { new: true }
  ).select('firstName isBanned banReason');
  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }
  res.status(200).json({ success: true, statusCode: 200, message: 'User banned', data: { user } });
});

/**
 * @desc    Unban a user
 * @route   POST /api/v1/admin/users/:id/unban
 * @access  Admin
 */
const unbanUser = asyncHandler(async (req, res) => {
  const user = await User.findByIdAndUpdate(
    req.params.id,
    { $set: { isBanned: false }, $unset: { banReason: 1 } },
    { new: true }
  ).select('firstName isBanned');
  if (!user) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }
  res.status(200).json({ success: true, statusCode: 200, message: 'User unbanned', data: { user } });
});

module.exports = { getReports, resolveReport, getModerationFlags, resolveModerationFlag, banUser, unbanUser };
```

- [ ] **Step 3: Create routes and mount**

```js
// src/routes/admin.routes.js
const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { adminAuth } = require('../middleware/adminAuth');

// All admin routes require the x-admin-key header
router.use(adminAuth);

router.get('/reports', adminController.getReports);
router.patch('/reports/:id', adminController.resolveReport);
router.get('/moderation-flags', adminController.getModerationFlags);
router.patch('/moderation-flags/:id', adminController.resolveModerationFlag);
router.post('/users/:id/ban', adminController.banUser);
router.post('/users/:id/unban', adminController.unbanUser);

module.exports = router;
```

In `src/routes/index.js`: add `const adminRoutes = require('./admin.routes');` and `router.use('/admin', adminRoutes);` after the `/safety` mount.

- [ ] **Step 4: Verify boot + fail-closed behavior**

Run: `node -e "require('./src/routes/index.js'); console.log('routes OK')" && npm test`
Expected: `routes OK`, suite PASS

- [ ] **Step 5: Commit**

```bash
git add src/middleware/adminAuth.js src/controllers/admin.controller.js src/routes/admin.routes.js src/routes/index.js
git commit -m "feat(admin): review queue API — reports, moderation flags, ban/unban"
```

---

## Task 9: Account deletion (App Store Guideline 5.1.1(v))

**Files:**
- Modify: `boop-backend/src/services/profile.service.js` (add `deleteAccount`)
- Modify: `boop-backend/src/controllers/profile.controller.js` (add handler + export)
- Modify: `boop-backend/src/routes/profile.routes.js` (add `DELETE /`)
- Test: `boop-backend/tests/unit/profile.delete.test.js`

Design: hard-delete media from S3 and personal content from Mongo; anonymize the User document as a tombstone so the other side of historical matches doesn't break on populate.

- [ ] **Step 1: Write the failing test**

```js
// tests/unit/profile.delete.test.js
jest.mock('../../src/models/User');
jest.mock('../../src/models/Match');
jest.mock('../../src/models/Conversation');
jest.mock('../../src/models/Answer');
jest.mock('../../src/models/Interaction');
jest.mock('../../src/models/Notification');
jest.mock('../../src/services/upload.service');
jest.mock('../../src/utils/logger', () => ({
  debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn(),
}));
// profile.service pulls in several other services at module load — mock them too.
// If `require` fails on others, add the same one-line jest.mock for each import
// listed at the top of src/services/profile.service.js.
jest.mock('../../src/services/transcription.service', () => ({}), { virtual: true });
jest.mock('../../src/services/badge.service', () => ({ BadgeService: { checkAndAwardBadges: jest.fn() } }), { virtual: true });

const User = require('../../src/models/User');
const Match = require('../../src/models/Match');
const Conversation = require('../../src/models/Conversation');
const Answer = require('../../src/models/Answer');
const Interaction = require('../../src/models/Interaction');
const Notification = require('../../src/models/Notification');
const UploadService = require('../../src/services/upload.service');
const ProfileService = require('../../src/services/profile.service');

const USER_ID = 'aaaaaaaaaaaaaaaaaaaaaaaa';

beforeEach(() => {
  jest.clearAllMocks();
  UploadService._extractS3Key = jest.fn((u) => u);
  UploadService.cleanupOldFiles = jest.fn().mockResolvedValue(undefined);
  Match.updateMany.mockResolvedValue({});
  Conversation.updateMany.mockResolvedValue({});
  Answer.deleteMany.mockResolvedValue({});
  Interaction.deleteMany.mockResolvedValue({});
  Notification.deleteMany.mockResolvedValue({});
  User.findByIdAndUpdate.mockResolvedValue({});
});

describe('deleteAccount', () => {
  it('404s for unknown users', async () => {
    User.findById.mockResolvedValue(null);
    await expect(ProfileService.deleteAccount(USER_ID)).rejects.toMatchObject({ statusCode: 404 });
  });

  it('deletes media, personal content, and anonymizes the user', async () => {
    User.findById.mockResolvedValue({
      _id: USER_ID,
      photos: {
        items: [{ s3Key: 'k1' }, { s3Key: 'k2' }],
        profilePhoto: { s3Key: 'pp', blurredUrl: 'pb', silhouetteUrl: 'ps' },
      },
      voiceIntro: { s3Key: 'vi' },
    });

    await ProfileService.deleteAccount(USER_ID);

    expect(UploadService.cleanupOldFiles).toHaveBeenCalledWith(
      expect.arrayContaining(['k1', 'k2', 'pp', 'pb', 'ps', 'vi'])
    );
    expect(Match.updateMany).toHaveBeenCalled();
    expect(Conversation.updateMany).toHaveBeenCalled();
    expect(Answer.deleteMany).toHaveBeenCalledWith({ userId: USER_ID });
    expect(Interaction.deleteMany).toHaveBeenCalled();
    expect(Notification.deleteMany).toHaveBeenCalledWith({ userId: USER_ID });

    const [, update] = User.findByIdAndUpdate.mock.calls[0];
    expect(update.$set.isActive).toBe(false);
    expect(update.$set.firstName).toBe('Deleted');
    expect(update.$set.phone).toMatch(/^\+999\d+$/);
    expect(update.$unset).toMatchObject({ fcmToken: 1, refreshToken: 1, voiceIntro: 1 });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx jest tests/unit/profile.delete.test.js`
Expected: FAIL — `deleteAccount` is not a function

- [ ] **Step 3: Implement deleteAccount in profile.service.js**

Add this static method to the `ProfileService` class (User and UploadService are already imported in this file; add the lazy requires shown for the rest):

```js
  // ─── Delete Account ───────────────────────────────────────────

  /**
   * Permanently delete an account (App Store Guideline 5.1.1(v)).
   * Media is hard-deleted from S3; answers/interactions/notifications are
   * removed; the user document is anonymized as a tombstone so the other
   * side of historical matches doesn't break.
   */
  static async deleteAccount(userId) {
    const Match = require('../models/Match');
    const Conversation = require('../models/Conversation');
    const Answer = require('../models/Answer');
    const Interaction = require('../models/Interaction');
    const Notification = require('../models/Notification');

    const user = await User.findById(userId);
    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    // 1. Hard-delete media from S3
    const s3Keys = [];
    (user.photos?.items || []).forEach((p) => s3Keys.push(p.s3Key));
    const pp = user.photos?.profilePhoto;
    if (pp) {
      s3Keys.push(pp.s3Key);
      s3Keys.push(UploadService._extractS3Key(pp.blurredUrl));
      s3Keys.push(UploadService._extractS3Key(pp.silhouetteUrl));
    }
    if (user.voiceIntro?.s3Key) s3Keys.push(user.voiceIntro.s3Key);
    await UploadService.cleanupOldFiles(s3Keys.filter(Boolean));

    // 2. Archive matches + deactivate conversations
    await Match.updateMany(
      { users: userId, isActive: true },
      {
        $set: {
          isActive: false,
          stage: 'archived',
          archiveReason: 'other',
          archivedAt: new Date(),
          archivedBy: userId,
        },
      }
    );
    await Conversation.updateMany({ participants: userId }, { $set: { isActive: false } });

    // 3. Delete personal content
    await Promise.all([
      Answer.deleteMany({ userId }),
      Interaction.deleteMany({ $or: [{ fromUser: userId }, { toUser: userId }] }),
      Notification.deleteMany({ userId }),
    ]);

    // 4. Anonymize the user document (tombstone)
    await User.findByIdAndUpdate(userId, {
      $set: {
        phone: `+999${Date.now()}`, // unique tombstone that passes E.164 validation
        phoneVerified: false,
        firstName: 'Deleted',
        isActive: false,
        'photos.items': [],
        'photos.totalPhotos': 0,
        questionsAnswered: 0,
      },
      $unset: {
        bio: 1,
        voiceIntro: 1,
        'photos.profilePhoto': 1,
        fcmToken: 1,
        refreshToken: 1,
        location: 1,
        dateOfBirth: 1,
        username: 1,
        badges: 1,
      },
    });

    logger.info(`Account deleted and anonymized: ${userId}`);
    return { deleted: true };
  }
```

Note: if `logger` isn't already imported in profile.service.js, add `const logger = require('../utils/logger');` at the top.

- [ ] **Step 4: Wire controller + route**

In `src/controllers/profile.controller.js` add (and include `deleteAccount` in `module.exports`):

```js
/**
 * @desc    Permanently delete the current user's account
 * @route   DELETE /api/v1/profile
 * @access  Private
 */
const deleteAccount = asyncHandler(async (req, res) => {
  await ProfileService.deleteAccount(req.user._id);
  res.status(200).json({
    success: true,
    statusCode: 200,
    message: 'Account deleted',
    data: { deleted: true },
  });
});
```

In `src/routes/profile.routes.js`, after the `GET /` route add:

```js
// DELETE /profile — Permanently delete the account (App Store 5.1.1(v))
router.delete('/', profileController.deleteAccount);
```

- [ ] **Step 5: Run tests**

Run: `npx jest tests/unit/profile.delete.test.js && npm test`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add src/services/profile.service.js src/controllers/profile.controller.js src/routes/profile.routes.js tests/unit/profile.delete.test.js
git commit -m "feat(account): permanent account deletion — S3 purge, content removal, tombstone"
```

---

## Task 10: Comfort score hardening (per-day caps, quality threshold, IST days)

**Files:**
- Modify: `boop-backend/src/utils/constants.js` (add COMFORT_LIMITS)
- Modify: `boop-backend/src/models/Match.js` (add comfortStats after comfortScoreUpdatedAt, ~line 98)
- Modify: `boop-backend/src/services/comfort.service.js` (rework factor computation)
- Test: `boop-backend/tests/unit/comfort.service.test.js`

Anti-gaming design:
- Only **text ≥ 20 chars, voice, image** messages count ("quality messages"); `system` (boops!) and `game_invite` never count.
- Per-IST-day caps: 30 messages, 3 voice notes, 3 long messages.
- `activeDays` computed on IST calendar days of quality messages and **persisted** to `match.comfortStats` for the reveal floor (Task 11).

- [ ] **Step 1: Write the failing test**

```js
// tests/unit/comfort.service.test.js
jest.mock('../../src/models/Match');
jest.mock('../../src/models/Conversation');
jest.mock('../../src/models/Message');
jest.mock('../../src/models/Game');
jest.mock('../../src/models/ScoreSnapshot');
jest.mock('../../src/utils/logger', () => ({
  debug: jest.fn(), info: jest.fn(), warn: jest.fn(), error: jest.fn(),
}));

const Match = require('../../src/models/Match');
const Conversation = require('../../src/models/Conversation');
const Message = require('../../src/models/Message');
const Game = require('../../src/models/Game');
const ScoreSnapshot = require('../../src/models/ScoreSnapshot');
const ComfortService = require('../../src/services/comfort.service');

const USER1 = 'aaaaaaaaaaaaaaaaaaaaaaaa';
const USER2 = 'bbbbbbbbbbbbbbbbbbbbbbbb';

const msg = (sender, type, text, daysAgo = 0) => ({
  senderId: sender,
  type,
  content: { text },
  createdAt: new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000),
});

const setupMocks = (messages, { completedGames = 0, deepGames = 0 } = {}) => {
  const match = {
    _id: 'match1',
    users: [USER1, USER2],
    comfortScore: 0,
    save: jest.fn().mockResolvedValue(undefined),
  };
  Match.findById.mockResolvedValue(match);
  Conversation.findOne.mockResolvedValue({ _id: 'conv1' });
  Message.find.mockReturnValue({
    select: jest.fn().mockReturnValue({
      lean: jest.fn().mockResolvedValue(messages),
    }),
  });
  Game.countDocuments
    .mockResolvedValueOnce(completedGames)
    .mockResolvedValueOnce(deepGames);
  ScoreSnapshot.findOne.mockReturnValue({
    sort: jest.fn().mockResolvedValue(null),
  });
  ScoreSnapshot.create.mockResolvedValue({});
  return match;
};

beforeEach(() => jest.clearAllMocks());

describe('comfort score hardening', () => {
  it('short-message spam cannot reach the reveal threshold', async () => {
    const messages = [];
    for (let i = 0; i < 100; i++) {
      messages.push(msg(USER1, 'text', 'k'));
      messages.push(msg(USER2, 'text', 'k'));
    }
    setupMocks(messages, { completedGames: 3, deepGames: 2 });

    const { score } = await ComfortService.calculateComfortScore('match1');
    expect(score).toBeLessThan(70);
  });

  it('a single-day flood of quality messages cannot reach the threshold', async () => {
    const longText = 'This is a long, genuinely substantive message to inflate volume.';
    const messages = [];
    for (let i = 0; i < 100; i++) {
      messages.push(msg(USER1, 'text', longText));
      messages.push(msg(USER2, 'text', longText));
    }
    setupMocks(messages, { completedGames: 3, deepGames: 2 });

    const { score } = await ComfortService.calculateComfortScore('match1');
    expect(score).toBeLessThan(70);
  });

  it('system messages (boops) never count', async () => {
    const messages = [];
    for (let i = 0; i < 200; i++) messages.push(msg(USER1, 'system', 'sent a boop! 💕'));
    setupMocks(messages);

    const { score, breakdown } = await ComfortService.calculateComfortScore('match1');
    expect(breakdown.messageVolume.value).toBe(0);
    expect(score).toBe(0);
  });

  it('a genuine multi-day conversation reaches the threshold', async () => {
    const longText =
      'A thoughtful message that says something real about my day and how I feel about it.';
    const messages = [];
    for (let day = 0; day < 10; day++) {
      for (let i = 0; i < 5; i++) {
        messages.push(msg(USER1, 'text', longText, day));
        messages.push(msg(USER2, 'text', longText, day));
      }
    }
    for (let day = 0; day < 4; day++) {
      messages.push(msg(USER1, 'voice', null, day));
    }
    setupMocks(messages, { completedGames: 3, deepGames: 2 });

    const { score } = await ComfortService.calculateComfortScore('match1');
    expect(score).toBeGreaterThanOrEqual(70);
  });

  it('persists activeDays and qualityMessages for the reveal floor', async () => {
    const messages = [
      msg(USER1, 'text', 'This message is definitely long enough to count.', 2),
      msg(USER2, 'text', 'This reply is also long enough to count toward quality.', 1),
      msg(USER1, 'text', 'And one more quality message today to make three days.', 0),
    ];
    const match = setupMocks(messages);

    await ComfortService.calculateComfortScore('match1');

    expect(match.comfortStats).toEqual({ activeDays: 3, qualityMessages: 3 });
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `npx jest tests/unit/comfort.service.test.js`
Expected: FAIL — spam tests score ≥ 70 and/or `comfortStats` undefined

- [ ] **Step 3: Add COMFORT_LIMITS to constants.js**

After `COMFORT_REVEAL_THRESHOLD` add (and export `COMFORT_LIMITS`):

```js
// Anti-gaming limits for the comfort score
const COMFORT_LIMITS = {
  MIN_QUALITY_TEXT_LENGTH: 20, // text shorter than this never counts
  MAX_MESSAGES_PER_DAY: 30, // per-day cap on messages counted toward volume
  MAX_VOICE_PER_DAY: 3, // per-day cap on voice notes counted
  MAX_LONG_MESSAGES_PER_DAY: 3, // per-day cap on "vulnerability" long messages
  MIN_ACTIVE_DAYS_FOR_REVEAL: 3, // reveal locked until this many distinct active days
};
```

- [ ] **Step 4: Add comfortStats to the Match schema**

In `src/models/Match.js`, after the `comfortScoreUpdatedAt` field (~line 98), add:

```js
    // Anti-gaming stats persisted by ComfortService (used by the reveal floor)
    comfortStats: {
      activeDays: { type: Number, default: 0 },
      qualityMessages: { type: Number, default: 0 },
    },
```

- [ ] **Step 5: Rework comfort.service.js**

Update the imports line to `const { COMFORT_WEIGHTS, COMFORT_LIMITS } = require('../utils/constants');` and add below the imports:

```js
const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

/** YYYY-MM-DD key for a date in IST */
const dayKeyIST = (date) =>
  new Date(new Date(date).getTime() + IST_OFFSET_MS).toISOString().split('T')[0];
```

Replace the body of `calculateComfortScore` from the `// ─── Factor 1` comment through the `const breakdown = {` assembly with:

```js
    // ─── Quality filter ───────────────────────────────────────────
    // Only real conversation counts: text (≥ min length), voice, image.
    // Never system (boops) or game_invite messages.
    const COUNTABLE_TYPES = ['text', 'voice', 'image'];
    const qualityMessages = messages.filter((m) => {
      if (!COUNTABLE_TYPES.includes(m.type)) return false;
      if (m.type !== 'text') return true;
      return (m.content?.text || '').trim().length >= COMFORT_LIMITS.MIN_QUALITY_TEXT_LENGTH;
    });

    // Group by IST calendar day for per-day caps
    const byDay = new Map();
    qualityMessages.forEach((m) => {
      const key = dayKeyIST(m.createdAt);
      if (!byDay.has(key)) byDay.set(key, []);
      byDay.get(key).push(m);
    });

    // ─── Factor 1: MESSAGE_VOLUME (per-day cap) ───────────────────
    let countedMessages = 0;
    byDay.forEach((dayMsgs) => {
      countedMessages += Math.min(dayMsgs.length, COMFORT_LIMITS.MAX_MESSAGES_PER_DAY);
    });
    const messageVolumeRaw = Math.min(countedMessages / 50, 1);

    // ─── Factor 2: MESSAGE_DEPTH (quality text only) ──────────────
    const textMessages = qualityMessages.filter(
      (m) => m.type === 'text' && m.content?.text
    );
    const avgLength =
      textMessages.length > 0
        ? textMessages.reduce((sum, m) => sum + (m.content.text?.length || 0), 0) /
          textMessages.length
        : 0;
    const messageDepthRaw = Math.min(avgLength / 100, 1);

    // ─── Factor 3: VOICE_ENGAGEMENT (per-day cap) ─────────────────
    let countedVoice = 0;
    byDay.forEach((dayMsgs) => {
      const dayVoice = dayMsgs.filter((m) => m.type === 'voice').length;
      countedVoice += Math.min(dayVoice, COMFORT_LIMITS.MAX_VOICE_PER_DAY);
    });
    const voiceEngagementRaw = Math.min(countedVoice / 5, 1);

    // ─── Factor 4: GAMES_COMPLETED ────────────────────────────────
    const gamesCompletedRaw = Math.min(completedGames / 3, 1);

    // ─── Factor 5: RESPONSE_CONSISTENCY (quality messages) ────────
    const user1Messages = qualityMessages.filter(
      (m) => m.senderId.toString() === user1Id
    ).length;
    const user2Messages = qualityMessages.filter(
      (m) => m.senderId.toString() === user2Id
    ).length;

    let responseConsistencyRaw = 0;
    if (user1Messages > 0 && user2Messages > 0) {
      const minMsgs = Math.min(user1Messages, user2Messages);
      const maxMsgs = Math.max(user1Messages, user2Messages);
      responseConsistencyRaw = minMsgs / maxMsgs;
    } else if (user1Messages > 0 || user2Messages > 0) {
      responseConsistencyRaw = 0.1;
    }

    // ─── Factor 6: ACTIVE_DAYS (IST, quality messages) ────────────
    const activeDayCount = byDay.size;
    const activeDaysRaw = Math.min(activeDayCount / 14, 1);

    // ─── Factor 7: VULNERABILITY_SIGNALS (per-day cap on long msgs)
    let countedLong = 0;
    byDay.forEach((dayMsgs) => {
      const dayLong = dayMsgs.filter(
        (m) => m.type === 'text' && (m.content?.text?.length || 0) > 200
      ).length;
      countedLong += Math.min(dayLong, COMFORT_LIMITS.MAX_LONG_MESSAGES_PER_DAY);
    });
    const photoMessages = qualityMessages.filter((m) => m.type === 'image').length;

    const deepGames = await Game.countDocuments({
      matchId,
      status: 'completed',
      'rounds.prompt.category': {
        $in: ['vulnerability', 'self-discovery', 'growth', 'connection'],
      },
    });

    const vulnerabilityScore =
      Math.min(countedLong / 10, 0.4) +
      Math.min(photoMessages / 3, 0.2) +
      Math.min(deepGames / 2, 0.4);
    const vulnerabilitySignalsRaw = Math.min(vulnerabilityScore, 1);
```

Keep the existing weighted-sum block unchanged, then update the breakdown details to reflect the new counting:

```js
    const breakdown = {
      messageVolume: {
        value: Math.round(messageVolumeRaw * 100),
        weight: COMFORT_WEIGHTS.MESSAGE_VOLUME,
        detail: `${countedMessages} quality messages counted (target: 50)`,
      },
      messageDepth: {
        value: Math.round(messageDepthRaw * 100),
        weight: COMFORT_WEIGHTS.MESSAGE_DEPTH,
        detail: `Avg ${Math.round(avgLength)} chars/msg (target: 100)`,
      },
      voiceEngagement: {
        value: Math.round(voiceEngagementRaw * 100),
        weight: COMFORT_WEIGHTS.VOICE_ENGAGEMENT,
        detail: `${countedVoice} voice messages counted (target: 5)`,
      },
      gamesCompleted: {
        value: Math.round(gamesCompletedRaw * 100),
        weight: COMFORT_WEIGHTS.GAMES_COMPLETED,
        detail: `${completedGames} games completed (target: 3)`,
      },
      responseConsistency: {
        value: Math.round(responseConsistencyRaw * 100),
        weight: COMFORT_WEIGHTS.RESPONSE_CONSISTENCY,
        detail: `${user1Messages} vs ${user2Messages} quality messages`,
      },
      activeDays: {
        value: Math.round(activeDaysRaw * 100),
        weight: COMFORT_WEIGHTS.ACTIVE_DAYS,
        detail: `${activeDayCount} active days (target: 14)`,
      },
      vulnerabilitySignals: {
        value: Math.round(vulnerabilitySignalsRaw * 100),
        weight: COMFORT_WEIGHTS.VULNERABILITY_SIGNALS,
        detail: `${countedLong} long msgs, ${photoMessages} photos, ${deepGames} deep games`,
      },
    };

    return ComfortService._saveAndReturn(match, score, breakdown, {
      activeDays: activeDayCount,
      qualityMessages: qualityMessages.length,
    });
```

Also delete the original standalone `deepGames` query further up if it would now be duplicated (the rework moves it inside Factor 7 — there must be exactly one `deepGames` query).

Update `_saveAndReturn` to accept and persist the stats:

```js
  static async _saveAndReturn(match, score, breakdown, stats = null) {
    match.comfortScore = score;
    match.comfortScoreUpdatedAt = new Date();
    match.comfortStats = stats || { activeDays: 0, qualityMessages: 0 };
    await match.save();
```

(rest of the method unchanged), and update the no-conversation early return (~line 45) to:

```js
      return ComfortService._saveAndReturn(match, 0, ComfortService._emptyBreakdown(), {
        activeDays: 0,
        qualityMessages: 0,
      });
```

- [ ] **Step 6: Run tests**

Run: `npx jest tests/unit/comfort.service.test.js && npm test`
Expected: all PASS. (Sanity-checked expectations: spam test ≈ 19, single-day flood ≈ 52, genuine multi-day ≈ 83.)

- [ ] **Step 7: Commit**

```bash
git add src/utils/constants.js src/models/Match.js src/services/comfort.service.js tests/unit/comfort.service.test.js
git commit -m "feat(comfort): anti-gaming — quality threshold, per-day caps, IST active days"
```

---

## Task 11: Minimum-active-days floor on photo reveal

**Files:**
- Modify: `boop-backend/src/services/match.service.js` (requestReveal, the CONNECTING gate ~line 332-352)

- [ ] **Step 1: Implement the floor**

In `src/services/match.service.js`, extend the constants import (line 3) to include `COMFORT_LIMITS`:

```js
const { CONNECTION_STAGES, STAGE_TRANSITIONS, COMFORT_REVEAL_THRESHOLD, COMFORT_LIMITS, DATE_READINESS_WEIGHTS } = require('../utils/constants');
```

In `requestReveal`, inside the `if (match.stage === CONNECTION_STAGES.CONNECTING)` block, update the post-recalculation refresh to also copy stats:

```js
        const updated = await Match.findById(matchId);
        if (updated) {
          match.comfortScore = updated.comfortScore;
          match.comfortStats = updated.comfortStats;
        }
```

Then, after the existing comfort-threshold check (`if (match.comfortScore < COMFORT_REVEAL_THRESHOLD) { ... }`) and before `match.stage = CONNECTION_STAGES.REVEAL_READY;`, insert:

```js
      // Anti-gaming floor: a high score earned in a burst isn't enough —
      // the connection must span real days.
      const activeDays = match.comfortStats?.activeDays || 0;
      if (activeDays < COMFORT_LIMITS.MIN_ACTIVE_DAYS_FOR_REVEAL) {
        const error = new Error(
          `You two are moving fast! Reveal unlocks after ${COMFORT_LIMITS.MIN_ACTIVE_DAYS_FOR_REVEAL} days of real conversation (you're on day ${activeDays}).`
        );
        error.statusCode = 400;
        throw error;
      }
```

- [ ] **Step 2: Verify**

Run: `npm test`
Expected: all suites PASS.

Manual verification note: requestReveal's mock surface is too large for a cheap unit test; the floor logic's input (`comfortStats.activeDays`) is covered by Task 10's persistence test. Verify end-to-end on the dev server in Task 17.

- [ ] **Step 3: Commit**

```bash
git add src/services/match.service.js
git commit -m "feat(comfort): require 3 distinct active days before photo reveal"
```

---

## Task 12: iOS — Firebase Crashlytics

**Files:**
- Modify: `boop-frontend/project.yml`

Firebase SPM 12.7.0 + `GoogleService-Info.plist` + `FirebaseApp.configure()` (PushNotificationService.swift:40) already exist — Crashlytics needs only the product dependency, dSYM format, and the upload script.

- [ ] **Step 1: Edit project.yml**

Under `targets.Boop.dependencies`, after the `FirebaseMessaging` entry add:

```yaml
      - package: Firebase
        product: FirebaseCrashlytics
```

Under `targets.Boop.settings.base` add:

```yaml
        DEBUG_INFORMATION_FORMAT: dwarf-with-dsym
```

Under `targets.Boop` (same indent level as `settings:`) add:

```yaml
    postBuildScripts:
      - name: Crashlytics dSYM Upload
        script: "\"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run\""
        inputFiles:
          - ${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${TARGET_NAME}
          - $(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist
        basedOnDependencyAnalysis: false
```

- [ ] **Step 2: Regenerate and build**

Run: `cd "/Users/nirpekshnandan/My Products/boop-frontend" && xcodegen generate && xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Enable Crashlytics in the Firebase console**

Manual founder step (note in final summary): Firebase console → project → Crashlytics → Enable. No code change needed.

- [ ] **Step 4: Commit**

```bash
git add project.yml
git commit -m "feat(observability): Firebase Crashlytics + dSYM upload"
```

---

## Task 13: iOS — Safety API endpoints + models

**Files:**
- Create: `boop-frontend/Boop/Models/SafetyModels.swift`
- Modify: `boop-frontend/Boop/Core/Network/APIEndpoint.swift`

- [ ] **Step 1: Create SafetyModels.swift**

```swift
import Foundation

struct ReportUserRequest: Encodable {
    let userId: String
    let reason: String
    let details: String?
    let contentType: String
}

enum ReportReason: String, CaseIterable, Identifiable {
    case harassment
    case inappropriateMessages = "inappropriate_messages"
    case inappropriatePhotos = "inappropriate_photos"
    case fakeProfile = "fake_profile"
    case underage
    case spam
    case safetyConcern = "safety_concern"
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .harassment: return "Harassment or bullying"
        case .inappropriateMessages: return "Inappropriate messages"
        case .inappropriatePhotos: return "Inappropriate photos"
        case .fakeProfile: return "Fake profile / catfishing"
        case .underage: return "Appears to be under 18"
        case .spam: return "Spam or scam"
        case .safetyConcern: return "I'm concerned about my safety"
        case .other: return "Something else"
        }
    }
}
```

- [ ] **Step 2: Add endpoints to APIEndpoint.swift**

Add cases (after the Messages group):

```swift
    // Safety
    case blockUser(userId: String)
    case unblockUser(userId: String)
    case getBlockedUsers
    case reportUser(ReportUserRequest)
    case deleteAccount
```

In `path`, add:

```swift
        case .blockUser: return "/safety/block"
        case .unblockUser(let userId): return "/safety/block/\(userId)"
        case .getBlockedUsers: return "/safety/blocked"
        case .reportUser: return "/safety/report"
        case .deleteAccount: return "/profile"
```

In `method`: add `.blockUser, .reportUser` to the `.POST` group, `.getBlockedUsers` to the `.GET` group, and `.unblockUser, .deleteAccount` to the `.DELETE` group.

In `body`, add:

```swift
        case .blockUser(let userId): return ["userId": userId]
        case .reportUser(let req): return req
```

- [ ] **Step 3: Build**

Run: `xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Boop/Models/SafetyModels.swift Boop/Core/Network/APIEndpoint.swift
git commit -m "feat(safety): block/report/delete-account API endpoints"
```

---

## Task 14: iOS — ReportUserSheet component

**Files:**
- Create: `boop-frontend/Boop/Features/Safety/ReportUserSheet.swift`

⚠️ Before writing: open `Boop/DesignSystem/Components/BoopButton.swift` and `BoopTextField.swift` and match their exact initializer signatures (e.g. whether BoopButton takes `isLoading:`); also confirm `BoopColors.error`/`BoopColors.success` exist in `BoopColors.swift` (fall back to `.red`/`.green` system styles if not). Adjust the code below to the real APIs — do not invent parameters.

- [ ] **Step 1: Create the sheet**

```swift
import SwiftUI

/// Reusable report flow: pick a reason, add optional details, submit.
/// Presented from chat and match detail.
struct ReportUserSheet: View {
    let userId: String
    let userName: String
    var contentType: String = "profile"

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var details = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var submitted = false

    var body: some View {
        NavigationStack {
            Group {
                if submitted {
                    confirmationView
                } else {
                    formView
                }
            }
            .navigationTitle("Report \(userName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var formView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BoopSpacing.md) {
                Text("Your report is anonymous — \(userName) won't know you reported them.")
                    .font(BoopTypography.caption)
                    .foregroundStyle(BoopColors.textSecondary)

                ForEach(ReportReason.allCases) { reason in
                    Button {
                        selectedReason = reason
                    } label: {
                        HStack {
                            Text(reason.label)
                                .font(BoopTypography.callout)
                                .foregroundStyle(BoopColors.textPrimary)
                            Spacer()
                            Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedReason == reason ? BoopColors.primary : BoopColors.textMuted)
                        }
                        .padding(BoopSpacing.md)
                        .boopCard(radius: BoopRadius.lg)
                    }
                }

                BoopTextField(
                    label: "Anything else? (optional)",
                    placeholder: "Add details that will help our review",
                    text: $details
                )

                if let errorMessage {
                    Text(errorMessage)
                        .font(BoopTypography.caption)
                        .foregroundStyle(.red)
                }

                BoopButton(title: isSubmitting ? "Submitting…" : "Submit Report") {
                    Task { await submit() }
                }
                .disabled(selectedReason == nil || isSubmitting)
            }
            .padding(BoopSpacing.md)
        }
        .background(BoopColors.background)
    }

    private var confirmationView: some View {
        VStack(spacing: BoopSpacing.md) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Thanks for letting us know")
                .font(BoopTypography.headline)
            Text("Our team will review this report. If you'd rather not hear from \(userName) again, you can also block them.")
                .font(BoopTypography.callout)
                .foregroundStyle(BoopColors.textSecondary)
                .multilineTextAlignment(.center)
            BoopButton(title: "Done") { dismiss() }
        }
        .padding(BoopSpacing.lg)
    }

    private func submit() async {
        guard let reason = selectedReason else { return }
        isSubmitting = true
        errorMessage = nil
        do {
            try await APIClient.shared.requestVoid(
                .reportUser(ReportUserRequest(
                    userId: userId,
                    reason: reason.rawValue,
                    details: details.isEmpty ? nil : details,
                    contentType: contentType
                ))
            )
            submitted = true
        } catch {
            errorMessage = "Couldn't submit the report. Please try again."
        }
        isSubmitting = false
    }
}
```

- [ ] **Step 2: Build**

Run: `xcodegen generate && xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED` (xcodegen run because a new file/directory was added)

- [ ] **Step 3: Commit**

```bash
git add Boop/Features/Safety/ReportUserSheet.swift project.yml
git commit -m "feat(safety): reusable ReportUserSheet"
```

---

## Task 15: iOS — Report/Block in chat

**Files:**
- Modify: `boop-frontend/Boop/Features/Chat/Views/ChatInboxView.swift` (ChatConversationView, ~line 214-380)

⚠️ Verify the other-user id property: check `ConversationOtherUser` in `Boop/Models/InteractionModels.swift` (~line 180+) — the backend sends `userId`. Use the actual property name.

- [ ] **Step 1: Add state + dismiss to ChatConversationView**

Add alongside the existing `@State` vars (~line 217):

```swift
    @Environment(\.dismiss) private var dismiss
    @State private var showReportSheet = false
    @State private var showBlockConfirm = false
```

- [ ] **Step 2: Add the options menu to the toolbar**

After the existing `topBarTrailing` ToolbarItem (the media-gallery NavigationLink, ~line 367-375), add a second one:

```swift
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showReportSheet = true
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                    Button(role: .destructive) {
                        showBlockConfirm = true
                    } label: {
                        Label("Block", systemImage: "hand.raised")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Conversation options")
            }
```

- [ ] **Step 3: Add sheet + confirmation dialog + block action**

After the `.toolbar { ... }` modifier add:

```swift
        .sheet(isPresented: $showReportSheet) {
            ReportUserSheet(
                userId: conversation.otherUser.userId ?? "",
                userName: conversation.otherUser.firstName ?? "this user",
                contentType: "message"
            )
        }
        .confirmationDialog(
            "Block \(conversation.otherUser.firstName ?? "this user")?",
            isPresented: $showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button("Block", role: .destructive) {
                Task { await blockOtherUser() }
            }
        } message: {
            Text("They won't be able to message you, this match will be removed, and they won't appear in Discover. They won't be notified.")
        }
```

And add the method to ChatConversationView:

```swift
    private func blockOtherUser() async {
        guard let userId = conversation.otherUser.userId else { return }
        do {
            try await APIClient.shared.requestVoid(.blockUser(userId: userId))
            dismiss()
        } catch {
            // Block failed — leave the conversation open; user can retry
        }
    }
```

- [ ] **Step 4: Build + commit**

Run: `xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`

```bash
git add Boop/Features/Chat/Views/ChatInboxView.swift
git commit -m "feat(safety): report and block from chat"
```

---

## Task 16: iOS — Report/Block in match detail

**Files:**
- Modify: `boop-frontend/Boop/Features/Matches/Views/MatchDetailView.swift`

⚠️ Verify the other-user id property on the match-detail model: the view uses `viewModel.detail?.otherUser?...` — check the model backing it (likely in `Boop/Models/InteractionModels.swift` or `Boop/Features/Matches/`) for the user-id property name (backend sends `userId`).

- [ ] **Step 1: Add state, toolbar menu, sheet, dialog**

Add to MatchDetailView's state:

```swift
    @Environment(\.dismiss) private var dismiss
    @State private var showReportSheet = false
    @State private var showBlockConfirm = false
```

Add a `.toolbar` modifier next to the existing `.navigationTitle` (~line 102):

```swift
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showReportSheet = true
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                    Button(role: .destructive) {
                        showBlockConfirm = true
                    } label: {
                        Label("Block", systemImage: "hand.raised")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("Match options")
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ReportUserSheet(
                userId: viewModel.detail?.otherUser?.userId ?? "",
                userName: viewModel.detail?.otherUser?.firstName ?? "this user",
                contentType: "profile"
            )
        }
        .confirmationDialog(
            "Block \(viewModel.detail?.otherUser?.firstName ?? "this user")?",
            isPresented: $showBlockConfirm,
            titleVisibility: .visible
        ) {
            Button("Block", role: .destructive) {
                Task { await blockOtherUser() }
            }
        } message: {
            Text("They won't be able to message you, this match will be removed, and they won't appear in Discover. They won't be notified.")
        }
```

And the method:

```swift
    private func blockOtherUser() async {
        guard let userId = viewModel.detail?.otherUser?.userId else { return }
        do {
            try await APIClient.shared.requestVoid(.blockUser(userId: userId))
            dismiss()
        } catch {
            // Block failed — keep the view open; user can retry
        }
    }
```

- [ ] **Step 2: Build + commit**

Run: `xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`

```bash
git add Boop/Features/Matches/Views/MatchDetailView.swift
git commit -m "feat(safety): report and block from match detail"
```

---

## Task 17: iOS — Delete Account in Profile + final verification

**Files:**
- Modify: `boop-frontend/Boop/Features/Profile/Views/ProfileView.swift` (~line 524, the Log Out button)

- [ ] **Step 1: Add state + the delete flow**

Add to ProfileView's state:

```swift
    @State private var showDeleteConfirm = false
    @State private var showDeleteError = false
    @State private var isDeleting = false
```

Directly below the existing `BoopButton(title: "Log Out", ...)` add:

```swift
            BoopButton(title: isDeleting ? "Deleting…" : "Delete Account", variant: .outline) {
                showDeleteConfirm = true
            }
            .disabled(isDeleting)
            .alert("Delete your account?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Forever", role: .destructive) {
                    Task { await deleteAccount() }
                }
            } message: {
                Text("This permanently deletes your profile, photos, voice intro, answers, matches, and conversations. This cannot be undone.")
            }
            .alert("Couldn't delete your account", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please check your connection and try again.")
            }
```

And the method on ProfileView:

```swift
    private func deleteAccount() async {
        isDeleting = true
        do {
            try await APIClient.shared.requestVoid(.deleteAccount)
            AuthManager.shared.logout()
        } catch {
            showDeleteError = true
        }
        isDeleting = false
    }
```

- [ ] **Step 2: Build + commit**

Run: `xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -5`
Expected: `BUILD SUCCEEDED`

```bash
git add Boop/Features/Profile/Views/ProfileView.swift
git commit -m "feat(account): permanent account deletion from Profile"
```

- [ ] **Step 3: Full verification sweep**

```bash
cd "/Users/nirpekshnandan/My Products/boop-backend" && npm test
cd "/Users/nirpekshnandan/My Products/boop-frontend" && xcodebuild -project Boop.xcodeproj -scheme Boop -destination 'generic/platform=iOS Simulator' build 2>&1 | tail -3
```
Expected: backend suite all green; `BUILD SUCCEEDED`.

- [ ] **Step 4: Deployment checklist (report to founder — do not deploy without confirmation)**

1. Server: `ADMIN_API_KEY` env var — generate with `openssl rand -hex 32`, add to `.env` on the box (SSM session), then `pm2 restart all`.
2. Verify moderation works live: `curl -s https://api.unmutee.in/api/v1/health` then send a test message on a dev account and check `moderationflags` collection.
3. Firebase console → Crashlytics → Enable (one-time).
4. App Store notes: the app now satisfies Guideline 1.2 (report + block for UGC) and 5.1.1(v) (account deletion).

---

## Out of scope (explicitly deferred)

- Admin web UI for the review queue (the API + curl/Postman is the v1 — build a UI when report volume justifies it).
- Photo *verification* (liveness/anti-catfish) — separate feature-level work, queued behind this.
- Blocked-users management screen in iOS settings (the `getBlockedUsers` endpoint exists; UI can follow).
- Retroactive moderation of pre-existing content.
