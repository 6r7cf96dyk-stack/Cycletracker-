import SwiftUI
import LocalAuthentication

/// Wraps content in an optional Face ID / Touch ID / passcode gate.
///
/// When the app-lock setting is on, the user must authenticate before the
/// content is shown — on launch and whenever the app returns from the
/// background. Authentication uses `.deviceOwnerAuthentication`, which tries
/// biometrics first and falls back to the device passcode.
///
/// All of this is on-device (the LocalAuthentication framework); nothing about
/// the lock leaves the device.
struct LockGate<Content: View>: View {
    @AppStorage(SettingsKeys.appLockEnabled) private var lockEnabled = false
    @Environment(\.scenePhase) private var scenePhase

    @State private var isUnlocked = false
    @State private var isAuthenticating = false

    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            content()
            if lockEnabled && !isUnlocked {
                lockScreen
            }
        }
        .task { await unlockOnAppear() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                if lockEnabled { isUnlocked = false } // re-lock when backgrounded
            case .active:
                if lockEnabled && !isUnlocked {
                    Task { await authenticate() }
                }
            default:
                break
            }
        }
    }

    private var lockScreen: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThickMaterial)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Text("Locked").font(.headline)
                Button {
                    Task { await authenticate() }
                } label: {
                    Label("Unlock", systemImage: "faceid")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAuthenticating)
            }
        }
    }

    private func unlockOnAppear() async {
        if lockEnabled {
            await authenticate()
        } else {
            isUnlocked = true
        }
    }

    private func authenticate() async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        let policy: LAPolicy = .deviceOwnerAuthentication // biometrics OR passcode

        var policyError: NSError?
        guard context.canEvaluatePolicy(policy, error: &policyError) else {
            // No biometrics and no passcode set on the device. Fail OPEN so the
            // user is never permanently locked out of their own local data.
            isUnlocked = true
            return
        }

        do {
            isUnlocked = try await evaluate(context, policy: policy,
                                            reason: "Unlock to view your logs.")
        } catch {
            isUnlocked = false // cancelled or failed — keep it locked
        }
    }

    /// Bridges LocalAuthentication's completion-handler API to async/await.
    private func evaluate(_ context: LAContext, policy: LAPolicy, reason: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: reason) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: success)
                }
            }
        }
    }
}
