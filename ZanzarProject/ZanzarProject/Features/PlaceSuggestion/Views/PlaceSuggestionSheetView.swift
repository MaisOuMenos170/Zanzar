import SwiftUI

struct PlaceSuggestionSheetView: View {
    @State private var viewModel: PlaceSuggestionViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isQueryFocused: Bool
    /// Height of everything in the sheet, so it is only as tall as its content (the Figma sheet hugs it) until
    /// the screen runs out of room, and then it scrolls.
    @State private var contentHeight: CGFloat?
    private let onFinished: (PlaceSuggestionOutcome) -> Void
    private let onClose: () -> Void

    init(
        service: PlaceSuggestionServicing = PlaceSuggestionService(),
        onFinished: @escaping (PlaceSuggestionOutcome) -> Void,
        onClose: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: PlaceSuggestionViewModel(service: service))
        self.onFinished = onFinished
        self.onClose = onClose
    }

    init(
        viewModel: PlaceSuggestionViewModel,
        onFinished: @escaping (PlaceSuggestionOutcome) -> Void = { _ in },
        onClose: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onFinished = onFinished
        self.onClose = onClose
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        VStack(alignment: .leading, spacing: 24) {
                            locationOptions
                            VStack(alignment: .leading, spacing: 16) {
                                searchSection
                                resultsSection
                                PlaceSuggestionNoteField(text: $viewModel.note)
                            }
                        }
                    }
                    .padding(.horizontal, 3)

                    submitButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                // The Figma sheet ends 40pt below the button, counting the home indicator area, which the card's
                // content already stays clear of.
                .padding(.bottom, max(8, 40 - ScreenInsets.bottom))
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            .toolbar(.hidden, for: .navigationBar)
        }
        // On the stack, not on the scroll view: a navigation stack takes all the height it is offered.
        .frame(maxHeight: contentHeight ?? .infinity)
        .animation(reduceMotion ? nil : .default, value: viewModel.results)
        .animation(reduceMotion ? nil : .default, value: viewModel.isManualEntry)
        // Re-runs when the option changes, so choosing "use my location" again retries a failed lookup.
        .task(id: viewModel.searchNearMe) {
            await viewModel.loadCurrentLocation()
            viewModel.fillQueryWithCurrentAddress()
        }
        .onChange(of: viewModel.outcome) { _, outcome in
            guard let outcome else { return }
            onFinished(outcome)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("placeSuggestion.header.title")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.brandSheetTitle)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 8)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.brandCloseIcon)
                        .padding(8)
                        .contentShape(.rect)
                }
                .accessibilityLabel("placeSuggestion.closeButton.label")
            }
            .padding(.top, 4)
            .padding(.bottom, 4)

            Text("placeSuggestion.header.subtitle")
                .font(.system(size: 14))
                .tracking(0.25)
                .foregroundStyle(.black)
        }
        .padding(.horizontal, 8)
    }

    private var locationOptions: some View {
        VStack(alignment: .leading, spacing: 8) {
            PlaceSuggestionLocationOption(
                titleKey: "placeSuggestion.locationOption.useMine",
                isSelected: viewModel.searchNearMe
            ) {
                viewModel.useCurrentLocation()
            }

            PlaceSuggestionLocationOption(
                titleKey: "placeSuggestion.locationOption.other",
                isSelected: !viewModel.searchNearMe
            ) {
                viewModel.useAnotherPlace()
            }

            if let status = locationStatus {
                Text(status.text)
                    .font(.footnote)
                    .foregroundStyle(status.isError ? Color.brandErrorRed : Color.brandNeutral600)
                    .padding(.horizontal, 8)
            }
        }
    }

    /// What the user needs to know about the position: it is being found, or it could not be.
    private var locationStatus: (text: String, isError: Bool)? {
        guard viewModel.searchNearMe else { return nil }
        if let message = viewModel.locationErrorMessage {
            return (message, true)
        }
        if viewModel.isResolvingLocation {
            return (L10n.string("placeSuggestion.nearMe.locating"), false)
        }
        return nil
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PlaceSuggestionTextField(
                labelKey: "placeSuggestion.placeField.label",
                placeholderKey: "placeSuggestion.placeField.placeholder",
                text: $viewModel.query,
                isFocused: $isQueryFocused,
                isRequired: true,
                onSearch: {
                    // Drop the keyboard first, or it keeps covering the results this search is about to show.
                    isQueryFocused = false
                    Task { await viewModel.search() }
                },
                canSearch: viewModel.canSearch,
                isSearching: viewModel.isSearching
            )

            if let message = viewModel.searchErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.brandErrorRed)
            }
        }
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
            .foregroundStyle(Color.brandPurple500)
        } else {
            Button("placeSuggestion.manual.button") {
                viewModel.enterManually()
            }
            .font(.footnote.weight(.semibold))
            .tint(Color.brandPurple500)
        }
    }

    private var submitButton: some View {
        PlaceSuggestionSubmitButton(
            titleKey: "placeSuggestion.submitButton.title",
            isLoading: viewModel.isSubmitting
        ) {
            Task { await viewModel.submit() }
        }
        .disabled(!viewModel.canSubmit)
        .opacity(viewModel.canSubmit || viewModel.isSubmitting ? 1 : 0.4)
    }
}

#Preview {
    PlaceSuggestionSheetCard(onClose: {}, content: {
        PlaceSuggestionSheetView(onFinished: { _ in }, onClose: {})
    })
    .environment(AppCoordinator())
}
