# Architectural & Engineering Decisions - Stellar Lift

This document tracks technical decisions made during the design and implementation of Stellar Lift.

---

## 1. Persistence & Data Architecture
- **SwiftData (`@Model`)**: Selected as required. Schema is designed with pure SwiftData relationships (`@Relationship(deleteRule: .cascade)` for sessions -> performed exercises -> sets, and splits -> planned exercises).
- **Inverse Relationships**: Explicit inverse relationships are established across models (`Exercise` <-> `PlannedExercise` / `PerformedExercise`, `WorkoutSession` <-> `PerformedExercise` <-> `SetEntry`) to ensure referential integrity.
- **Offline First**: All queries execute against the local `ModelContainer`. CloudKit sync flag (`Config.iCloudSyncEnabled`) is default `false` for free provisioning profiles.

## 2. Progression Engine
- **Working Sets Only**: Any set with `isWarmup == true` is strictly filtered out prior to metric calculation.
- **e1RM Formula**: Epley formula: `weight * (1.0 + reps / 30.0)` is used and capped at `reps <= 12`. For reps > 12, calculations use 12 to maintain reliability against aerobic bias.
- **Double Progression Model**: Weight is held constant until working sets achieve the top of the exercise's rep range (`targetRepHigh`). Once achieved across all target sets, the progression engine recommends the next discrete equipment jump.
- **Stagnation Threshold**: Evaluated at 21 days (the user's explicit key trigger) or 3+ sessions at identical top weight without rep improvements.

## 3. UI/UX & Aesthetics
- **Dark Mode Only**: All colors use semantic dark tokens with ultra-deep space tones (`#05060F`, `#0B0E1D`, `#131734`).
- **Starfield Background**: Implemented with SwiftUI `Canvas` and `TimelineView` with a frame limiter (approx 30fps) for battery preservation. When `UIAccessibility.isReduceMotionEnabled` is active, stars are rendered statically.
- **Monospaced Digits**: `.monospacedDigit()` applied across all timers, weight displays, and rep steppers to prevent layout shifts during input.

## 4. Notifications & Sideloading
- **Local Notifications Only**: `UNUserNotificationCenter` handles rolling weekday split reminders and background rest timer alerts. Stays well within iOS's 64 pending notification limit.
- **Free Provisioning Compliance**: No push notification entitlements or paid developer capabilities are configured in the project file, ensuring 100% compatibility with AltStore / SideStore / Xcode free provisioning.

## 5. Equipment Profiles & Plate Calculator
- **Barbell Math**: Default bar weight is 20kg. Available plates default to pairs of `1.25, 2.5, 5, 10, 15, 20` kg. Barbell calculations strictly require symmetric pairs `(weight - barWeight) / 2`.
- **Dumbbells & Machines**: Discrete step lookup finds the nearest valid increment above current weight.

## 6. Build Targets & Test Architecture
- **Widget Decoupled from Main Target**: `StellarLiftWidget.swift` is retained as a reference file in the workspace but removed from the main app's Sources build phase to prevent duplicate `@main` compilation errors. When ready for Home Screen widgets, it can be mounted into a dedicated Widget Extension target.
- **Unit Test Target Linkage**: `StellarLiftTests` utilizes `@testable import StellarLift` and relies on `TEST_HOST` / `BUNDLE_LOADER` rather than recompiling app source files, eliminating duplicate symbol ambiguity. `GENERATE_INFOPLIST_FILE = YES` is enabled to automatically package the test bundle.
- **Zero Entitlements Overhead**: Time-sensitive notification interruption levels are set to `.active` and CloudKit is disabled to eliminate the requirement for a paid Apple Developer certificate.

