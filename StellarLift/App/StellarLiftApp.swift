import SwiftUI
import SwiftData
import LocalAuthentication

@main
struct StellarLiftApp: App {
    let container: ModelContainer
    @State private var appState = AppState.shared
    @AppStorage("selectedTheme") private var selectedTheme: AppTheme = .nebula
    @AppStorage("faceIDLockEnabled") private var faceIDLockEnabled: Bool = false
    @State private var isUnlocked: Bool = true

    init() {
        self.container = Config.createModelContainer()

        // Configure system tab bar and navigation bar dark appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#05060F").opacity(0.92))
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if faceIDLockEnabled && !isUnlocked {
                    lockScreen
                } else {
                    mainTabView
                }
            }
            .preferredColorScheme(.dark)
            .modelContainer(container)
            .environment(appState)
            .onAppear {
                let context = container.mainContext
                SeedData.seedDatabaseIfNeeded(context: context)
                if faceIDLockEnabled {
                    authenticateUser()
                }
            }
        }
    }

    private var mainTabView: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "sparkle")
                }

            SplitsView()
                .tabItem {
                    Label("Splits", systemImage: "calendar")
                }

            ExerciseListView()
                .tabItem {
                    Label("Exercises", systemImage: "dumbbell.fill")
                }

            ProgressDashboardView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }

            CoachDashboardView()
                .tabItem {
                    Label("Coach", systemImage: "sparkles")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(selectedTheme.secondaryAccent)
    }

    private var lockScreen: some View {
        ZStack {
            StarfieldBackground()

            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 52))
                    .foregroundColor(selectedTheme.secondaryAccent)
                    .shadow(color: selectedTheme.secondaryAccent.opacity(0.6), radius: 12)

                Text("Stellar Lift")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)

                Text("Biometric Security Enabled")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(selectedTheme.textSecondary)

                StellarPrimaryButton("Unlock with Face ID", icon: "faceid") {
                    authenticateUser()
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)
            }
        }
    }

    private func authenticateUser() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock Stellar Lift") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        isUnlocked = true
                    }
                }
            }
        } else {
            isUnlocked = true
        }
    }
}
