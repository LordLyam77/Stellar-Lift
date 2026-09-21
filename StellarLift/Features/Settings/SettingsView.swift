import SwiftUI
import SwiftData
import LocalAuthentication

public struct SettingsView: View {
    @Query private var equipmentProfiles: [EquipmentProfile]
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    @AppStorage("useLbsUnits") private var useLbsUnits: Bool = false
    @AppStorage("defaultRestSeconds") private var defaultRestSeconds: Int = 90
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("prCelebrationEnabled") private var prCelebrationEnabled: Bool = true
    @AppStorage("faceIDLockEnabled") private var faceIDLockEnabled: Bool = false

    public var profile: EquipmentProfile {
        equipmentProfiles.first ?? EquipmentProfile.defaultProfile
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                StarfieldBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Theme Selector Card
                        themeSection

                        // 2. Training Equipment & Units
                        equipmentAndUnitsSection

                        // 3. Rest Timer & Interactions
                        interactionPreferencesSection

                        // 4. Intelligence & Notifications
                        smartFeaturesSection

                        // 5. Data & Privacy
                        dataSection

                        // 6. Sideload & Build Info
                        buildInfoSection
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
        }
    }

    // Theme Picker
    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("COSMIC PALETTE (ALL DARK)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
                .tracking(1.2)

            HStack(spacing: 12) {
                themeButton(theme: .nebula, subtitle: "Violet / Cyan")
                themeButton(theme: .deepSpace, subtitle: "Near-Black / Ice")
                themeButton(theme: .supernova, subtitle: "Obsidian / Amber")
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 20)
    }

    private func themeButton(theme: AppTheme, subtitle: String) -> some View {
        let isSelected = selectedTheme == theme
        return Button {
            selectedTheme = theme
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Circle().fill(theme.primaryAccent).frame(width: 8, height: 8)
                    Circle().fill(theme.secondaryAccent).frame(width: 8, height: 8)
                }
                Text(theme.rawValue)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(isSelected ? selectedTheme.primaryAccent.opacity(0.2) : selectedTheme.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? selectedTheme.primaryAccent : selectedTheme.stroke, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // Equipment & Units
    private var equipmentAndUnitsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("EQUIPMENT & WEIGHT UNITS")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
                .tracking(1.2)

            NavigationLink {
                EquipmentEditorView(profile: profile)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dumbbell Rack & Plates")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)
                        Text("Configure available dumbbells, barbell bar, and increments")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(selectedTheme.textMuted)
                }
            }

            Divider().background(selectedTheme.stroke)

            Toggle(isOn: $useLbsUnits) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Display Units in Pounds (lbs)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)
                    Text("Default is kilograms (kg)")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                }
            }
            .tint(selectedTheme.primaryAccent)
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 20)
    }

    // Interactions
    private var interactionPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WORKOUT EXPERIENCE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
                .tracking(1.2)

            // Default Rest Timer
            HStack {
                Text("Default Rest Timer")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTheme.textPrimary)
                Spacer()
                Picker("", selection: $defaultRestSeconds) {
                    Text("60s").tag(60)
                    Text("90s").tag(90)
                    Text("120s").tag(120)
                    Text("180s").tag(180)
                }
                .pickerStyle(.menu)
                .tint(selectedTheme.secondaryAccent)
            }

            Divider().background(selectedTheme.stroke)

            // Haptics Toggle
            Toggle("Tactile Haptics on Set Complete", isOn: $hapticsEnabled)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textPrimary)
                .tint(selectedTheme.primaryAccent)

            Divider().background(selectedTheme.stroke)

            // PR Starburst Animation
            Toggle("PR Starburst Particle Animation", isOn: $prCelebrationEnabled)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textPrimary)
                .tint(selectedTheme.primaryAccent)
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 20)
    }

    // Smart Features
    private var smartFeaturesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("NOTIFICATIONS & INTELLIGENCE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
                .tracking(1.2)

            NavigationLink {
                NotificationSettingsView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Local Notifications")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)
                        Text("Weekday split reminders and timer alerts")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(selectedTheme.textMuted)
                }
            }

            Divider().background(selectedTheme.stroke)

            NavigationLink {
                AICoachSettingsView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Coach Engine")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)
                        Text("Configure remote API key or local LAN LM Studio")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(selectedTheme.textMuted)
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 20)
    }

    // Data & Privacy
    private var dataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("DATA, BACKUPS & PRIVACY")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
                .tracking(1.2)

            NavigationLink {
                DataExportImportView()
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Backup & Export")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textPrimary)
                        Text("Export to JSON and CSV spreadsheet")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(selectedTheme.textMuted)
                }
            }

            Divider().background(selectedTheme.stroke)

            Toggle(isOn: $faceIDLockEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Face ID App Lock")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(selectedTheme.textPrimary)
                    Text("Require biometric authentication on launch")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(selectedTheme.textSecondary)
                }
            }
            .tint(selectedTheme.primaryAccent)
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
        .padding(.horizontal, 20)
    }

    // Sideload Info
    private var buildInfoSection: some View {
        VStack(spacing: 4) {
            Text("Stellar Lift v\(Config.appVersion) (Build \(Config.appBuild))")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(selectedTheme.textSecondary)
            Text("Free Provisioning Profile • Offline First • Zero Tracking")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(selectedTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
}
