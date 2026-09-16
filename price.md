# Pricing Configuration

## Monetization Model: Subscription (IAP) with Lifetime Buyout

Freemium model: free tier delivers full value for the first scan each day; auto-renewable subscriptions (weekly/monthly/annual) plus two non-consumable one-time purchases (Lifetime buyout, BYO AI Unlock). All prices are displayed transparently before purchase — no hidden per-use charges inside any paid tier. Marginal cost ≈ 0 (fully on-device), which makes the Lifetime buyout sustainable.

## Subscription Group
- **Group Name**: JawScore Pro
- **Reference Name**: JawScore Pro
- **Products in group**: Pro Weekly, Pro Monthly, Pro Annual (auto-renewable only)

## Subscription Tiers (Auto-Renewable)

### 1. Weekly Subscription
- **Reference Name**: JawScore Pro Weekly
- **Product ID**: `com.zzoutuo.JawScore.pro.weekly`
- **Type**: Auto-renewable subscription
- **Price**: $2.99 USD per week
- **Display Name**: `JawScore Pro Weekly` (19 chars, ≤35 ✅)
- **Description**: `All Pro features. Cancel anytime.` (33 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: JawScore Pro
- **Restore Purchases**: ✅ Required

### 2. Monthly Subscription
- **Reference Name**: JawScore Pro Monthly
- **Product ID**: `com.zzoutuo.JawScore.pro.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $4.99 USD per month
- **Display Name**: `JawScore Pro Monthly` (20 chars, ≤35 ✅)
- **Description**: `All Pro features with 7-day free trial.` (39 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: JawScore Pro
- **Restore Purchases**: ✅ Required

### 3. Annual Subscription (hero tier)
- **Reference Name**: JawScore Pro Annual
- **Product ID**: `com.zzoutuo.JawScore.pro.annual`
- **Type**: Auto-renewable subscription
- **Price**: $29.99 USD per year (≈ $2.50/week — 50% savings vs weekly)
- **Display Name**: `JawScore Pro Annual` (19 chars, ≤35 ✅)
- **Description**: `Best value — all Pro for a full year.` (37 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: JawScore Pro
- **Restore Purchases**: ✅ Required

## One-Time Purchases (Non-Consumable)

### 1. Lifetime Buyout (differentiation flagship)
- **Reference Name**: JawScore Pro Lifetime
- **Product ID**: `com.zzoutuo.JawScore.pro.lifetime`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $59.99 USD (one-time)
- **Display Name**: `JawScore Pro Lifetime` (21 chars, ≤35 ✅)
- **Description**: `All Pro features, forever. One purchase.` (40 chars, ≤55 ✅)
- **Localization**: English (US)
- **Family Sharing**: ✅ Enabled
- **Restore Purchases**: ✅ Required
- **Note**: Sustainable because all scoring/AI is on-device with zero marginal cost. Unlocks the SAME Pro feature set as subscriptions — value framing is "buy once, never renew".

### 2. BYO AI Unlock (independent add-on)
- **Reference Name**: JawScore BYO AI Unlock
- **Product ID**: `com.zzoutuo.JawScore.byo.unlock`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $19.99 USD (one-time)
- **Display Name**: `JawScore BYO AI Unlock` (22 chars, ≤35 ✅)
- **Description**: `Use your own DeepSeek API key for deep analysis.` (48 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **⚠️ DIFFERENTIATION NOTE**: BYO AI Unlock does NOT include Pro features (unlimited scans, trends, no watermark) — it only enables the DeepSeek BYO deep-analysis settings module. Pro/Lifetime does NOT include BYO deep analysis — the two unlock different feature sets. BYO AI calls use the user's own API key (user pays their own API costs); generation is unlimited; no free-generation counting (`freeGenerationsUsed` / `maxFreeGenerations` forbidden dead code).

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - 1 full 3D scan per day — complete score, never blurred, never stuck at a fake progress bar
  - All 8 dimension scores + JawScore total with confidence band
  - Top 3 improvement suggestions
  - 7-day scan history
  - Basic habit check-ins
  - FaceCard sharing (with `JawScore.app` watermark)
- **Conversion hooks**:
  - After the day's free scan: friendly context card — "Unlimited scans, trends, and no watermark with Pro"
  - Trends page and watermark-free FaceCard export reveal Pro value after the free tier's history window
  - Transparent pricing card: every tier and price shown up front, with "Cancel anytime in Settings → Apple ID → Subscriptions"

## Pro Features Unlocked (All Paid Tiers)

⚠️ Cross-referenced with capabilities.md — only features confirmed for PHASE 4 implementation are listed.

| Feature | Free | Pro (All Paid Tiers) |
|---------|:----:|:--------------------:|
| Full 3D scans | 1 per day | Unlimited |
| 8-dimension scores + JawScore band | ✅ | ✅ |
| Scan history | 7 days | Unlimited |
| Trends & DeltaEngine before/after comparison | ❌ | ✅ |
| Weekly rescan reminders | ❌ | ✅ |
| FaceCard export | With watermark | No watermark |
| Habit check-ins | Basic (today + yesterday backfill) | ✅ Full history editing |
| DeepSeek BYO deep analysis | ❌ | ❌ Not included — separate $19.99 BYO AI Unlock add-on |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid subscription)
- **Available for**: Pro Monthly ($4.99/mo) and Pro Annual ($29.99/yr)

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView (all tiers visible before purchase)
- [x] Free trial terms included (7-day trial on Monthly & Annual)
- [x] Restore purchases functionality implemented (StoreKit 2 `Transaction.currentEntitlements`)
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options (paywall shows this app's prices only, no competitor price comparison)
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] IAP type purity: subscriptions and non-consumables separated (Lifetime & BYO Unlock are non-consumables, not in subscription group)
- [x] No per-use charges inside any paid tier (unlimited scans included)
- [x] BYO Key model: gated only by one-time unlock + user's own key — no generation counting
