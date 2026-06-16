# UnMutee — Monetisation & Subscriptions Design

**Date:** 2026-06-16
**Status:** Draft for review
**Authors:** Nirpeksh, Pratiksha (with Claude as CEO/CFO sparring partner)
**Scope:** iOS app (`boop-frontend`, SwiftUI) + backend (`boop-backend`, Node/Express/MongoDB). This spec spans both repositories.

---

## 1. Goal & Context

UnMutee is currently 100% free. The `User` model already carries unused `isPremium` / `premiumExpiry` stubs. This spec defines the first revenue system: a single Premium subscription, two consumables, marketplace-balancing grants for women, a founders' admin panel, and the legal/compliance scaffolding required to charge Indian consumers lawfully.

**Decisions already made (founders, 2026-06-16):**

| Decision | Choice |
|---|---|
| Tier model | One Premium tier + consumables (Gold tier deferred to v2) |
| Premium pricing (India, App Store, GST-inclusive) | ₹599 / month · ₹1,499 / 3 months · ₹3,999 / 12 months |
| Paywall lead | Annual plan, framed as "₹333/mo" |
| Free trial | 7-day free trial for new subscribers |
| Founding Member offer | 50% off locked for 12 months (launch window only) |
| Verified-women offer | 3 months Premium free, then standing 50% off |
| Consumables at launch | Boost (₹199) + Super Connect |
| Initial build scope | iOS / Apple IAP only (Android Play Billing + web deferred) |

**The decisive economic fact:** Apple IAP is **mandatory** for digital subscriptions on iOS in India (no Razorpay/UPI in-app; none of the US/EU/Netherlands carve-outs apply). Apple is therefore the **merchant of record**: it collects payment, complies with RBI e-mandate rules, **remits the 18% GST**, and processes refunds. We receive net proceeds and our job is purely **entitlement management**. Enrolling in the **Apple Small Business Program** gives us **15% commission from day one** (vs 30%).

**Net unit economics (₹599/mo @ 15% commission):** ₹599 − ₹91 GST − ₹76 commission = **~₹432 net**, against ~₹5–15/mo variable cost to serve → **~95% contribution margin**. The business is structurally unit-economics positive; the constraint is conversion and CAC, not cost.

---

## 2. Non-Goals (explicitly out of scope for v1)

- **Android / Google Play Billing** — added when the Android app is launch-ready (entitlement core is designed store-agnostic to make this cheap later).
- **Razorpay / web checkout** — cannot be linked or promoted inside the iOS app in India (Apple anti-steering); no near-term payoff.
- **Second "Gold" tier** — deferred to v2 pending conversion data.
- **Automated face/ID-based women verification** — v1 uses manual admin review (low launch volume).
- **Automated consumption-request refund decisioning** (`CONSUMPTION_REQUEST`) — we will revoke entitlement on `REFUND`, but not build automated refund-influence logic in v1.
- **GST invoicing to consumers** — Apple remits consumer GST; not our responsibility.

---

## 3. System Architecture

```
┌─────────────────────────┐         ┌──────────────────────────────┐
│  iOS App (SwiftUI)       │         │  Apple App Store / StoreKit  │
│  - PaywallView           │◄───────►│  - Subscriptions (IAP)       │
│  - StoreService (SK2)    │ purchase│  - Consumables (IAP)         │
│  - EntitlementStore      │         │  - Offer codes / intro offer │
└───────────┬─────────────┘         └──────────────┬───────────────┘
            │ JWS transaction                       │ Server Notifications V2 (JWS)
            ▼                                        ▼
┌──────────────────────────────────────────────────────────────────┐
│  Backend (Node/Express/MongoDB)                                    │
│  - subscription.service  (entitlement = single source of truth)   │
│  - appstore.service      (App Store Server API + JWS verify)      │
│  - consumable.service    (Boost / Super Connect credits + effects)│
│  - appstoreWebhook.controller (notifications endpoint)            │
│  - admin/*               (founders' panel: grants, verify, codes) │
│  - gating in discover.service / match flow                        │
└──────────────────────────────────────────────────────────────────┘
```

**Source of truth:** the backend computes entitlement, not the client. The client renders based on a server-provided entitlement object and StoreKit's local entitlements only as an optimistic hint. The server reconciles via Apple's App Store Server API (`Get All Subscription Statuses` by `originalTransactionId`) and Server Notifications V2.

---

## 4. Entitlement Model (backend, store-agnostic)

A user's access is the **union** of (a) an active store subscription and (b) any active grant (comp / women-promo / founding). This abstraction lets Android slot in later without touching gating logic.

```
User.subscription = {
  status: 'none' | 'trialing' | 'active' | 'grace' | 'expired' | 'cancelled',
  tier: 'premium',                 // only tier in v1
  source: 'apple',                 // 'google' later
  productId: String,               // e.g. com.unmutee.premium.annual
  originalTransactionId: String,   // Apple primary key for the subscription
  expiresAt: Date,
  autoRenew: Boolean,
  isTrial: Boolean,
  environment: 'sandbox' | 'production'
}

User.grants = [{
  type: 'women_promo' | 'comp' | 'founding',
  tier: 'premium',
  startsAt: Date,
  endsAt: Date | null,             // null = indefinite (comp)
  grantedBy: ObjectId(Admin) | 'system',
  note: String
}]

User.consumables = { boostCredits: Number, superConnectCredits: Number }

User.genderVerification = {
  status: 'none' | 'pending' | 'approved' | 'rejected',
  submittedAt: Date, reviewedAt: Date, reviewedBy: ObjectId(Admin),
  assetKey: String                 // S3 key of the verification selfie
}

// Derived & denormalised for fast reads (kept in sync by subscription.service):
User.isPremium: Boolean
User.premiumExpiry: Date
```

**`isPremium` computation:** `true` if `subscription.status ∈ {trialing, active, grace}` **or** any grant with `startsAt ≤ now < (endsAt ?? ∞)`. Recomputed on every store notification, on grant change, and lazily on read if `premiumExpiry` has passed.

**Active boost:** stored on the consumable effect, not the user doc — see §7.

---

## 5. Apple IAP Integration

### 5.1 Products (configured in App Store Connect)

**Subscription group `unmutee_premium`** (auto-renewable):
- `com.unmutee.premium.monthly` — ₹599
- `com.unmutee.premium.quarterly` — ₹1,499
- `com.unmutee.premium.annual` — ₹3,999

**Offers on the subscription group:**
- **Introductory Offer — 7-day free trial** (new subscribers, auto-applied). One intro offer per subscription group per Apple ID.
- **Founding Member — Offer Code**, 50% off for 12 months. Delivered as an **Offer Code** (not an intro offer) so it can be redeemed independently of intro-offer eligibility.
  - **Constraint:** Apple applies **one offer per purchase**. A user redeeming the Founding offer code does **not** also get the 7-day trial on that transaction — and does not need to (50%/12mo is the stronger deal). Two distinct funnels:
    - *Standard funnel:* 7-day free trial → standard price.
    - *Founding funnel:* redeem code → 50% off for 12 months → standard price at renewal.
- **Verified-women 50%-off (post-3-months)** — delivered as an **Offer Code** issued after the women-promo grant expires.

**Consumables (IAP):**
- `com.unmutee.boost` — ₹199 (1 boost)
- `com.unmutee.superconnect.single` — Super Connect (price TBD in §13)

> **Founding "50% for 12 months" mapping note:** Apple offer codes express discounts as a price + duration on a specific plan. We will configure the Founding code on the **monthly** and **quarterly** plans as a recurring 50% discount for the first 12 months, and on **annual** as a 50%-off first year (₹1,999). Exact App Store Connect offer configuration is an implementation task, not a design decision.

### 5.2 Client (iOS, StoreKit 2)

- `StoreService` loads products, presents purchase, handles the offer-code redemption sheet, and `Transaction.updates`.
- On a successful purchase/restore, send the **signed JWS transaction** to the backend for verification; do **not** unlock features on client trust alone.
- **Restore Purchases** supported.
- **Manage / Cancel** deep-links to Apple subscription settings (`showManageSubscriptions`) — we never build a fake cancel flow (CCPA "Subscription Trap" compliance).
- **Paywall** displays: all three plans (annual highlighted), the 7-day-trial disclosure, **auto-renew terms**, price, and links to ToS / Privacy / Refund policy (mandatory).

### 5.3 Server verification & reconciliation

- `appstore.service`:
  - Authenticates to the **App Store Server API** with an ASC API key (JWT, ES256).
  - Verifies the JWS transaction signature against Apple root certificates.
  - Calls **`Get All Subscription Statuses`** by `originalTransactionId` to establish authoritative state.
  - Maps Apple status → our `subscription.status`.
- `subscription.controller` endpoints (client-facing, authed):
  - `POST /api/v1/subscription/verify` — body: JWS transaction → verify, upsert subscription, return entitlement.
  - `GET /api/v1/subscription/entitlement` — current entitlement object for the user.
- **App Store Server Notifications V2** webhook: `POST /api/v1/webhooks/appstore` (no user auth; verifies Apple JWS signature). Handles: `SUBSCRIBED`, `DID_RENEW`, `DID_CHANGE_RENEWAL_STATUS`, `DID_CHANGE_RENEWAL_PREF`, `EXPIRED`, `GRACE_PERIOD_EXPIRED`, `REFUND`, `REVOKE`, `OFFER_REDEEMED`. Each updates `subscription` + recomputes `isPremium`. On `REFUND`/`REVOKE` → revoke entitlement immediately.
- **Billing grace period** enabled in App Store Connect (16 days) → `status: 'grace'` keeps access during payment-retry (involuntary churn handling).
- Every notification is persisted to a `SubscriptionEvent` collection (idempotent on Apple's `notificationUUID`) for audit and replay.

---

## 6. Free vs Premium Gating

Gate the **amplifiers**, never the **soul** (conversation). Free limits live in `boop-backend/src/utils/constants.js`.

| Capability | Free | Premium |
|---|---|---|
| Personality questions + basic archetype reveal | ✅ | ✅ |
| **Chat with matches (text/voice/images/reactions)** | ✅ unlimited | ✅ unlimited |
| Comfort-score → reveal mechanic, games | ✅ | ✅ |
| Discover cards / day | 5 | unlimited |
| Connects (likes) / day | 3 | unlimited |
| "X people liked you" | count only, identities blurred | **see who liked you** |
| Full personality report + numerology + premium share cards | basic only | ✅ |
| AI relationship insights + AI conversation openers | ❌ | ✅ |
| AI date concierge (venues/coaching) | ❌ | ✅ |
| Priority placement in others' Discover | ❌ | ✅ |
| Incognito / private browsing | ❌ | ✅ |
| Monthly Boost included | ❌ | 1 / month |

**Enforcement:** server-side in `discover.service` (daily counters with IST midnight reset, reusing the existing cron infra) and in the like/connect controller. The "see who liked you" endpoint returns blurred identities for free users. Client mirrors limits for UX but the server is authoritative.

---

## 7. Consumables — Boost & Super Connect

- **Boost (₹199):** raises the user's ranking in others' Discover for a fixed window (default 30 min). On verified purchase, `consumable.service` credits `boostCredits`; on activation it writes an `activeBoost { startsAt, endsAt }` record consulted by `discover.service` ranking. Premium users get 1 free boost/month (granted on renewal).
- **Super Connect:** a credit that elevates the user's Connect note to the **top of the recipient's pending queue** and visually flags it. Integrates with the existing Like/Connect → pending flow.
- Purchase path mirrors subscriptions: client sends JWS consumable transaction → `appstore.service` verifies → `consumable.service` credits balance → ledger entry in `PurchaseLedger`.
- Balances and a transaction ledger are exposed via `GET /api/v1/consumables` and debited server-side on use.

---

## 8. Grants — Verified Women & Comp

- **Women promo:** on `genderVerification.status → approved` (admin action), `subscription.service` creates a `women_promo` grant with `endsAt = now + 90 days`. On expiry, the user becomes eligible for a **50%-off Offer Code** (surfaced in-app and trackable in the admin panel).
- **Verification flow:** woman submits a live selfie → stored in S3 (private) → `genderVerification.status = pending` → appears in the admin **Verification Queue** → founder approves/rejects. Manual in v1.
- **Comp grants:** founders can grant Premium to influencers / support cases via the admin panel (indefinite or dated), recorded with `grantedBy` + `note`.

---

## 9. Admin Panel (founders)

A minimal authenticated web app served by the backend (separate from the consumer API surface).

- **Auth:** new `Admin` model (email + bcrypt password + role), **individual logins** (not one shared credential) for an audit trail. Session or short-lived JWT. Two seed accounts: Nirpeksh, Pratiksha.
- **Capabilities:**
  1. **Dashboard** — active / trialing subscribers, estimated net MRR, conversion %, churn, consumable revenue.
  2. **User lookup** — view subscription/entitlement; grant/revoke comp Premium.
  3. **Verification Queue** — review women-verification selfies → approve (triggers 90-day grant) / reject.
  4. **Discount requests & approvals** — a request → founder-approval workflow; on approval the system records issuance of an Apple Offer Code (or a comp grant). Codes are generated in App Store Connect / via App Store Server API and tracked here as an `OfferCode` pool with assignment + redemption status.
  5. **Audit log** — every admin action recorded (`AdminAuditLog`).
- **Note:** *paid* discounts must flow through Apple Offer Codes / Promotional Offers (we cannot arbitrarily discount Apple's charge); *free* grants we control directly via entitlements.

---

## 10. Legal & Compliance (gating requirement for launch)

| Item | Requirement | Notes |
|---|---|---|
| **Terms of Service** | Mandatory (IT Rules 2021, Contract Act) | 18+, acceptable use, subscription + auto-renew terms, governing law = India, India-based grievance officer. **No** US-style class-action waiver / US-seat arbitration. |
| **Privacy Policy** | Mandatory (SPDI Rules 2011, IT Rules 2021, DPDP s.5, Apple 5.1.1) | Orientation = SPDI today; treat orientation/location/photos as highest-risk. |
| **Refund & Cancellation Policy** | Mandatory (Consumer Protection Act 2019, E-Commerce Rules 2020) | State that Apple processes IAP refunds; how to cancel; no one-sided cancellation charges. |
| **Grievance Officer** | Named India contact, displayed in-app | Design to strictest combo: ack ≤24h, resolve ≤15 days. |
| **18+ age assurance** | Hard gate, **not a checkbox** (DPDP children's rules; ₹200cr exposure) | Onboarding already collects DOB → enforce a hard <18 block; strengthen beyond self-declaration. |
| **Auto-renew disclosure** | On the paywall (Apple + Indian dark-pattern law) | Price, renewal cadence, how to cancel. |
| **Dark patterns (CCPA 2023)** | Avoid "Subscription Trap" / "SaaS Billing" | Easy visible cancellation (deep link to Apple), no auto-debit for "free", affirmative consent (no pre-ticked boxes). |
| **DPDP readiness** | Consent (free/specific/unambiguous, easy withdrawal), itemized standalone notice, data-rights handling, 72h breach reporting | Act live; substantive deadline ~May 2027 — **build consent correctly now**. |
| **GST** | Not required until ₹20L aggregate turnover; Apple remits consumer GST | Register voluntarily at NewCo incorporation. |

Claude will draft ToS / Privacy / Refund policies to ~production grade; **a short Indian-lawyer review is required before go-live** given the sensitive-data and children's-data risk profile.

---

## 11. Data Model Changes (MongoDB)

**Modified:** `User` — add `subscription`, `grants[]`, `consumables`, `genderVerification`; keep `isPremium`/`premiumExpiry` as derived.

**New collections:**
- `Admin` — founder accounts (email, passwordHash, role, name).
- `SubscriptionEvent` — store notifications (idempotent on `notificationUUID`), for audit/replay.
- `PurchaseLedger` — every verified purchase (subscription + consumable) and grant.
- `OfferCode` — issued Apple offer codes: campaign, code, assignedTo, status.
- `DiscountRequest` — approval workflow records.
- `AdminAuditLog` — admin actions.

---

## 12. Build Phases

One cohesive system, built in revenue-first order. `writing-plans` will expand each into tasks.

- **Phase 1 — Core revenue (entitlement + subscription).** Entitlement model; `appstore.service` (verify + status); `subscription` endpoints; Server Notifications V2 webhook; iOS `StoreService` + `PaywallView` + gating for the §6 matrix; restore/manage; auto-renew disclosure. **Plus the §10 legal docs + 18+ gate** (cannot ship payments without these). → *First rupee.*
- **Phase 2 — Growth levers.** Admin panel (auth, dashboard, user lookup, comp grants, audit log); women-verification queue + 90-day grant + post-expiry 50% code; Founding Member offer-code issuance/tracking.
- **Phase 3 — Consumables.** Boost + Super Connect: products, purchase verification, balances/ledger, and the discover/match effects.

---

## 13. Open Questions / Assumptions

1. **Super Connect price** — assumed a single-credit consumable; price not yet set (suggest ₹99–149, or a pack). **Decision needed before Phase 3.**
2. **Grievance Officer name + contact** + the support/legal email domain (`unmutee.in` recommended over `scaleupapp.club` for consistency, since the API already runs on `api.unmutee.in`). **Needed for legal docs.**
3. **Operating entity at go-live** — ScaleUp Learning Technologies now vs. NewCo. Affects the App Store Connect account holder, bank, tax forms, and Small Business Program enrollment; switching later requires an app transfer + re-papering. **Decision needed before App Store Connect setup.**
4. **Daily free limits** — assumed 5 Discover / 3 Connects; tune with data.
5. **Boost window** — assumed 30 min; tune with data.
6. **Lawyer review** — one-time Indian-counsel sign-off on the three legal docs before go-live (assumed yes).

---

## 14. Testing Strategy

- **Backend unit tests (Jest):** entitlement computation (subscription × grant union, edge cases at boundaries/expiry/grace); JWS verification (valid/tampered); notification handlers (each type, idempotency on `notificationUUID`); free-limit enforcement; consumable credit/debit; admin auth + grant flows.
- **Apple sandbox:** full purchase / renew / cancel / refund / grace / restore / offer-code redemption against StoreKit sandbox; verify webhook → entitlement transitions.
- **iOS:** StoreKit configuration file for local testing; paywall states (trial-eligible vs founding vs returning); gating behaviour free vs premium.
- **Compliance smoke test:** paywall shows auto-renew + policy links; cancel deep-links to Apple; 18+ gate blocks under-18; consent screens present.
