import SwiftUI

/// The card that explains proximity alerts before iOS asks for anything. Same look as the rating alert: a glass
/// card over a dimmed screen.
struct ProximityPermissionPromptView: View {
    let viewModel: ProximityPermissionViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .contentShape(.rect)

            card
        }
    }

    private var card: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "bell.badge")
                    .font(.title)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Text("proximityPermission.title")
                    .font(.headline)

                Text(message)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.top, 8)

            buttons
        }
        .padding(14)
        .frame(width: 300)
        .glassEffect(.regular, in: .rect(cornerRadius: 34))
    }

    private var message: LocalizedStringKey {
        switch viewModel.step {
        case .intro, .working: "proximityPermission.message"
        case .enabled: "proximityPermission.enabled.message"
        case .needsSettings(.notifications): "proximityPermission.settings.notifications.message"
        case .needsSettings(.location): "proximityPermission.settings.location.message"
        }
    }

    @ViewBuilder
    private var buttons: some View {
        HStack(spacing: 16) {
            switch viewModel.step {
            case .intro, .working:
                Button("proximityPermission.laterButton.title", action: viewModel.dismiss)
                    .buttonStyle(.glass)
                    .tint(.primary)
                    .disabled(viewModel.step == .working)

                Button {
                    Task { await viewModel.enable() }
                } label: {
                    if viewModel.step == .working {
                        ProgressView()
                    } else {
                        Text("proximityPermission.enableButton.title")
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(viewModel.step == .working)

            case .enabled:
                Button("proximityPermission.doneButton.title", action: viewModel.dismiss)
                    .buttonStyle(.glassProminent)

            case .needsSettings:
                Button("proximityPermission.closeButton.title", action: viewModel.dismiss)
                    .buttonStyle(.glass)
                    .tint(.primary)

                Button("proximityPermission.settingsButton.title", action: viewModel.openSettings)
                    .buttonStyle(.glassProminent)
            }
        }
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .frame(maxWidth: .infinity)
    }
}
