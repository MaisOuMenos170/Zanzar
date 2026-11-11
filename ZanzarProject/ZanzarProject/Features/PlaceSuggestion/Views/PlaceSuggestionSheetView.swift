import SwiftUI

struct PlaceSuggestionSheetView: View {
    @State private var viewModel: PlaceSuggestionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isQueryFocused: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var searchButtonSize: CGFloat = 51
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
                VStack(alignment: .leading, spacing: 20) {
                    Text("placeSuggestion.header.subtitle")
                        .font(.subheadline.weight(.light))
                    searchSection
                    resultsSection
                    PlaceSuggestionNoteField(text: $viewModel.note)
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
        .animation(reduceMotion ? nil : .default, value: viewModel.results)
        .animation(reduceMotion ? nil : .default, value: viewModel.isManualEntry)
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(620), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(.systemBackground))
        // Re-runs when the toggle changes, so turning "near me" on again retries a failed lookup.
        .task(id: viewModel.searchNearMe) {
            await viewModel.loadCurrentLocation()
        }
        .onChange(of: viewModel.outcome) { _, outcome in
            guard let outcome else { return }
            onFinished(outcome)
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AdaptiveStack(horizontalAlignment: .trailing, verticalAlignment: .bottom, spacing: 8) {
                AuthFormField(
                    labelKey: "placeSuggestion.placeField.label",
                    placeholderKey: "placeSuggestion.placeField.placeholder",
                    text: $viewModel.query,
                    submitLabel: .search,
                    capitalization: .words,
                    disablesAutocorrection: false,
                    isFocused: $isQueryFocused
                )
                .onSubmit { Task { await viewModel.search() } }

                Button {
                    // Drop the keyboard first, or it keeps covering the results this search is about to show.
                    isQueryFocused = false
                    Task { await viewModel.search() }
                } label: {
                    if viewModel.isSearching {
                        ProgressView()
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .font(.body.weight(.semibold))
                .frame(width: searchButtonSize, height: searchButtonSize)
                .foregroundStyle(.white)
                .background(Color("WelcomePrimary"), in: .circle)
                .disabled(!viewModel.canSearch)
                .opacity(viewModel.canSearch || viewModel.isSearching ? 1 : 0.4)
                .accessibilityLabel("placeSuggestion.searchButton.label")
            }

            Toggle(isOn: $viewModel.searchNearMe) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("placeSuggestion.nearMe.title")
                        .font(.subheadline.weight(.semibold))
                    Text(nearMeSubtitle)
                        .font(.footnote)
                        .foregroundStyle(viewModel.locationErrorMessage != nil ? Color("AuthError") : Color.secondary)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
                }
            }
            .tint(Color("WelcomePrimary"))

            if let message = viewModel.searchErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color("AuthError"))
            }
        }
    }

    private var nearMeSubtitle: String {
        if let message = viewModel.locationErrorMessage {
            return message
        }
        if viewModel.isResolvingLocation {
            return L10n.string("placeSuggestion.nearMe.locating")
        }
        return viewModel.currentLocation?.address ?? L10n.string("placeSuggestion.nearMe.subtitle")
    }

    @ViewBuilder
    private var resultsSection: some View {
        if viewModel.hasSearched {
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.results.isEmpty {
                    Text("placeSuggestion.results.empty")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.results) { place in
                        PlaceSuggestionResultRow(
                            place: place,
                            isSelected: viewModel.selectedPlace == place
                        ) {
                            viewModel.select(place)
                        }
                    }
                    Text("placeSuggestion.results.attribution")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                manualEntry
            }
        }
    }

    @ViewBuilder
    private var manualEntry: some View {
        if viewModel.isManualEntry {
            Label(
                L10n.string("placeSuggestion.manual.selected", viewModel.trimmedQuery),
                systemImage: "checkmark.circle.fill"
            )
            .font(.footnote)
            .foregroundStyle(Color("WelcomePrimary"))
        } else {
            Button("placeSuggestion.manual.button") {
                viewModel.enterManually()
            }
            .font(.footnote.weight(.semibold))
            .tint(Color("WelcomePrimary"))
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
