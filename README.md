# 🌌 Stellar Lift

A dark, galactic-themed iOS gym logger built around one uncompromising job: **making sure every session beats the last one**.

Built natively with **Swift 5.9+**, **SwiftUI**, and **SwiftData** for **iOS 17.0+**. Offline-first, single-user, zero analytics, zero ads, and engineered specifically for free Apple Developer accounts and sideloading (.ipa via AltStore / SideStore / TrollStore).

---

## ✨ Features

- **Double Progression Engine (`ProgressionAnalyzer`)**: Pure Swift progression analyzer that tracks working sets, calculates accurate Epley e1RMs (capped at reps ≤ 12), detects 7 distinct progression verdicts (`readyToProgress`, `progressing`, `grinding`, `stalled`, `stagnantLong`, `regressing`, `newExercise`), and automatically flags 21-day plateaus.
- **Active Workout Screen**:
  - Sticky header with real-time session duration and live total tonnage.
  - **Previous Column**: Displays last session's matching set (e.g. `20kg × 10`). Tap once to auto-fill.
  - Increment steppers tailored to your real equipment.
  - Orbit rest timer with rotating glowing planet animation.
  - Personal Record detector with particle starburst animation and distinct haptics.
  - Plate loading visualizer per side for barbells.
  - Ramp warm-up calculator (40% / 60% / 80%).
  - Mid-workout unplanned exercise insertion.
  - Automatic continuous autosave and kill-resilience.
- **Galactic Aesthetic**:
  - 3-layer parallax starfield with canvas twinkle and drift (pauses in background and respects Reduce Motion).
  - 3 custom dark themes: **Nebula** (violet/indigo/cyan), **Deep Space** (near-black/electric cyan), and **Supernova** (obsidian/amber).
  - Glassmorphic `.ultraThinMaterial` cards with 1pt gradient strokes and soft outer glows.
  - SF Pro Rounded typography with monospaced digit alignment.
- **Signature Visual: Strength Constellation**:
  - Spider/radar chart mapping relative strength across muscle groups drawn as connected glowing stars.
- **Splits & Scheduling**:
  - Drag-and-drop split day manager with built-in templates (PPL ×2, Arnold, Upper/Lower ×3, Bro Split + Cardio).
  - 7-day schedule grid (Mon–Sun) driving today's workout cards and notifications.
- **Local Notifications (`UNUserNotificationCenter`)**:
  - Rolling weekday split reminders with personalized workout previews.
  - Time-sensitive background rest timer alerts.
  - Inactivity nudges and Sunday evening training debriefs.
  - Strictly stays within the iOS 64 pending notification limit.
- **AI Coach Layer**:
  - Pluggable `CoachProvider` protocol.
  - Offline deterministic `RuleBasedCoach` requiring no network or keys.
  - Configurable `LLMCoach` supporting remote OpenAI-compatible endpoints (OpenRouter, OpenAI, DashScope) or local LAN LM Studio instances (`http://192.168.x.x:1234/v1`).
  - Automatic silent fallback so the UI never breaks.
- **Data Portability & Security**:
  - Export complete backups to JSON and CSV spreadsheets via the iOS Share Sheet.
  - Biometric Face ID app lock.
  - 120+ seeded exercises covering every muscle group and equipment type.

---

## 🛠️ Building in Xcode

### Prerequisites
- Mac running macOS Sonoma (14.0+) or Sequoia (15.0+).
- **Xcode 15.0+** with the iOS 17.0+ SDK installed.
- An Apple ID (a free personal Apple ID works 100%).

### 1. Open the Project
Double-click `StellarLift.xcodeproj` to launch Xcode.

### 2. Configure Signing (Free Provisioning Profile)
1. In Xcode's Project Navigator (left sidebar), select the root **StellarLift** project.
2. Select the **StellarLift** target.
3. Switch to the **Signing & Capabilities** tab.
4. Check **Automatically manage signing**.
5. Under **Team**, select your Personal Team (e.g. `Your Name (Personal Team)`).
6. Change the **Bundle Identifier** from `com.stellarlift.app` to something unique to your account, for example:
   ```
   com.yourname.StellarLift
   ```
7. Select the **StellarLiftTests** target and ensure its Bundle Identifier matches (e.g., `com.yourname.StellarLiftTests`).

> [!NOTE]
> All paid-developer entitlements (such as CloudKit and Push Notifications) are disabled by default (`Config.iCloudSyncEnabled = false`). Local notifications and SwiftData work without any paid developer certificates.

### 3. Build & Run
1. Connect your iPhone via USB or Wi-Fi.
2. In Xcode's scheme menu at the top, select **StellarLift** and your physical iPhone.
3. Press **Cmd + R** (or click the Play button) to build and install.
4. On your iPhone, navigate to **Settings > General > VPN & Device Management** and trust your Personal Developer certificate before opening the app for the first time.

---

## 📲 Sideloading via AltStore / SideStore (.ipa Export)

If you prefer sideloading an `.ipa` directly:

### Option A: Archive in Xcode
1. In Xcode, select **Product > Destination > Any iOS Device (arm64)**.
2. Select **Product > Archive**.
3. In the Organizer window, click **Distribute App**.
4. Choose **Custom > Development** or **Direct Export / Ad Hoc**.
5. Choose **Automatically manage signing** or export without re-signing.
6. Export the `.ipa` file to your desktop.

### Option B: SideStore / AltStore Installation
1. AirDrop or save the exported `.ipa` to the **Files** app on your iPhone.
2. Open **AltStore** or **SideStore** on your iPhone.
3. Tap the **+** icon in My Apps, select `StellarLift.ipa`, and install.

> [!IMPORTANT]
> **The 7-Day Free Provisioning Caveat:**
> Free Apple Developer accounts sign apps with certificates valid for **7 days**.
> - With **SideStore** or **AltStore**, enable automatic Wi-Fi background refreshing so the app is refreshed seamlessly without plugging into a computer.
> - Because Stellar Lift is **offline-first** and persists everything locally in **SwiftData**, refreshing or re-sideloading over the existing install never deletes your workout logs.

---

## 🧪 Running Unit Tests

Stellar Lift includes unit tests for `ProgressionAnalyzer` (covering all progression verdicts, Epley e1RM capping, double progression, deload detector) and `EquipmentMath` (plate symmetry, discrete dumbbell racks, barbell loadability):

In Xcode, press **Cmd + U** to run tests in the `StellarLiftTests` target.

---

## 📂 Project Architecture

```
StellarLift/
├── App/               // StellarLiftApp, Config (feature flags), AppState coordinator
├── Models/            // SwiftData @Model types: Exercise, SplitDay, WorkoutSession, etc.
├── Core/              // ProgressionAnalyzer, EquipmentMath, PRDetector, NotificationScheduler
├── DesignSystem/      // StarfieldBackground, Theme tokens, GlassCard, OrbitRestTimerView
├── Features/          // Today, Workout, Splits, Exercises, Progress, Coach, Settings
├── CoachEngine/       // CoachProvider protocol, RuleBasedCoach, LLMCoach, TrainingContext
├── Resources/         // 120+ exercise library JSON, Assets.xcassets
├── Widget/            // Home screen widget extension
└── Tests/             // ProgressionAnalyzerTests, EquipmentMathTests
```

---

## 🪐 Philosophy & Design Choices
All architectural decisions, mathematical formulas, and UX choices are detailed in [`DECISIONS.md`](file:///c:/Users/lyamf/Desktop/Stellar%20Lift/DECISIONS.md).
