import SwiftUI
import UserNotifications

/// Explains notifications and asks for provisional authorization during onboarding.
///
/// Provisional authorization lets Zanzar post alerts right away (quietly, to Notification Center)
/// without showing a system prompt. The user can promote them to full alerts later in Settings.
/// "Always" location is asked later — only when a check-in or itinerary makes it useful.
struct NotificationPermissionView: View {
    @State private var viewModel = NotificationPermissionViewModel()
    @Environment(OnboardingGate.self) private var onboarding
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bellRings = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            VStack(spacing: 16) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                    .symbolEffect(.bounce, options: .nonRepeating, value: bellRings)
                    .accessibilityHidden(true)

                Text("notificationPermission.title")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("notificationPermission.message")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(spacing: 12) {
                Button {
                    Task { await viewModel.enableProvisional() }
                } label: {
                    if viewModel.isWorking {
                        ProgressView()
                    } else {
                        Text("notificationPermission.enableButton.title")
                    }
                }
                .buttonStyle(AuthPrimaryButtonStyle())
                .disabled(viewModel.isWorking)
                .frame(maxWidth: .infinity)

                Button {
                    viewModel.skip()
                    finishOnboarding()
                } label: {
                    Text("notificationPermission.laterButton.title")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                if viewModel.step == .refused {
                    Button("notificationPermission.settingsButton.title") {
                        viewModel.openSettings()
                    }
                    .font(.footnote)
                    .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 0)
        }
        .background(Color.brandBlue50.ignoresSafeArea())
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .task { await viewModel.checkStatus() }
        .task {
            // The bell rings once, a beat after the screen settles.
            guard !reduceMotion else { return }
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            bellRings += 1
        }
        .onChange(of: viewModel.step) { _, newStep in
            if newStep == .enabled {
                finishOnboarding()
            }
        }
    }

    private func finishOnboarding() {
        onboarding.finish()
        coordinator.popToRoot()
    }
}

#Preview {
    NavigationStack {
        NotificationPermissionView()
            .environment(AppCoordinator())
            .environment(OnboardingGate())
    }
}
