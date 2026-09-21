import SwiftUI
import SwiftData

@Observable
public final class AppState {
    public static let shared = AppState()

    // Active workout session restoration
    public var activeSessionId: UUID? {
        didSet {
            if let id = activeSessionId {
                UserDefaults.standard.set(id.uuidString, forKey: "activeWorkoutSessionId")
            } else {
                UserDefaults.standard.removeObject(forKey: "activeWorkoutSessionId")
            }
        }
    }

    // Active rest timer
    public var restTimerTotalSeconds: Int = 90
    public var restTimerRemainingSeconds: Int = 0
    public var isRestTimerActive: Bool = false
    private var restTimerTask: Task<Void, Never>?

    // PR Celebration overlay state
    public var currentPRText: String? = nil
    public var showPRCelebration: Bool = false

    public init() {
        if let savedIdString = UserDefaults.standard.string(forKey: "activeWorkoutSessionId"),
           let uuid = UUID(uuidString: savedIdString) {
            self.activeSessionId = uuid
        }
    }

    public func startRestTimer(seconds: Int) {
        restTimerTask?.cancel()
        restTimerTotalSeconds = max(seconds, 1)
        restTimerRemainingSeconds = max(seconds, 1)
        isRestTimerActive = true

        restTimerTask = Task { @MainActor [weak self] in
            while let self = self, self.isRestTimerActive && self.restTimerRemainingSeconds > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { break }
                self.restTimerRemainingSeconds -= 1
                if self.restTimerRemainingSeconds <= 0 {
                    self.isRestTimerActive = false
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                    break
                }
            }
        }
    }

    public func add30SecondsToRest() {
        restTimerRemainingSeconds += 30
        restTimerTotalSeconds += 30
    }

    public func skipRestTimer() {
        restTimerTask?.cancel()
        isRestTimerActive = false
        restTimerRemainingSeconds = 0
    }

    public func triggerPRCelebration(text: String) {
        currentPRText = text
        showPRCelebration = true
    }

    public func dismissPRCelebration() {
        showPRCelebration = false
        currentPRText = nil
    }
}
