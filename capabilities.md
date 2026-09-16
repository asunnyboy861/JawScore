# JawScore — 配置文档

生成时间：2026-09-16

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强功能**，不配置这些项，App 仍可正常使用所有核心功能（扫描、打分、计划、打卡、联系客服均已可用）。配置后可获得完整商业闭环。

### 🔵 IAP StoreKit 配置（必须 — 否则用户无法完成购买）

**影响功能**：不创建 IAP 产品则付费墙无法购买（本地 StoreKit 测试不受影响，模拟器测试已可用）
**当前状态**：✅ StoreKit 2 代码已完成（PurchaseManager.swift），✅ 本地测试配置 Configuration.storekit 已创建，✅ Restore Purchases 已实现

**配置步骤**：
1. 打开 [App Store Connect](https://appstoreconnect.apple.com) → 我的 App → **JawScore**（需先创建 App 记录）
2. 左侧栏 **Features** → **In-App Purchases** → 点击 **"+"**
3. 先创建订阅组 **JawScore Pro**，然后按以下信息创建订阅产品：

| 产品 | Reference Name | Product ID | 价格 | 试用 |
|------|---------------|-----------|------|------|
| 周订阅 | JawScore Pro Weekly | `com.zzoutuo.JawScore.pro.weekly` | $2.99/周 | 无 |
| 月订阅 | JawScore Pro Monthly | `com.zzoutuo.JawScore.pro.monthly` | $4.99/月 | 7天免费试用 |
| 年订阅（主推） | JawScore Pro Annual | `com.zzoutuo.JawScore.pro.annual` | $29.99/年 | 7天免费试用 |

4. 再创建 **Non-Consumable（非消耗型）** 产品：

| 产品 | Reference Name | Product ID | 价格 |
|------|---------------|-----------|------|
| 买断 | JawScore Pro Lifetime | `com.zzoutuo.JawScore.pro.lifetime` | $59.99 一次性 |
| BYO AI 解锁 | JawScore BYO AI Unlock | `com.zzoutuo.JawScore.byo.unlock` | $19.99 一次性 |

5. 每个产品的 Display Name 和 Description 从 `price.md` 复制（已验证字符限制合规）
6. Lifetime 勾选 **Family Sharing**（价格策略要求）
7. ⚠️ 创建后需等待 Apple 处理（通常 1-2 小时）才能在沙盒环境测试
8. 在真机/模拟器 Settings → **Restore Purchases** 验证流程

---

### 🟢 App Store Connect 审核信息配置（必须 — 防止 Guideline 2.1(a) 拒绝）

**影响功能**：不配置则 Apple 审核员可能无法正确测试订阅与 BYO AI 功能
**当前状态**：✅ `app_review_info.md` 已自动生成（项目根目录），内容可直接粘贴

**配置步骤**：
1. App Store Connect → 你的 App → **App Review Information**
2. **Notes** 字段：粘贴 `app_review_info.md` 的 "Review Notes" 部分（含订阅产品表、BYO Key 说明、隐私声明）
3. **Privacy Policy URL**：`https://asunnyboy861.github.io/JawScore/privacy.html`
4. **Terms of Use (EULA) URL**：`https://asunnyboy861.github.io/JawScore/terms.html`
5. **Support URL**：`https://asunnyboy861.github.io/JawScore/support.html`
6. ⚠️ 本 App 审核员无需 Demo 账号：无账号体系；AI 计划生成在 iOS 26+ 用端侧 Apple Intelligence、其余设备用内置计划库，开箱即用；BYO DeepSeek 深度分析默认关闭且需逐次确认

---

### 🟡 Widget 小组件扩展（可选增强 — 不添加不影响 App）

**增强功能**：主屏 streak 打卡格子小组件 + 距下次复扫天数；锁屏 ring 小组件
**不配置的影响**：App 内所有功能正常，仅缺少桌面小组件入口
**当前状态**：✅ App Group 数据层已就绪（FreeScanCounter 已使用 `group.com.zzoutuo.JawScore` 并带标准 UserDefaults 降级，未配置 App Group 时 App 正常运行）

**如需启用，请手动操作**：
1. Xcode → File → New → Target → **Widget Extension**（命名 `JawScoreWidget`，勾选 Standalone/随主 App）
2. Signing & Capabilities 中为主 App 和 Widget 两个 target 都添加 **App Groups**：`group.com.zzoutuo.JawScore`（自动签名会自动注册）
3. 数据源直接读 App Group UserDefaults（streak 计数、上次扫描日期），参考 `Models.swift` 中 `FreeScanCounter` / `StreakCalculator`
4. ⚠️ 添加 target 后需要重新 Build 验证

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| Camera 权限 | NSCameraUsageDescription 已写入（3D 扫描用途，声明数据不出设备） | ✅ 已配置 |
| Photo Library Add 权限 | NSPhotoLibraryAddUsageDescription 已写入（FaceCard 保存） | ✅ 已配置 |
| 本地通知 | UNUserNotificationCenter（周复扫提醒），无需推送证书 | ✅ 已配置 |
| Keychain | BYO DeepSeek Key 存储（kSecClassGenericPassword，KeychainHelper） | ✅ 已配置 |
| StoreKit 2 | PurchaseManager + 5 SKU + Configuration.storekit 本地测试 | ✅ 已配置 |
| Outgoing Network | 联系客服 HTTPS（Workers 默认放行） | ✅ 已配置 |
| App Group 数据层 | group.com.zzoutuo.JawScore（带标准 UserDefaults 降级） | ✅ 已配置 |
| Bundle ID / 签名 | com.zzoutuo.JawScore，Team JP4TN5PTS3 自动签名 | ✅ 已配置 |
| App 图标 | Agnes 生成（霓虹青下颌线），AppIcon.appiconset 已配置，无 alpha | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers：https://feedback-board.iocompile67692.workers.dev/api/feedback | ✅ 已部署 |
| ContactSupportView | 7 主题磁贴 + 5 必填字段 + 成功/错误反馈 + 隐私微文案 | ✅ 已完成 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | 26 个 Swift 文件，MVVM，3 Tab（Scan/Plan/Trends） | ✅ 已完成 |
| 确定性打分引擎 | 48 项测量纯函数 + 8 维分 + 区间输出，7/7 fixture 单元测试通过 | ✅ 已完成 |
| 3D 扫描 | ARKit TrueDepth 主路径 + Vision 照片兜底 + 质量门控 + 实时引导 | ✅ 已完成 |
| Glow-Up 计划 | Apple FMs（iOS 26+）/ 内置计划库（全设备可用）/ DeepSeek BYO（逐次确认） | ✅ 已完成 |
| 习惯打卡 | 90 天格子、昨日补卡、历史编辑、连击计算 | ✅ 已完成 |
| 趋势对比 | 历史记录、DeltaEngine、雷达图对比滑块 | ✅ 已完成 |
| PaywallView | 全部 5 档价格前置 + 法律链接 + 自动续订披露 + 取消指引 | ✅ 已完成 |
| Numbers Off / Take a Break | 心理健康友好模式 | ✅ 已完成 |
| QA 迭代 | 构建零警告 + 全量合规 grep 检查通过 | ✅ 已完成 |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/JawScore | ✅ 已推送 |
| GitHub Pages | 政策页 4 页（Landing/Support/Privacy/Terms）已启用 | ✅ 已部署 |
| App Store 元数据 | keytext.md 已生成，15 项验证全部通过（保密，不入库） | ✅ 已完成 |
| 定价配置 | price.md 已生成验证 | ✅ 已完成 |

### 💡 使用提示（非开发者配置，App 内操作即可）

**AI 功能**：App 默认零配置 — iOS 26+ 设备用端侧 Apple Intelligence（免费、私密），其余设备自动使用内置计划库，下载即用。BYO 深度分析为用户自有 DeepSeek Key（App 内 Settings 输入，存 Keychain），属于用户操作而非开发者配置。

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据。原 "Auto-Configured" 与 "Manual Configuration Required" 内容已重组到上方 Section 一 和 Section 二。

### Analysis

关键词检测（中文指南 + us.md）：相机/camera/扫描 → Camera；照片 → Photo Library Add；通知/提醒 → Local Notifications（本地，无推送）；购买/订阅 → IAP（StoreKit 2）；Keychain → BYO Key 存储；Widget → App Group + WidgetKit（扩展目标未创建）；同步 → CloudKit 判定为可选增强，MVP 采用本地优先。

### No Configuration Needed

- HealthKit、Location、Siri、Apple Watch、iCloud（本地优先设计，非必需）
- Keychain：标准访问无需 entitlement
- 推送通知证书：仅使用本地通知，无需

### Verification

- Bundle ID 修正：com.zzoutuo.JawScore（原 com.zzoutuo.JawScore.JawScore）✅
- 构建验证：build_sim BUILD SUCCEEDED（iPhone 16 / iPad Pro 13-inch M5 运行通过，零警告）✅
- 单元测试：JawScoreTests 7/7 通过（确定性引擎 fixture）✅
- 模拟器已清理 ✅
