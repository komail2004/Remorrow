# Remorrow 1.0 (Build 2) — Production Certification

**Status: IN PROGRESS — NO-GO for public App Store submission.** This report carries forward the findings in the externally supplied Claude audit and records follow-up engineering changes. Do not conflate source fixes with signing, device validation, or Apple's review.

Evidence labels: **[EXECUTED]** run and verified · **[STATIC]** code/config inspected · **[SIMULATED]** logic reproduced outside iOS · **[NOT TESTED]**.

## 1. Exact source baseline and release branch

- The audited baseline was `main` commit `005e8e501571de513d27626d2b9ecb8d2c27ea06`.
- Claude's patch was delivered as `da3f7e2`; its fixes have been reviewed and integrated into this independent branch: `release/claude-audit-fixes-2026-11-23`.
- Confirm the actual final commit and latest GitHub Actions run before promoting this branch to `main`.

## 2–4. Environment and test scope

- Claude's audit ran in an Ubuntu Linux environment without Xcode, Swift, simulator, physical iPhone or distribution credentials.
- This follow-up uses GitHub source inspection/edits and GitHub Actions for iOS tests; it does not have the owner's local Apple signing identity, physical iPhone, or App Store Connect access.
- Device models, device iOS versions, signing team, and signed archive remain **[NOT TESTED]** until captured in an actual Mac/Xcode release session.

## 5. Test results

- Previous merged baseline CI: **125 unit tests and 9 UI tests passed** on `8ebd78c` in GitHub run `45082895527` **[EXECUTED CI]**.
- New regression tests cover: spring and autumn DST, all explicit times, `7.30pm`, reschedule destinations, time ranges, duplicate time mentions, missing dates with two times, and bounded shared image import.
- **New branch CI results:** PENDING; record exact run URL and totals before merge. A clean compile by itself is not a passing test suite.

## 6. Critical user journeys and defects

### D1 — P1 — Reschedules previously selected the OLD time
**Fix in validation branch [STATIC, testing pending]:**
- Use `ExplicitTimeParser.all(in:)` to recognize multiple distinct clock times.
- Prefer the last explicit time for an apparent reschedule; keep the first for ordinary time ranges.
- Mark multi-time proposals `confirmTime` and require an explicit user verification toggle before saving **or updating** a plan in Review.
- Apply to relative dates, absolute dates and no-date proposals.

### D2 — P1 — DST shifted requested local time
**Fix [STATIC, testing pending]:** `suggestedPickerDate` uses `Calendar.date(bySettingHour:minute:second:of:)` rather than elapsed hours from midnight. Added DST regression cases.

### D3 — POTENTIAL P0 — Historical Build 1 Bundle ID differs from repository source
**Mitigation [STATIC]:** The signed release script now refuses export unless `APPSTORE_CONNECT_BUNDLE_ID` explicitly equals the actual existing app identifier `com.komail2004.remorrow`; all three extension IDs and build versions and the shared App Group are checked. This does not verify what was actually installed by Build 1. **Owner must still check App Store Connect › App Information and perform an in-place upgrade.**

### Other journeys
Calendar permission-denial and actual writes, receipt camera/OCR on 20 real examples, widgets, share/action extensions, shortcuts and notification delivery: **[NOT TESTED on a physical device]**.

## 7. Apple Intelligence
**[STATIC]:** The model is gated by framework/OS availability; deterministic fallback remains. The model may classify a verbatim excerpt, but the proposed title now comes from `SmartTitleGenerator.title(from: quote)`, preventing unsupported model-invented names. Model availability, speed and behavior on an eligible iPhone: **[NOT TESTED]**.

## 8. Receipt extraction
Receipt OCR and purchase editing are present from the previous merged branch; this follow-up does not establish 20-case real-world accuracy. **[NOT TESTED on device]**.

## 9. Subscription accuracy
Existing anchored renewal projections, editable cadence/amount/currency, and currency-separated totals remain. A limited rolling set of future local notifications is scheduled and refreshed on app foreground; iOS has limits and reminders are not guaranteed if permissions are denied or the app is never reopened. **[STATIC]**, real-device testing pending.

## 10. Calendar correctness
Review now requires explicit verification for ambiguous times. Existing calendar creation and update authorization rules have not been proven against an isolated real-device test calendar. **[STATIC]**, real-world test pending.

## 11. Migration
Three optional legacy SwiftData properties have safe defaults, but **a real Build 1 → Build 2 upgrade without uninstalling remains mandatory**. Do not erase an existing test installation to make migration succeed.

## 12. Crash and performance
**[NOT TESTED on device].** Review crash logs, memory pressure, cold starts, repeated camera/OCR usage, image size and foreground/background lifecycle.

## 13. Accessibility
Review now exposes an accessibility identifier for explicit time verification. Full VoiceOver, Dynamic Type, contrast and screen-size audits: **[NOT TESTED on device]**.

## 14. Privacy and security
**[STATIC]**:
- SharedInbox now uses capped, incremental FileHandle reads instead of file metadata access, reducing the privacy-manifest timestamp concern and bounding huge images to 30 MiB.
- Foundation Model output is treated as untrusted; user confirmation remains required.
- `ITSAppUsesNonExemptEncryption` is set to false based on currently inspected app code using native Apple functionality. The account holder must confirm the actual release binary's export-compliance answers before uploading.
- Public support and privacy URLs, valid contact information, final disclosure verification: **OUTSTANDING**.

## 15. Signed archive
**[NOT EXECUTED]**. `scripts/archive-signed-release.sh` now checks the expected App Store Connect Bundle ID, app version, all three extension IDs, matching build numbers, App Group source entitlements, and code signatures; a real Mac, Apple Developer team, signing certificates and provisioning profiles are still required.

## 16. App Store compliance
- Paid upfront pricing of **$4.99** must be set by the owner in App Store Connect, not in Swift code.
- Privacy policy and support URLs must be publicly accessible and accurate. Current policy source is a draft.
- Screenshots, age rating, export declarations, contact information, content rights, signed upload, App Review notes and device testing are still owner-side gates.
- Do not claim fully offline or 100% accurate AI interpretation.

## 17. Defect and blocker matrix

| Finding | Severity | Status |
|---|---|---|
| D1 reschedule/multiple times | P1 | Fixed in code; new CI pending |
| D2 DST picker offset | P1 | Fixed in code; new CI pending |
| D3 Build 1 actual Bundle ID continuity | Potential P0 | Guard added; owner verification needed |
| Time `7.30pm` | P3 | Parser and regression test added |
| Unverified model-generated event title | P3 | Replaced with source-grounded title |
| SharedInbox file-timestamp API / huge-image handling | P2 | Changed to bounded reads; tests pending |
| Rolling subscription alerts | P2 | System-limited; foreground refresh available; device tests needed |
| Export compliance declaration | P3 | Boolean declared; owner must verify eligibility |
| Public privacy/support URLs | Release blocker | Owner must provide/publish |
| Signed App Store IPA | Release blocker | Not produced |
| Physical-device upgrade and functional testing | Release blocker | Not performed |

## 18. Evidence

- Claude-supplied `PRODUCTION-CERTIFICATION.md` and `0001-fix-time-prefer-rescheduled-time-confirm-multi-time-.patch` were reviewed as input.
- Prior green CI: https://github.com/komail2004/Remorrow/actions/runs/45082895527.
- Latest validation branch PR / CI: add resulting links after opening the PR.
- Signed archive: none. Do not claim production certification from unsigned CI results.

## 19. Release GO / NO-GO

**NO-GO** for public App Store submission until all the following are independently verified: latest commit's full iOS CI, real Build 1/2 Bundle ID continuity, an actual in-place device migration, a signed archive plus App Store Connect validation, real-device functional QA, and active privacy/support URLs. Merging a passing code branch is an engineering milestone, not permission to submit an unverified binary.
