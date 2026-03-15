import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = AppViewModel()
    @Environment(\.scenePhase) var scenePhase
    @State private var hasAttemptedAutoUnlock = false
    
    var body: some View {
        ZStack {
            switch viewModel.state {
            case .onboarding:
                SetupView(viewModel: viewModel)
            case .locked:
                LoginView(viewModel: viewModel)
            case .unlocked:
                MainListView(viewModel: viewModel)
            }
        }
        .onAppear {
            attemptAutoUnlock()
        }
        .onChange(of: viewModel.state) { newValue in
            if newValue == .locked {
                hasAttemptedAutoUnlock = false
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .inactive || newPhase == .background {
                if viewModel.state == .unlocked && viewModel.shouldAutoLock() {
                    viewModel.lock()
                }
                hasAttemptedAutoUnlock = false
            } else if newPhase == .active {
                attemptAutoUnlock()
            }
        }
    }
    
    private func attemptAutoUnlock() {
        guard !hasAttemptedAutoUnlock,
              viewModel.state == .locked,
              viewModel.biometricEnabled else {
            return
        }
        
        hasAttemptedAutoUnlock = true
        viewModel.errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            Task {
                _ = await viewModel.unlockWithBiometricSilent()
            }
        }
    }
}
