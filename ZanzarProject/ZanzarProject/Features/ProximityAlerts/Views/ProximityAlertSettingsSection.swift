import SwiftUI
import TipKit

struct ProximityAlertSettingsSection: View {
    @State private var viewModel = ProximityAlertSettingsViewModel(
        service: SystemProximityPermissionService(),
        store: UserDefaultsProximityAlertStore(),
        onChanged: { await ProximityAlertCoordinator.shared.refresh() }
    )
    @Environment(\.scenePhase) private var scenePhase
    
    private let enableTip = ProximityAlertsEnableTip()
    private let customizeTip = ProximityAlertsCustomizeTip()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("proximitySettings.title")
                    .typography(.headline6)
                    .foregroundStyle(Color.black)
                    .accessibilityAddTraits(.isHeader)
                Text("proximitySettings.subtitle")
                    .typography(.caption2)
                    .foregroundStyle(Color.brandSlate500)
            }

            ListCard {
                Toggle(isOn: nearbyBinding) {
                    label("proximitySettings.nearby.title", "proximitySettings.nearby.subtitle")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Toggle(isOn: itineraryBinding) {
                    label("proximitySettings.itinerary.title", "proximitySettings.itinerary.subtitle")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                permissionRow
            }
            .tint(Color.brandPurple600)
            .tipAbove(customizeTip)
            .tipAbove(enableTip)
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
                .typography(.subtitle2)
                .foregroundStyle(Color.brandNeutral950)
            Text(subtitle)
                .typography(.caption1)
                .foregroundStyle(Color.brandNeutral600)
        }
    }

    @ViewBuilder
    private var permissionRow: some View {
        switch viewModel.permissions {
        case .unknown, .complete:
            EmptyView()
        case .canTurnOn:
            settingsRow(message: "proximitySettings.turnOn.message")
        case .needsSettings(let missing):
            settingsRow(
                message: missing == .notifications
                    ? "proximityPermission.settings.notifications.message"
                    : "proximityPermission.settings.location.message"
            )
        }
    }

    private func settingsRow(message: LocalizedStringKey) -> some View {
        Button(action: viewModel.openSettings) {
            ProfileSettingsRow(title: Text("proximityPermission.settingsButton.title"), subtitle: Text(message)) {
                Image(systemName: "chevron.right")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.brandNeutral950)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
    }
}
