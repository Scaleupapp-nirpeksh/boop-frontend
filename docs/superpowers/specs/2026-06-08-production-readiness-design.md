# UnMutee (Boop) — Production-Readiness & Security Hardening Spec

> **Date:** 2026-06-08
> **Author:** CTO (Claude) + Founder (Nirpeksh)
> **Status:** In progress
> **Scope:** Technical + security hardening of the existing platform. Monetization and product changes are explicitly **out of scope** for this effort (to be tackled later).

---

## 1. Context & Operating Assumptions

- **Product:** UnMutee (currently branded "Boop") — a compatibility-first / "personality before photos" dating app. Native iOS app + App Clip + Widget; Node.js/Express backend on a single EC2 box; MongoDB Atlas; Redis (local on box); AWS S3 for media; OpenAI for personality/embeddings/transcription; Twilio OTP; Firebase FCM push; Socket.IO realtime.
- **No real users yet.** This is the single most important constraint: it means we can make **breaking changes, re-point IPs/URLs, rename, and even wipe/reseed the DB without migration risk or downtime concerns.** Strategy is therefore a clean, aggressive cutover rather than zero-downtime choreography.
- **Rebrand:** "Boop" → "UnMutee". Decision: change **display name, assets, and API host only**. The **bundle IDs stay `com.influhitch.boop*`** (internal identifiers, invisible to users; changing them would needlessly destroy the App Store Connect record, Firebase registration, and provisioning profiles).
- **Domain:** `unmutee.in` (registered via Route53 during this effort). API will be served at `https://api.unmutee.in`.
- **Access model:** AWS SSM Session Manager (no SSH keys, no public port 22). Founder-provided IAM access keys are temporary and **will be rotated at end of session**.

---

## 2. Live Infrastructure Findings (recon 2026-06-08)

AWS account `854781667410`, region `ap-south-1` (Mumbai).

| Resource | Value |
|---|---|
| Instance | `i-056f61b97f67460df` — `boop-backend`, t3.small, Ubuntu (AMI `ami-07216ac99dc46a187`) |
| Public IP | `35.154.171.1` — **ephemeral (NOT an Elastic IP)** |
| Security group | `sg-0d15243b5e462f305` |
| Root volume | `vol-07a3800ddaf384e61` — 20 GB gp3, **unencrypted** |
| Web server | nginx 1.18.0 on :80 → Node app on :3000 |
| Runtime | MongoDB Atlas connected, Redis local, `NODE_ENV=production` |
| S3 bucket | `boop-uploads` |
| GitHub | `Scaleupapp-nirpeksh/boop-backend` |

### Security issues found
| # | Issue | Severity |
|---|---|---|
| S1 | **All traffic is plaintext HTTP/ws** — no TLS listening on :443 (faces, voices, locations, intimate answers in the clear) | 🔴 Critical |
| S2 | SSH (22) open to `0.0.0.0/0` | 🔴 High |
| S3 | Raw Node app (3000) exposed to `0.0.0.0/0`, bypassing nginx | 🔴 High |
| S4 | No IAM role on instance → app uses **static AWS keys in `.env`** | 🔴 High |
| S5 | Public IP is ephemeral → stop/start silently breaks the hardcoded app URL | 🔴 High |
| S6 | Root EBS volume unencrypted at rest | 🟠 Medium |
| S7 | CORS wildcard `*`, helmet/CSP disabled, `x-powered-by` on | 🟠 Medium |
| S8 | Rate limiting per-IP only (ineffective behind India mobile NAT); OTP abuse possible | 🟠 Medium |
| S9 | No DB transactions → mutual-match creation can race/double-write | 🟠 Medium |
| G1 | `.env` **never committed to git** (good — gitignored). Secrets only live on the box. | ✅ (verified) |

---

## 3. Phased Plan

### Phase 0 — Access & safety net  *(via temporary keys, this session)*
- [x] Full EBS snapshot as rollback point — `snap-01b60edb0592b1ce1`
- [x] IAM role `unmutee-backend-role` (SSM core + S3 scoped to `boop-uploads`) + instance profile `unmutee-backend-profile`, associated to instance
- [ ] Confirm SSM agent online → secure shell established

### Phase 1 — Network / firewall  *(this session)*
- [ ] Allocate + associate **Elastic IP** (stable address)
- [ ] SG lockdown: remove `0.0.0.0/0` from **3000** and **22** (22 only after SSM proven); keep 80 (ACME + redirect) + 443
- [ ] Encrypt root volume at rest (snapshot → encrypted copy → swap; one stop/start window)

### Phase 2 — TLS + domain  *(after unmutee.in active)*
- [ ] Route53 zone for `unmutee.in` (auto-created on registration); `A` record `api.unmutee.in → EIP`
- [ ] nginx: `server_name api.unmutee.in`, Let's Encrypt cert, HTTP→HTTPS redirect, HSTS, version hidden, body-size limits, security headers
- [ ] Socket.IO over **wss://**

### Phase 3 — Application security  *(backend code)*
- [ ] Delete static AWS keys from `.env` (IAM role replaces them); lock `.env` perms; consider SSM Parameter Store
- [ ] Rotate secrets (OpenAI, Twilio, Firebase, JWT) as hygiene
- [ ] CORS → strict allowlist; enable helmet/CSP; disable `x-powered-by`
- [ ] Per-user rate limits + OTP abuse protection (per-phone throttle, attempt lockout)
- [ ] DB transaction for mutual-match creation; verify indexes
- [ ] `npm audit` fixes; body-size limits; PII/secret scrubbing in logs

### Phase 4 — Rebrand → UnMutee
- [ ] Backend: API strings, package name, health message
- [ ] iOS: display name, logo/assets, base URL → `api.unmutee.in`, associated domains. **Bundle IDs unchanged.**
- [ ] (Flag only) the in-app "boop" nudge feature name is a separate product decision — not touched here.

### Phase 5 — Stability & observability
- [ ] Fix onboarding question-flow bugs + the **6-vs-15 answer contract mismatch** (frontend lets users in at 6; backend marks ready at 15)
- [ ] Process manager (systemd/pm2) auto-restart + log rotation
- [ ] CloudWatch alarms (CPU/disk/health) + automated daily EBS snapshots (DLM)

---

## 4. Decisions Log
- Keep bundle IDs `com.influhitch.boop*` (display-name rebrand only).
- SSM over SSH for server access; SSH kept until SSM proven, then closed.
- Register `unmutee.in` via Route53 ($8/yr, privacy on, auto-renew on), reusing the existing `calledit.in` company contact.
- Aggressive cutover acceptable (no users).

## 5. Rollback
- Pre-hardening snapshot `snap-01b60edb0592b1ce1` restores the box.
- All SG/IP/IAM changes are individually reversible via the AWS console/CLI.

---

## 6. Progress — 2026-06-08 (Session 1)

**DONE & verified:**
- ✅ Domain `unmutee.in` registered (Route53, privacy + auto-renew). Hosted zone `Z07246543LAT1IZ8C6DSA`. `api.unmutee.in` A-record live.
- ✅ **HTTPS live** at `https://api.unmutee.in` — Let's Encrypt cert (exp 2026-09-06, auto-renew via certbot.timer), HTTP→HTTPS 301, HSTS + `X-Content-Type-Options`/`X-Frame-Options`/`Referrer-Policy`, TLS1.2/1.3, websocket(wss) preserved. **(S1 fixed)**
- ✅ Firewall: port 3000 removed from `0.0.0.0/0`; app only reachable via nginx. **(S3 fixed)**
- ✅ IAM role `unmutee-backend-role` (SSM core + S3 scoped to `boop-uploads`) attached; **SSM Session Manager online** (no SSH keys needed). **(access modernized)**
- ✅ Safety snapshot `snap-01b60edb0592b1ce1`.
- ✅ pm2 reboot persistence (`pm2-ubuntu` systemd unit) — app now survives reboot.
- ✅ Automated daily backups (DLM `policy-0277ede159b326f35`, retain 7).
- ✅ CloudWatch alarms (`unmutee-instance-status-failed`, `unmutee-cpu-high`) → SNS `unmutee-alerts`.
- ✅ Verified `.env` never committed to git (secrets only on box).

- ✅ **Elastic IP `3.6.127.127`** allocated + associated (EIP quota raised 5→8). `api.unmutee.in` repointed; HTTPS verified on new IP. **(S5 fixed)**
- ✅ **Phase 3 app hardening deployed** (commits `bd9d67f`, `2e1c4d2`, `39493ba`): `trust proxy=1` (verified real client IPs in logs), CORS allowlist via `CORS_ORIGINS` (mobile unaffected), rate limits 100→300 / 10→20 for CGNAT, **static AWS keys removed from `.env`** (app on IAM role; verified S3 RW + presigned), `.env` chmod 600, `npm audit fix` cleared **critical + all 7 high** vulns. **(S4, S7, S8 fixed)**

- ✅ **Match unique-index bug fixed** (commit `15f7979` + live migration): backfilled `pairKey` on 3 existing matches, dropped unique `users_1`, added unique `pairKey_1` + non-unique `users_1`. Users can now hold multiple matches; duplicate pairs still blocked.
- ✅ **Phase 4 — iOS repoint + rebrand** (working-tree edits, founder to build): `APIClient`/`RealtimeService`/App-Clip → `https://api.unmutee.in`; display name + permission strings → UnMutee; **removed insecure-HTTP ATS exception** for the old IP; App-Clip domain → `unmutee.in`. Bundle IDs unchanged.

- ✅ **Disk encryption complete** — root is now encrypted volume `vol-0cea5c10571481757` (`Encrypted: true`); old unencrypted volume `vol-07a3800ddaf384e61` deleted. Reboot validated pm2 auto-resurrect. **(S6 fixed)**
- ✅ **Port 22 closed** — SG now only 80/443; access is SSM-only. **(S2 fixed)**

**DEFERRED (documented):**
- 9 moderate npm advisories (breaking ws/socket.io upgrades; need testing).
- App Clip needs an `apple-app-site-association` file on `unmutee.in` to actually invoke.
- Snapshots remaining: `snap-0bb4fc5e40df3e4f6` (encrypted, keep as rollback), `snap-01b60edb0592b1ce1` + `snap-0774941cd59b3da19` (UNENCRYPTED — delete after a confidence period).

**EVERY 🔴/🟠 audit finding is now resolved.**

**Founder action items (recap):**
- iOS: `xcodegen generate` → build/sign/release (review uncommitted changes first).
- Confirm SNS alert email (`nirpeksh@scaleupapp.club`).
- **Rotate IAM key `AKIA4OBHVFBJAWYIBNJM`** after this session.
- Optional: `KeychainManager` service string `com.boop.app` (internal namespace) left as-is.

**Founder action items:**
- Confirm the SNS subscription email sent to `nirpeksh@scaleupapp.club` (so alerts deliver).
- **Rotate the IAM access key `AKIA4OBHVFBJAWYIBNJM` after this session** (it was shared in chat).
- `firebase-service-account.json` sits unencrypted in the app dir — fine for now (locked box), revisit in Phase 3.
