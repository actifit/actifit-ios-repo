# Actifit iOS — Android Parity Port

**Goal:** bring the iOS app up to functional parity with the Android app (`c:\mo\coding\actifit\android`).
**Only intentional exclusion:** Health Connect (Android-only). iOS covers tracking via CoreMotion `CMPedometer` (primary) + HealthKit + Fitbit; where Android sourced distance/calories from Health Connect, iOS will source the equivalent from **HealthKit** (distance / active energy).

Both apps share the same Actifit backend (REST + JWT) and the **server-side broadcast model** (private keys sent to `api.actifit.io` endpoints such as `performTrx` / `performTrxPost` / `tipAccount`; iOS does **not** sign Hive transactions locally). Most gaps are therefore **client-side screens to build**, not new backend infrastructure.

_Last updated: 2026-07-23. Source: dual deep-dive of both codebases._

---

## ✅ At parity (already in both)

- Posting-key login + Skip/guest (iOS also adds Face ID + Keychain — ahead of Android)
- Dashboard: live steps, pie + hourly/daily bar charts
- Post & Earn (daily report: markdown, images, 3Speak embed, activity types, body measurements, charity)
- Wallet core balances (AFIT / HIVE / HBD / HP / BLURT)
- Social feed (upvote / comment / voters / share)
- Waves microblog (create / upvote / comment) — Android also folds in LEO Threads (minor)
- Leaderboard; Notifications (in-app + FCM push); Referrals
- Exchanges / Buy AFIT list
- Settings (payout mode, charity, language, daily reminder, keys, per-type notifications)
- 3Speak upload (TUS); Polls / Surveys; Chat (WebView); AdMob rewarded ads (4 tiers)
- Send AFIT; Send HIVE/HBD

---

## ❌ Gap backlog (Android has → iOS missing/partial)

| # | Feature (Android) | iOS status | Effort | Notes / iOS mapping |
|---|---|---|---|---|
| 1 | **AI Workout Wizard** — Gemini/Gemma generation, saved workouts, edit, exercise search, exercise detail, local exercise DB | ❌ Missing | Large | 4 screens + AI service + assets. Pay-per-generate via on-chain AFIT (backend exists) |
| 2 | **GPS Route recording** (`RouteMapActivity` + recording service, osmdroid) | ❌ Missing | Large | Live + replay → **MapKit + CoreLocation** |
| 3 | **Native Profile screen** ("Living Fitness Identity": AuraView companion, activity rings, tiers, streak, lifetime tiles) | ❌ Missing (iOS opens web profile in Safari) | Large | Includes Lottie companion animal |
| 4 | **Wallet: staking / unstaking** (power up/down HIVE, stake/unstake HE tokens) | ❌ Missing | Medium | Backend `perform_trx` exists |
| 5 | **Wallet: claim rewards** (pending HIVE / HBD / BLURT) | ❌ Missing | Medium | `/claim_rewards` endpoint exists |
| 6 | **Wallet: send arbitrary Hive-Engine tokens + Hive tx history** | ⚠️ Partial (iOS sends only AFIT + HIVE/HBD; shows AFIT tx only) | Medium | Android does full HE send + `condenser_api.get_account_history` |
| 7 | **Gadget marketplace purchase** (requirement evaluation, spend AFIT) | ⚠️ Partial (iOS shows gadgets/info; Android has full `MarketActivity` buy flow) | Medium | Confirm whether iOS can actually purchase |
| 8 | **AI feed translation** + **AI dashboard motivational insight** | ❌ Missing | Small–Med | Same Gemini service as #1 |
| 9 | **QR scan** of posting / active key | ❌ Missing | Small | AVFoundation |
| 10 | **Backup / restore settings** (JSON export/import) | ❌ Missing | Small | SAF → iOS document picker |
| 11 | **Dashboard month heatmap + streak strip** | ⚠️ Partial | Small–Med | iOS has charts but no heatmap/streak |
| 12 | **Share Achievement card** (render PNG + share) | ❌ Missing | Small | |
| 13 | **Local milestone notifications** (5k/10k) + streak tracking | ⚠️ Likely missing | Small | |
| 14 | Governance nudge (DHF proposal vote), free-signup-link claiming, dark mode toggle | ❌ Missing (minor) | Small | Low priority |
| 15 | **Dashboard Twitter/X cards** — latest 2 posts in news carousel | ❌ Missing | Small | Android calls backend endpoint **`latestXPost`** (server-proxied, not Twitter API). Response `{ tweets: [{ tweetText, tweetUrl, tweetTimestamp, tweetImageUrl }] }`, takes `min(2, …)`, prepends to news ViewPager. iOS: same endpoint → prepend to dashboard news banner carousel |

---

## 🎨 UI Revamp backlog (match Android redesign)

Beyond feature parity, three core screens need a **visual revamp** to match the Android redesign. Design target: Android repo `docs/screen-redesign-mockups.md` (Material 3, Actifit Red `#FF112D`, card radius 16, button radius 12, pill radius 24, bg `#F5F5F5`). The reusable `AccordionCardView` (from the wallet facelift) and a shared card/token style are the foundation.

| # | Screen | Scope | Status |
|---|---|---|---|
| R1 | **Wallet** | Android-style accordion + inline action icons | ✅ Done (PR #3) |
| R2 | **Dashboard** (`ActivityTrackingVC`) | Full revamp: clean header (greeting + profile, bell badge, wallet), unified "Today's Activity" hero card (single pie + source badge + Sync/Settings/Share row), quick-action pills (Post / Workout), Daily Rewards card (4 tiers + progress bar w/ milestones), Earnings card (AFIT/HIVE/BLURT + pending), Activity Breakdown chart card (Daily/Hourly segmented), Workout highlight, 4-item footer + "More" bottom sheet | ⏳ In progress |
| R3 | **Login** (`LoginViewController`) | Revamp: animated logo + tagline, rounded input card w/ leading icons + QR trailing button, full-width red login button, "Continue as Guest" link, helper links | ☐ Not started |
| R4 | **Post & Earn** (`PostToSeemitView`) | Full revamp: top bar w/ preview toggle, horizontal stepper, card sections (title, date/steps/activities as chips, collapsible measurements, content editor w/ toolbar + live preview), FAB post button | ☐ Not started |

Design tokens to mirror (from the spec): `colorPrimary #FF112D`, `colorBackground #F5F5F5`, `colorSuccess #00C853`, `colorTextSecondary #757575`, card 16 / button 12 / pill 24 corner radii. iOS note: the dashboard's 3 separate pie charts (device/Fitbit/HealthKit) unify into one card with a dynamic source badge; Health Connect → HealthKit.

## 🚫 Intentionally excluded

- **Health Connect** — Android-only; iOS uses CoreMotion + HealthKit + Fitbit. When building Profile rings / heatmap (#3, #11), source distance/active-energy from **HealthKit**.
- Android-locked plumbing with no iOS analog: accelerometer foreground-service + wake-lock tracking, boot receivers, APK-signature/root checks. iOS gets background step history via CMPedometer queries.

---

## 🗺️ Phasing

- **Phase 1 — Wallet completeness** (#4, #5, #6): highest value, backend already there, self-contained. **← IN PROGRESS**
- **Phase 2 — Store/gadget purchase + Profile + streak/heatmap/achievements** (#7, #3, #11, #12, #13): identity/engagement layer.
- **Phase 3 — AI Workout Wizard + AI translation/insight** (#1, #8): biggest new surface, modular.
- **Phase 4 — GPS Routes** (#2): most platform-specific (MapKit/CoreLocation).
- **Phase 5 — Polish** (#9, #10, #14, #15).

---

## Progress log

### Phase 1 — Wallet completeness (started 2026-07-23)

**Backend API foundation — DONE** (`Actifit/API/API.swift`, `Actifit/Structs/Structs.swift`). Added, all mirroring the exact Android contracts and reusing the existing `performTrxPost` (active-key) / `performTrx` wrappers:
- `broadcastActiveOperation(...)` — shared active-key `performTrxPost` helper
- `hiveEngineTokenOperation(...)` — HE `custom_json` `ssc-mainnet-hive` transfer/stake/unstake
- `powerUpHive(...)` (`transfer_to_vesting`), `powerDownHive(...)` (`withdraw_vesting`)
- `getPendingRewards(...)`, `claimRewards(...)` (JWT via `x-acti-token`)
- `getHiveAccountHistory(...)` — `condenser_api.get_account_history`
- `ApiUrls`: `pendingRewards`, `claimRewards`, `hiveRPCNode` (`hiveapi.actifit.io`)

**#5 Claim rewards — DONE (pending Xcode build/device test).**
- `WalletViewModel`: `fetchPendingRewards()`, `claimAllRewards()`, `powerToVests(...)` + `claimResultPublisher` / `pendingRewardsPublisher`.
- `WalletVC`: programmatic "Claim Rewards" button (shown only when rewards pending) → confirm alert → claim → result alert + balance refresh. No storyboard edits (deliberate — repo can't be compiled in this environment).

**#6 HE token send + #4 stake/unstake + HP power up/down — DONE (pending Xcode build/device test).**
- Discovered `ExpandedSectionCell` **already ships** `sendBtn`/`stakeBtn`/`unstakeBtn` + callbacks in its xib — they were simply unwired for Hive-Engine rows. So **no storyboard/xib changes** were needed.
- `WalletVC`: wired HE rows → `presentHETokenAction(row:action:)` (transfer/stake/unstake) and the HIVE core row → `presentPowerUp()` / `presentPowerDown()`. All use programmatic `UIAlertController` input popups (recipient/amount/memo), validation (active key set, positive amount, ≤ balance, no self-send), then broadcast via the new API methods and refresh balances.

**#6 Hive on-chain transaction history — DONE (pending Xcode build/device test).**
- Note: iOS already had the **AFIT reward** transactions list; on-chain Hive history (transfers, power up/down, reward claims) never existed — now added.
- `HiveHistoryViewController` (a programmatic `UITableViewController` appended **inside `WalletVC.swift`** to avoid `.pbxproj` edits) fetches `condenser_api.get_account_history`, parses transfer / transfer_to_vesting / withdraw_vesting / claim_reward_balance, and lists them. Opened via a "Hive History" button on the wallet screen.

**Phase 1 status: COMPLETE (build-verified).** Merged via PR #1 (feature/android-parity-wallet → develop).

### Phase 2 — Gadget marketplace (#7) (started 2026-07-23)

Confirmed iOS had **no** gadget purchase — only owned-gadget display + an AFIT *exchanges* list. The dashboard "market" button did nothing (`openPopup` passed no action). Now built:

- **`Actifit/Controllers/Market/MarketViewController.swift`** (new file, registered in the Xcode target via the `xcodeproj` gem on the build server) — a programmatic marketplace screen: lists active `ingame` gadgets sorted by level, with image, price (AFIT + HIVE), validity, boosts, and a **requirement engine** (User Rank ≥, AFIT balance ≥, prerequisite consumed gadgets) mirroring Android exactly. Buttons gate on eligibility + ownership state (none/bought/active).
- **Four two-step flows** (relay broadcast → parse `trx.tx.{ref_block_num,id}` → confirmation call): buy-with-AFIT (`performTrx` custom_json id `actifit`, `buy-gadget`), buy-with-HIVE (`performTrxPost` transfer to `actifit.market`, memo `buy-gadget:<id>`), activate (with optional friend beneficiary), deactivate — each followed by `buyGadget`/`buyGadgetHive`/`activateGadget`/`deactivateGadget` confirms.
- **`API.swift`** — `getMarketProducts`/`getNonConsumedGadgets`/`getConsumedGadgets`/`getExchangeAfitPrice`, `broadcastGadgetOperation`, `buyGadgetWithHive`, `confirmGadgetTransaction`. **`Structs.swift`** — marketplace endpoints + `actifit.market` + gadget image base.
- **`ActivityTrackingVC.swift`** — dashboard gadget popup's "market" action now opens the marketplace.

✅ **Build-verified** on Xcode 26.5 (BUILD SUCCEEDED, zero errors). Runtime testing pending.

**Remaining Phase 2:** #3 Profile screen, #11 heatmap/streak, #12 achievements, #13 milestones.

> ⚠️ **pbxproj note:** the `MarketViewController.swift` target registration was done on the build server. The local `Actifit.xcodeproj/project.pbxproj` must receive the same one-file addition before committing (see progress notes).

> ✅ **Build verified (2026-07-23):** compiled on the MacinCloud server (Xcode 26.5) — `xcodebuild -workspace Actifit.xcworkspace -scheme Actifit -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build` → **BUILD SUCCEEDED**, zero compile errors in the Phase-1 code. One fix applied during the build: `UITableView.automaticDimension` → `UITableViewAutomaticDimension` (this codebase uses the old spelling via a rename shim). Notes: transferred the working tree via scp (repo is private); a clean `pod install` was required because the committed `Pods/` carried stale IQKeyboardManagerSwift files. Device/runtime testing of the new wallet flows still pending.

## Key references

- iOS wallet: `Actifit/Controllers/WalletVC/*`, send popups under `Actifit/Controllers/TransparentPopup/SendAfitPopup/*` & `SendHiveAndHpPopup/*`
- iOS transaction layer: `Actifit/API/API.swift`, `Actifit/Network/**`, `Actifit/Structs/Structs.swift` (`ApiUrls`)
- Android wallet: `WalletActivity.java`, `SendAFITModalDialogFragment.java`, `SendTokenModalDialogFragment.java`, `StakeTokenModalDialogFragment.java`, `HiveEngineAPI.java`, `HiveRequests.java`
- Android docs to reuse: `documentation/main_activity_deep_dive.md`, `documentation/posting_activity_deep_dive.md`, `documentation/actifit_features_and_user_rank.md`
