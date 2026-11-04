import SwiftUI

struct PlaceSuggestionSheetView: View {
    @State private var viewModel: PlaceSuggestionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let onFinished: (PlaceSuggestionOutcome) -> Void

    init(
        service: PlaceSuggestionServicing = PlaceSuggestionService(),
        onFinished: @escaping (PlaceSuggestionOutcome) -> Void
    ) {
        _viewModel = State(initialValue: PlaceSuggestionViewModel(service: service))
        self.onFinished = onFinished
    }

    init(viewModel: PlaceSuggestionViewModel, onFinished: @escaping (PlaceSuggestionOutcome) -> Void = { _ in }) {
        _viewModel = State(initialValue: viewModel)
        self.onFinished = onFinished
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("placeSuggestion.header.subtitle")
                        .font(.subheadline.weight(.light))
                    options
                    fields
                }
                .padding(.horizontal, 19)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                submitButton
                    .padding(.horizontal, 19)
                    .padding(.vertical, 12)
            }
            .navigationTitle("placeSuggestion.header.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
            }
        }
        .animation(reduceMotion ? nil : .default, value: viewModel.mode)
        .presentationDetents([.height(620), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemBackground))
        // Re-runs when the option changes, so picking "Usar minha localização" again retries a failed lookup.
        .task(id: viewModel.mode) {
            await viewModel.loadCurrentLocation()
        }
        .onChange(of: viewModel.outcome) { _, outcome in
            guard let outcome else { return }
            onFinished(outcome)
        }
    }

    private var options: some View {
        VStack(spacing: 8) {
            PlaceSuggestionOptionRow(
                titleKey: "placeSuggestion.locationOption.title",
                subtitle: locationOptionSubtitle,
                subtitleIsError: viewModel.locationErrorMessage != nil,
                isLoading: viewModel.isResolvingLocation,
                isSelected: viewModel.mode == .currentLocation
            ) {
                viewModel.mode = .currentLocation
            }

            PlaceSuggestionOptionRow(
                titleKey: "placeSuggestion.otherPlaceOption.title",
                subtitle: L10n.string("placeSuggestion.otherPlaceOption.subtitle"),
                isSelected: viewModel.mode == .otherPlace
            ) {
                viewModel.mode = .otherPlace
            }
        }
    }

    private var locationOptionSubtitle: String {
        if let message = viewModel.locationErrorMessage {
            return message
        }
        if let address = viewModel.currentLocation?.address {
            return address
        }
        return L10n.string("placeSuggestion.locationOption.subtitle")
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.mode == .otherPlace {
                AuthFormField(
                    labelKey: "placeSuggestion.placeField.label",
                    placeholderKey: "placeSuggestion.placeField.placeholder",
                    text: $viewModel.placeQuery
                )
            }
            PlaceSuggestionNoteField(text: $viewModel.note)
        }
    }

    private var submitButton: some View {
        PlaceDetailCheckInButton(
            titleKey: "placeSuggestion.submitButton.title",
            hasCheckedIn: false,
            isLoading: viewModel.isSubmitting
        ) {
            Task { await viewModel.submit() }
        }
        .disabled(!viewModel.canSubmit)
        .opacity(viewModel.canSubmit || viewModel.isSubmitting ? 1 : 0.4)
    }
}

#Preview {
    PlaceSuggestionSheetView(onFinished: { _ in })
        .environment(AppCoordinator())
}
