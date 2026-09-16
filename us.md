# JawScore - iOS Development Guide

> Translated from: `TR-20260915-JawScore颜值扫描-操作指南.MD` (2026-09-15)
> Target Market: United States 🇺🇸 | Platform: iOS (SwiftUI native) | Age Rating: 12+

## Executive Summary

**JawScore** ("3D Face Scan & Glow-Up") is a US-market iOS app that scans the user's face in 3D entirely on-device, scores it with a **deterministic geometry engine** (same photo → same score, every time), and turns the score into an actionable 4-week Glow-Up plan with habit tracking and before/after progress comparison.

**Product Vision**: "Your face, measured honestly. Scanned in 3D on your device, scored the same every time, improved with a plan that actually tracks."

**Target Audience**: US looksmaxxing/glow-up culture (TikTok-native, primarily 16-30, male-skewed but gender-neutral design).

**Key Differentiators (four-axis crushing of the category)**:
1. **Determinism** — pure geometric formulas, no random/network drift; built-in "Verify" double-scan trust ritual
2. **On-device privacy** — no account, no upload, Data Not Collected privacy label; photos are ephemeral by default
3. **Transparent pricing** — all prices shown up front, one-time Lifetime option, cancel instructions on the paywall
4. **Habit loop** — score → plan → daily check-in streak → weekly rescan → delta comparison (retention engine)

**Positioning**: entertainment / self-discovery (NOT medical, NOT a measure of worth). Fixed disclaimer on every result screen: *"JawScore is for self-discovery and entertainment. It does not measure your worth, health, or real-world attractiveness."*

## Competitive Analysis

| App | Model | Pricing | Strengths | Weaknesses (user-verified) | Our Advantage |
|-----|-------|---------|-----------|---------------------------|---------------|
| **Umax - Become Hot** | Photo rating | $3.99/week (~$208/yr) | Viral marketing, big brand | Same photo → different scores; paywall AFTER upload; 40% users stuck at 91% scan; hidden second charges; 3rd-party security score 37.4/100 | Deterministic engine + free tier gives full score BEFORE paywall + never-stuck on-device scan |
| **FaceKit: 3D Face Analysis** (id6756392359, direct target) | TrueDepth 3D | $9.99/month | Real 3D scan, 1000+ data points, AI coach, routines | No transparent lifetime price; TrueDepth-only devices; social battles create privacy exposure; small review base | $59.99 Lifetime buy-once; MediaPipe photo fallback for non-TrueDepth; private by default |
| **LooksMax AI** | Photo rating | Weekly sub | TikTok reach | Same three complaints as Umax (upload→paywall, inconsistent scores, PSL shame framing) | Positive "Potential" framing only; strengths-first results UI |
| **FacePSL** | Photo + PSL scale | Free + IAP | PSL culture niche | PSL tier shaming; collects Head/Body data | No PSL tiers, no shaming vocabulary; Data Not Collected |
| **QOVES** | Human reports | ~$150/year | Expert analysis | Expensive, slow (days), generic | Instant, free-tier, personalized via on-device AI |

**Category economics validated**: Umax peaked ~$500K/month; FaceKit made $100K+ in 2 months. The gap is TRUST + improvement loop + fair pricing — exactly what JawScore attacks.

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Onboarding | 1. Launch (no account/login, 0 sec) → 2. Value prop screen with big "SCAN MY FACE" button → 3. ≤3 screens → 4. Camera permission pre-explanation ("3D scan happens only on your phone") | Taps | None | Permission pre-prompt screen | `UserDefaults.hasCompletedOnboarding` | First scan reachable in ≤30 seconds from cold launch |
| 2 | 3D Face Scan (TrueDepth mode) | 1. Tap SCAN → 2. ARKit face tracking with live mesh + colored light-wave effect + progress ring → 3. Completes in ~3 seconds | Live camera (ARFaceAnchor.geometry, 1220 vertices + sceneDepth) | ARSession tracking, best-frame capture, quality evaluation each frame | Live mesh visualization, quality status | Nothing persisted until quality passes | Works on iPhone X+ (TrueDepth); mesh renders at 30+ fps |
| 3 | Photo Scan (fallback mode) | 1. On non-TrueDepth device or via "Import Photo" → 2. Camera capture or photo library pick → 3. Face landmark detection → 4. Same scoring pipeline | Still image | Face landmark detection (Apple Vision framework; MediaPipe Face Landmarker optional enhancement, 478 pts) + blendshape expression normalization | FaceMeasurement vector | Nothing (frames ephemeral) | Produces valid measurement on any iOS 17+ device with camera |
| 4 | Capture Quality Gate | Continuous during scan: real-time guidance overlay (turn head / move closer / add light with playful icons). If quality < 70 → refuse to score, loop back to guidance | Pose (yaw/pitch/roll), face-in-frame ratio, ambient brightness histogram, distance 0.45–0.65m, light > 250 lux | Threshold scoring → quality 0–100 | Real-time guidance UI; quality score | Quality stored with record only when passed | Quality <70 never produces a score; guidance arrow direction is correct |
| 5 | Geometry Extraction (48 measurements) | Automatic after quality pass — "decoding" animation lights up 48 measurements one by one | 1220-vertex mesh (or 478 landmarks) | `GeometryExtractor` pure functions: gonial angle, chin projection, jawline curvature variance, mirror symmetry, facial thirds, facial fifths, canthal tilt, golden ratios (5 pairs), skin clarity metrics, capture quality | `FaceMeasurement` (48-item vector) | Stored as JSON blob in ScoreRecord | Deterministic: same input → byte-identical output. Unit tests with fixed fixtures pass |
| 6 | Scoring Engine (8 dimensions + total) | Automatic: 8-dim radar chart + big JAWSCORE number pops with heavy haptic | FaceMeasurement + quality score | `ScoringEngine` pure math (NO Date(), NO random, NO network, NO global mutable state): Jaw 35% / Symmetry 35% / Canthal Tilt 30% base weighting; all dims linear-normalized from published anthropometric ranges | 8 dimension scores 0–10 + overall `7.6 ± 0.3` interval (band narrows as quality rises) | Stored in ScoreRecord (immutable) | Fixture tests: fixed vertices → fixed scores. Band = (100-quality)/100*0.9+0.1 |
| 7 | TrustVerify (same-photo double scan) | 1. Results page → tap "Verify" → 2. Re-run scoring on same captured frame → 3. Show both results side-by-side, identical | Same stored frame/measurement | Runs ScoringEngine twice, compares | "Verified: identical results" confirmation card | None extra | Two runs always produce identical output — the trust ritual works |
| 8 | Results Page | 1. Big number + band bar → 2. **Top 2 Strengths shown FIRST** → 3. Potential items (never "deficiency" wording) → 4. 8-dim radar → 5. Fixed footer disclaimer | ScoreRecord | Strength ranking (top dims first) | Radar chart, interval bar, strengths/potential cards, "Your worth ≠ a number" footer | Read from DB | All copy uses Strengths/Potential/Balance framing; PSL/deficiency vocabulary absent |
| 9 | Glow-Up Plan (on-device AI) | 1. Results → "Generate My Plan" → 2. ~2 sec generation → 3. 4-week plan with habits + per-habit "Why" + weekly milestones | Measurement numbers + habit streak (numbers ONLY, never photos) | Apple Foundation Models (`LanguageModelSession`, `@Generable GlowPlan`), iOS 26+; falls back to curated deterministic plan library on iOS 17–25 | 3–5 habits, reasons, 4 weekly milestones | Plan saved to SwiftData | Never shames; potential framing; works offline on iOS 26+; graceful fallback below iOS 26 |
| 10 | Habit Tracker (daily check-in) | 1. Plan tab → today's habits → 2. Tap to check in → 3. GitHub-style 90-day grid → 4. Tap yesterday's cell to backfill → 5. Long-press cell to edit/delete | Tap events | Streak calculation, combo/heat coloring | Streak grid, streak count, streak history | SwiftData HabitCheckIn | Yesterday backfill works; editing history allowed; streak count correct across edits |
| 11 | Weekly Rescan Reminder | Local notification after 7 days since last scan | Last scan date | `UNUserNotificationCenter` scheduling | Local notification | Notification permission + schedule | Notification fires on day 7; tappable to open Scan tab |
| 12 | DeltaEngine (before/after) | 1. Trends tab → 2. Before/after slider (drag to reveal) → 3. Aligned-by-pose comparison → 4. "+0.4 since last scan" interval delta | Two ScoreRecords (baseline + latest) | Pose-normalized comparison, interval arithmetic | Comparison slider, delta badges per dimension | Read from DB | Delta computed from stored measurements only; slider drag renders both images |
| 13 | FaceCard Share Image | 1. Results → "Share FaceCard" → 2. SwiftUI ImageRenderer renders card (big score + radar + streak) → 3. Share sheet → save to Photos or share | Current ScoreRecord + streak | ImageRenderer composition | PNG card. Free version: `JawScore.app` watermark; Pro: no watermark | Saved only to user's photo library on explicit action | Card renders correctly in Dark/Light; watermark logic matches Pro status |
| 14 | Transparent Paywall (StoreKit 2) | Appears ONLY after value (2nd scan / trends / watermark removal). Shows ALL prices, "Cancel anytime in Settings → Apple ID → Subscriptions", Restore Purchases link | Tap purchase | StoreKit 2 `SubscriptionStoreView` + product queries | Purchase flow, upgrade success view | StoreKit entitlement | Free tier NEVER blocks core scan (1/day always works). No per-scan charges inside Pro. All 5 SKUs visible |
| 15 | Free Tier Enforcement | 1 free full scan per day (full score, no mosaic, no fake progress) + Top3 suggestions + 7-day history + basic check-ins | Daily scan count | `UserDefaults`/SwiftData daily counter reset at local midnight | Scan availability state | Counter | After 1 scan today, Scan tab shows friendly context card with transparent Pro offer — never locks the whole app |
| 16 | Numbers Off Mode | Settings → toggle → all scores hidden, only trend arrows (↑/→/↓) shown | Toggle | Score display abstraction | Trend arrows instead of numbers | `UserDefaults.numbersOff` | No numeric score visible anywhere when enabled (results, card, trends) |
| 17 | Take a Break | Settings → "Take a break" → scan + results hidden for 30 days, app shows supportive screen | Tap | 30-day hide timer | Supportive placeholder | `UserDefaults.breakUntilDate` | Re-activates automatically after 30 days or manual end |
| 18 | DeepSeek BYO Deep Mode | 1. Settings → Advanced → enter own DeepSeek API key (stored in Keychain) → 2. Results → "Deep Analysis" → 3. Explicit per-call confirmation dialog (photo leaves device THIS time only) → 4. Response displayed | User key + explicit confirmation + optional photo attachment | DeepSeek API call (OpenAI-compatible), key from Keychain | Deep analysis text | Key in Keychain only | Default OFF; every call requires explicit confirm; key never leaves Keychain; requires BYO Unlock purchase (SKU 5) |
| 19 | Widgets (WidgetKit) | Add widget: medium = streak grid + days-until-rescan; lock screen = ring | Shared app group data | Timeline provider | Streak/rescan widgets | App Group shared defaults | Widget updates on check-in; works after app kill |
| 20 | Settings & Legal | Settings: Numbers Off, Take a Break, BYO AI config, Restore Purchases, Privacy Policy link, Terms link, contact support | Taps | Navigation + external links | In-app pages / Safari links | — | Privacy + Terms links functional (required by Guideline 3.1.2(c)); support contact works |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Detail | Interaction |
|---|--------|-------------|--------|-------------|
| 2.1 | 3D Scan | Live mesh light effect | Blue-green light wave sweeps mesh during scan (RealityKit shader) | Continuous during scan |
| 2.2 | 3D Scan | Progress ring | ~3 second completion, on-device, never stalls | Auto |
| 4.1 | Quality Gate | Playful guidance | e.g. "left side under-lit → smiley face fill-light icon" | Real-time overlay |
| 5.1 | Extraction | Decode animation | 48 measurements light up one-by-one "like unboxing" | Auto on pass |
| 6.1 | Results | Number pop + Haptic | Score rolls up, `.soft` heavy haptic impact | Auto |
| 6.2 | Results | Interval bar | `7.6 ± 0.3` visual bar; band width tied to quality | Auto |
| 9.1 | Plan | Every suggestion has "Why" | One-sentence reason tied to the specific measurement gap | Tap habit row to expand |
| 10.1 | Habits | Combo/heat coloring | GitHub-style intensity levels | Visual |
| 12.1 | Delta | Interval delta badges | "Since last scan +0.4" per dimension | Visual |
| 14.1 | Paywall | Family Sharing | Lifetime & Monthly enable Family Sharing | StoreKit config |
| 14.2 | Paywall | No hidden charges | Zero per-use fees inside any paid tier | Design rule |
| 20.1 | Settings | Contact Support | Preset subject tiles, required fields, backend URL, privacy microcopy, success/error feedback | Push form |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|------------|--------|--------|-------------|---------|
| Scan → History | Scan pipeline | SwiftData | ScoreRecord (timestamp, quality, overall, band, 48-metric JSON) | Quality ≥ 70 |
| Scan → Results | ScoringEngine | Results UI | 8 dims + total + band | Post-scan |
| Results → Plan | Results | PlanGenerator | Measurement numbers + streak | "Generate My Plan" tap |
| Plan → Habits | PlanGenerator | HabitTracker | Habit list | Plan saved |
| Habits → Widget | HabitTracker | WidgetKit | Streak via App Group | Check-in |
| Habits → FaceCard | HabitTracker | FaceCard renderer | Streak count | Share tap |
| History → Delta | ScoreRecords | DeltaEngine | Baseline + latest measurements | Trends tab open |
| LastScan → Reminder | ScoreRecord | Notification scheduler | Last scan date | Post-scan |
| Pro status → Watermark | StoreKit | FaceCard renderer | isPro flag | Share render |
| Pro status → Scan limit | StoreKit | Free tier counter | isPro flag | Scan start |
| BYO key → Deep mode | Settings | DeepSeekClient | Keychain key | Deep Analysis tap |

**VERIFICATION**: 20 primary features — matches all features described in the Chinese guide (scan dual-mode, quality gate, 48-measurement engine, 8-dim scoring, Verify, results, plan, habits, reminder, delta, FaceCard, paywall, free tier, Numbers Off, Take a Break, BYO deep mode, widgets, settings/support, onboarding). ✅

## Apple Design Guidelines Compliance

- **Privacy (5.1.2)**: Data Not Collected label; no account; frames ephemeral; BYO photo sent only after per-call explicit confirmation
- **Subscriptions (3.1.2)**: price disclosure before purchase, Privacy Policy + Terms links on paywall, Restore Purchases, cancel instructions, auto-renew disclosure
- **Medical (1.4.1)**: entertainment/self-discovery positioning, fixed disclaimer, no medical claims, skin section is "lighting & state hint" only
- **HIG**: SF Symbols, Dynamic Type, VoiceOver labels, Reduce Motion degradation, Dark-first with full Light support, iOS 26 Liquid Glass material with graceful iOS 17 fallback
- **Mental wellness**: 12+ rating, positive Potential framing, Numbers Off mode, Take a Break mode, "Your worth ≠ a number" footer

## Technical Architecture

- **Language**: Swift 5.10+, SwiftUI
- **Min iOS**: 17.0 (deployment target); Foundation Models path requires iOS 26+ with fallback plan library
- **Scan layer (dual mode)**:
  - A. TrueDepth (iPhone X+): ARKit `ARFaceTrackingConfiguration` → `ARFaceAnchor.geometry` (1220 vertices) + sceneDepth
  - B. Non-TrueDepth / photo import: Apple Vision face landmarks (base) — MediaPipe Face Landmarker (478 pts, `MediaPipeTasksVision`) as optional enhancement
- **Scoring**: pure deterministic geometry (NO neural network in scoring path)
- **AI layer**: Apple Foundation Models (default, on-device, free) → DeepSeek API (BYO Key, user-paid) behind `CoachProvider` protocol
- **Data**: SwiftData (local, immutable records) + optional CloudKit private DB; Keychain for BYO key; App Group for widgets
- **Monetization**: StoreKit 2 (`SubscriptionStoreView`)
- **Sharing**: SwiftUI `ImageRenderer`
- **Notifications**: `UNUserNotificationCenter`

## Module Structure

```
JawScore/
├── JawScoreApp.swift
├── Views/
│   ├── Onboarding/
│   ├── Scan/ (ScanView, ScanViewModel, ARViewContainer, GuidanceOverlay)
│   ├── Results/ (ResultsView, RadarChartView, BandBarView, VerifyView)
│   ├── Plan/ (PlanView, HabitGrid, CheckInCell)
│   ├── Trends/ (TrendsView, DeltaSliderView)
│   ├── Paywall/ (PaywallView)
│   ├── Settings/ (SettingsView, BYOAIConfigView, ContactSupportView)
│   └── Share/ (FaceCardView)
├── Models/ (FaceMeasurement, ScoreRecord, HabitCheckIn, GlowPlan)
├── Services/
│   ├── FaceScanSession.swift (ARKit)
│   ├── PhotoScanService.swift (Vision fallback)
│   ├── GeometryExtractor.swift (48 measurements, pure)
│   ├── ScoringEngine.swift (pure, fixture-tested)
│   ├── AestheticConstants.swift (all thresholds + literature sources)
│   ├── PlanGenerator.swift (CoachProvider protocol)
│   ├── AppleFMsCoach.swift / DeepSeekCoach.swift
│   ├── KeychainStore.swift
│   ├── StoreService.swift (StoreKit 2)
│   ├── NotificationService.swift
│   └── DeltaEngine.swift
└── Widgets/ (JawScoreWidget)
```

## ⚠️ Data Flow Diagram (Every Feature's Data Lifecycle)

```
Feature: 3D Scan → Score (the single scoring path — NO bypasses allowed)
┌───────────────────────────────────────────────────────────────┐
│ User Input: face in front of TrueDepth camera                 │
│   │                                                           │
│ FaceScanSession (ARKit) → ARFaceAnchor.geometry 1220 verts    │
│   │                                                           │
│ QualityGate → score<70? → guidance UI (nothing stored)        │
│   │ pass (≥70)                                                │
│ GeometryExtractor (pure) → FaceMeasurement (48 values)        │
│   │                                                           │
│ ScoringEngine (pure) → 8 dims + overall + band                │
│   │                                                           │
│ SwiftData ScoreRecord (immutable, append-only)                │
│   │                                                           │
│ Results UI (number pop, radar, band bar, strengths)           │
│   └→ PlanGenerator (numbers only) → GlowPlan → HabitTracker   │
│   └→ FaceCard renderer / DeltaEngine / Reminder scheduler     │
└───────────────────────────────────────────────────────────────┘

Feature: Habit Check-in
User tap → HabitViewModel → validate (today/yesterday only) → SwiftData
HabitCheckIn → streak recompute → grid UI + WidgetKit reload (App Group)

Feature: BYO Deep Analysis
Settings key → Keychain → Deep Analysis tap → explicit confirm dialog →
DeepSeekCoach (HTTPS, user's key) → response text → results card
(Photos leave device ONLY after per-call confirmation; default OFF)

Feature: Purchase
Paywall tap → StoreService (StoreKit 2) → Transaction.currentEntitlements →
isPro flag → unlocks: unlimited scans / trends / no watermark / FaceCard HD

Feature: Free Tier
Scan start → StoreService.isPro? → no → DailyScanCounter (App Group defaults,
resets local midnight) → count < 1 → allow : → context-card upsell
(core app NEVER locks)
```

## Implementation Flow

1. Configure Xcode project (iOS 17+, SwiftUI, Dark-first color assets)
2. Models: `FaceMeasurement`, `ScoreRecord` (immutable), `HabitCheckIn`, `GlowPlan`
3. `AestheticConstants.swift` — all thresholds with literature annotations
4. `GeometryExtractor` + `ScoringEngine` as pure functions + fixture unit tests
5. ARKit `FaceScanSession` + Quality Gate + guidance overlay
6. Vision-based `PhotoScanService` fallback
7. Results UI (radar, band bar, strengths-first, disclaimer footer)
8. SwiftData history + Trends + DeltaEngine
9. PlanGenerator (`CoachProvider` protocol; Apple FMs on iOS 26+, deterministic fallback library below)
10. HabitTracker + streak grid + notifications
11. StoreKit 2 paywall + free tier counter + FaceCard + watermark
12. TrustVerify flow + Numbers Off + Take a Break
13. DeepSeek BYO (Keychain, per-call confirm)
14. Widgets + accessibility pass + contact support

## UI/UX Design Specifications

- **Tone**: iOS 26 Liquid Glass material, Dark-first (`#0A0C10` base), full Light support
- **Colors**: Electric teal `#00E5C7` (primary), neon orange `#FF7A45` (streak/heat), base `#0A0C10`
- **Typography**: SF Pro; hero score `.system(size: 96, weight: .heavy, design: .rounded)`
- **Layout**: Single-column large cards; exactly 3 tabs: **Scan / Plan / Trends**; no nested tab bars
- **Animations**: mesh light-wave during scan; score roll-up + heavy haptic on reveal; 1.2s restrained confetti on goal
- **Components**: 8-dim radar chart, ±band interval bar, GitHub-style 90-day streak grid, before/after drag slider
- **Interaction red lines**: first score ≤ 30s; zero full-screen modal interruptions (permission pre-prompts and paywall are context cards); free tier always functional; no mocking/others-comparison features

## ⚠️ App Store Compliance — AI Features

### Apple Intelligence (Default Free AI Backend)
- iOS 26+: Apple Foundation Models on-device (free, private) powers Glow-Up plans out-of-the-box
- iOS < 26: falls back to a curated deterministic plan library (still fully functional, no AI buttons leading to errors)
- Simulator: FMs unavailable → fallback library used; BYO key path testable
- `canGenerate` logic: always true somewhere — no free-generation counters, no dead code (`freeGenerationsUsed` etc. forbidden)
- Create `app_review_info.md` for reviewers

### BYO API Key (DeepSeek)
- Key in Keychain; default OFF; every call requires explicit confirmation (photo leaves device only then)
- Guideline 2.1(a): app fully functional without any key (fallback library)

## ⚠️ App Store Compliance — Subscriptions

Paywall MUST contain: Privacy Policy link, Terms of Use (EULA) link, per-product title/length/price, auto-renewal disclosure, Restore Purchases, cancel path text.
Subscription value framed as "Unlock Pro features" — never "unlimited AI generations". No per-scan charges inside any paid tier.

## Pricing (US, transparent)

| Tier | Price | Content |
|------|-------|---------|
| Free | $0 | 1 full scan/day + all 8 scores + Top3 suggestions + 7-day history + basic check-ins |
| Pro Weekly | $2.99/wk | All Pro |
| Pro Monthly | $4.99/mo (7-day trial) | All Pro |
| Pro Annual (hero) | $29.99/yr (7-day trial) | ≈ $2.50/wk |
| Lifetime (differentiator) | $59.99 one-time | Forever Pro (launch with 30% off = $41.99 optional) |
| BYO AI Unlock | $19.99 one-time | DeepSeek BYO access forever |

Product IDs: `com.zzoutuo.JawScore.pro.weekly`, `com.zzoutuo.JawScore.pro.monthly`, `com.zzoutuo.JawScore.pro.annual`, `com.zzoutuo.JawScore.pro.lifetime`, `com.zzoutuo.JawScore.byo.unlock`.

## Code Generation Rules

- Scoring path: NO `Date()`, NO `random`, NO network, NO global mutable state — pure functions only, each formula fixture-tested
- All thresholds centralized in `AestheticConstants.swift` with source annotations
- Forbidden copy: PSL tier, mog, low-tier, harsh rating, "deficient/bad" labels — use Strengths/Potential/Balance/Progress
- Fixed disclaimer on every result surface
- Read app version dynamically via `Bundle.main.infoDictionary` — never hardcode
- No dead code (no free-generation counters); native frameworks first; no external AI SDK required for MVP
- Version number managed in Xcode (MARKETING_VERSION / CURRENT_PROJECT_VERSION)

## Build & Deployment Checklist

1. Xcode build succeeds on iPhone + iPad simulators
2. Fixture unit tests for ScoringEngine pass (determinism proof)
3. Free tier: scan works with zero purchases; paywall only after value
4. Privacy labels: Data Not Collected; BYO confirm dialog present
5. Paywall: legal links + restore + cancel text present
6. Widgets build with App Group
7. Contact support wired to backend
8. Accessibility: VoiceOver labels, Dynamic Type, Reduce Motion
