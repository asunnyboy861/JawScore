# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | JawScore |
| **Git URL** | git@github.com:asunnyboy861/JawScore.git |
| **Repo URL** | https://github.com/asunnyboy861/JawScore |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/JawScore/ | ✅ Active |
| Support | https://asunnyboy861.github.io/JawScore/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/JawScore/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/JawScore/terms.html | ✅ Active |

## Repository Structure

```
JawScore/
├── JawScore.xcodeproj/            # Xcode Project
├── JawScore/                      # Swift Source Files (26 files)
│   ├── JawScoreApp.swift
│   ├── Views (Scan/Results/Plan/Trends/Paywall/Settings/Share)
│   ├── Services (FaceScanSession, GeometryExtractor, ScoringEngine,
│   │            PlanGenerator, AppleFMsCoach, DeepSeekCoach, PurchaseManager)
│   └── Models (ScoreRecord, HabitCheckIn, GlowPlanRecord)
├── JawScoreTests/                 # ScoringEngine fixture tests (7 tests)
├── Configuration.storekit         # Local IAP testing configuration
├── docs/                          # Policy Pages (GitHub Pages source — PHASE 7)
├── .github/workflows/deploy.yml   # Pages deployment (PHASE 7)
├── capabilities.md
├── nowgit.md
└── (excluded: .env, keytext*.md, COMPETITOR_REPORT.md, improvement_plan_*.md)
```
