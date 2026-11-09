import SwiftUI

/// The Profile section where the user chooses what the proximity alerts tell them, and fixes what blocks them.
struct ProximityAlertSettingsSection: View {
    @State private var viewModel = ProximityAlertSettingsViewModel(
        service: SystemProximityPermissionService(),
        store: UserDefaultsProximityAlertStore(),
        onChanged: { await ProximityAlertCoordinator.shared.refresh() }
    )
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("proximitySettings.title")
                .font(.headline)

            VStack(spacing: 12) {
                Toggle(isOn: nearbyBinding) {
                    label("proximitySettings.nearby.title", "proximitySettings.nearby.subtitle")
                }
                Toggle(isOn: itineraryBinding) {
                    label("proximitySettings.itinerary.title", "proximitySettings.itinerary.subtitle")
                }
            }

            permissionRow
        }
        .task { await viewModel.load() }
        // The user may have changed the permissions in the Settings app.
        .onChange(of: scenePhase) {
            guard scenePhase == .active else { return }
            Task { await viewModel.load() }
        }
    }

    private var nearbyBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.nearbyPlacesEnabled },
            set: { isOn in Task { await viewModel.setNearbyPlacesEnabled(isOn) } }
        )
    }

    private var itineraryBinding: Binding<Bool> {
        Binding(
            get: { viewModel.settings.itineraryEnabled },
            set: { isOn in Task { await viewModel.setItineraryEnabled(isOn) } }
        )
    }

    private func label(_ title: LocalizedStringKey, _ subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var permissionRow: some View {
        switch viewModel.permissions {
        case .unknown:
            EmptyView()
        case .complete:
            Label("proximitySettings.complete.message", systemImage: "checkmark.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .canTurnOn:
            VStack(alignment: .leading, spacing: 8) {
                Text("proximitySettings.turnOn.message")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("proximitySettings.turnOnButton.title") {
                    Task { await viewModel.turnOn() }
                }
                .buttonStyle(.glassProminent)
                .disabled(viewModel.isWorking)
            }
        case .needsSettings(let missing):
            VStack(alignment: .leading, spacing: 8) {
                Text(missing == .notifications
                     ? "proximityPermission.settings.notifications.message"
                     : "proximityPermission.settings.location.message")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("proximityPermission.settingsButton.title", action: viewModel.openSettings)
                    .buttonStyle(.glass)
            }
        }
    }
}
