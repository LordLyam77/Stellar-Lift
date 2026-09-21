import SwiftUI

public struct AICoachSettingsView: View {
    @AppStorage("aiCoachMode") private var aiCoachMode: String = "off"
    @AppStorage("aiCoachBaseURL") private var aiCoachBaseURL: String = "https://api.openai.com/v1"
    @AppStorage("aiCoachAPIKey") private var aiCoachAPIKey: String = ""
    @AppStorage("aiCoachModelName") private var aiCoachModelName: String = "gpt-4o-mini"
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula

    @State private var connectionStatus: String? = nil
    @State private var isTesting: Bool = false

    public var body: some View {
        ZStack {
            StarfieldBackground()

            ScrollView {
                VStack(spacing: 20) {
                    // Coach Mode Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI COACH ENGINE")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                            .tracking(1.2)

                        Picker("Coach Mode", selection: $aiCoachMode) {
                            Text("Off (Deterministic Rules Only)").tag("off")
                            Text("Remote API (OpenAI / OpenRouter / LM Studio)").tag("remote")
                            Text("On-Device MLX (Qwen 1.5B)").tag("onDevice")
                        }
                        .pickerStyle(.inline)
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)
                    .padding(.horizontal, 20)

                    if aiCoachMode == "remote" {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("REMOTE API CONFIGURATION")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                                .tracking(1.2)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Base URL (e.g. LAN LM Studio or OpenRouter)")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)
                                TextField("https://api.openai.com/v1", text: $aiCoachBaseURL)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)
                                    .padding(10)
                                    .background(selectedTheme.surfaceCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Model Name")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)
                                TextField("gpt-4o-mini", text: $aiCoachModelName)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)
                                    .padding(10)
                                    .background(selectedTheme.surfaceCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("API Key")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)
                                SecureField("sk-...", text: $aiCoachAPIKey)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textPrimary)
                                    .padding(10)
                                    .background(selectedTheme.surfaceCard)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }

                            Button {
                                testConnection()
                            } label: {
                                HStack {
                                    if isTesting {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                    }
                                    Text("Test Connection")
                                }
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTheme.secondaryAccent.opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isTesting)

                            if let status = connectionStatus {
                                Text(status)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(status.contains("Success") ? selectedTheme.successPR : selectedTheme.danger)
                            }
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 20)
                        .padding(.horizontal, 20)
                    }

                    if aiCoachMode == "onDevice" {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "cpu")
                                    .foregroundColor(selectedTheme.secondaryAccent)
                                Text("ON-DEVICE MLX SWIFT")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(selectedTheme.textSecondary)
                                    .tracking(1.2)
                            }

                            Text("Qwen2.5-1.5B-Instruct 4-bit runs locally in memory via MLX. Downloaded on-demand into Application Support without bloating the IPA sideload.")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(selectedTheme.textPrimary)

                            Text("Model Cache: ~980 MB")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(selectedTheme.secondaryAccent)
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 20)
                        .padding(.horizontal, 20)
                    }

                    // Security & Privacy Guarantee
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(selectedTheme.successPR)
                            Text("OFFLINE-FIRST GUARANTEE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTheme.textSecondary)
                                .tracking(1.0)
                        }
                        Text("Stellar Lift transmits only a minimal 400-token summary of recent metrics when remote queries are executed. If offline or erroring, the app silently uses the offline Rule-Based Coach.")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(selectedTheme.textSecondary)
                    }
                    .padding(16)
                    .glassCard(cornerRadius: 18)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("AI Coach Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func testConnection() {
        isTesting = true
        connectionStatus = nil

        let coach = LLMCoach()
        Task {
            do {
                let answer = try await coach.answer(question: "Test connection: respond with 'Stellar connection verified.'", context: TrainingContext.empty)
                await MainActor.run {
                    connectionStatus = "Success! " + answer.prefix(60)
                    isTesting = false
                }
            } catch {
                await MainActor.run {
                    connectionStatus = "Connection error: \(error.localizedDescription)"
                    isTesting = false
                }
            }
        }
    }
}
