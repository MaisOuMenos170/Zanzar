import SwiftUI
import TipKit

struct PlaceSuggestionSheetView: View {
    @State private var viewModel: PlaceSuggestionViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isQueryFocused: Bool
    @FocusState private var isNameFocused: Bool
    @FocusState private var isAddressFocused: Bool
    /// Height of everything in the sheet, so it is only as tall as its content (the Figma sheet hugs it) until
    /// the screen runs out of room, and then it scrolls.
    @State private var contentHeight: CGFloat?
    /// The search is typed on a screen of its own, over the whole screen.
    @State private var isSearchPresented = false
    private let onFinished: (PlaceSuggestionOutcome) -> Void
    private let onClose: () -> Void

    private let suggestTip = PlaceSuggestionTip()

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
                                manualEntrySection
                                missingFieldsSection
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
            .ignoresSafeArea(.container, edges: .top)
            .scrollEdgeEffectHidden(true, for: .top)
            .containerBackground(.clear, for: .navigation)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close, action: onClose)
                }
            }
        }
        // On the stack, not on the scroll view: a navigation stack takes all the height it is offered.
        .frame(maxHeight: contentHeight ?? .infinity)
        // Until the height is measured the stack would take all the screen for a frame and then shrink.
        .opacity(contentHeight == nil ? 0 : 1)
        .animation(reduceMotion ? nil : .default, value: viewModel.selection)
        .fullScreenCover(isPresented: $isSearchPresented) {
            PlaceSearchView(viewModel: viewModel) { isSearchPresented = false }
        }
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
        SheetHeader(
            title: "placeSuggestion.header.title",
            subtitle: "placeSuggestion.header.subtitle"
        )
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

    /// Shows what was searched and opens the search screen, where it is typed.
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PlaceSuggestionTextField(
                labelKey: "placeSuggestion.searchField.label",
                placeholderKey: "placeSuggestion.searchField.placeholder",
                text: $viewModel.query,
                isFocused: $isQueryFocused,
                submitLabel: .search,
                onTap: { isSearchPresented = true },
                leadingSystemImage: "magnifyingglass",
                placeholderColor: .brandNeutral600
            )
            // VoiceOver and a hardware keyboard focus the field without tapping it.
            .onChange(of: isQueryFocused) {
                guard isQueryFocused else { return }
                isQueryFocused = false
                isSearchPresented = true
            }

            if let message = viewModel.searchErrorMessage {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(Color.brandErrorRed)
            }
        }
    }

    /// The note that the place will be filled in by hand. A place picked in the search is written in the search
    /// field itself.
    @ViewBuilder
    private var manualEntrySection: some View {
        if viewModel.isManualEntry {
            Label("placeSuggestion.manual.selected", systemImage: "checkmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(Color.brandPurple500)
        }
    }

    /// What the chosen place lacks: a name, an address, or both when nothing was found.
    @ViewBuilder
    private var missingFieldsSection: some View {
        if viewModel.needsName || viewModel.needsAddress {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.needsName {
                    VStack(alignment: .leading, spacing: 8) {
                        if !viewModel.isManualEntry {
                            hint("placeSuggestion.nameField.hint")
                        }
                        PlaceSuggestionTextField(
                            labelKey: "placeSuggestion.nameField.label",
                            placeholderKey: "placeSuggestion.nameField.placeholder",
                            text: $viewModel.customName,
                            isFocused: $isNameFocused,
                            isRequired: true,
                            submitLabel: .next
                        )
                    }
                }

                if viewModel.needsAddress {
                    VStack(alignment: .leading, spacing: 8) {
                        if !viewModel.isManualEntry {
                            hint("placeSuggestion.addressField.hint")
                        }
                        PlaceSuggestionTextField(
                            labelKey: "placeSuggestion.addressField.label",
                            placeholderKey: "placeSuggestion.addressField.placeholder",
                            text: $viewModel.customAddress,
                            isFocused: $isAddressFocused,
                            isRequired: true,
                            submitLabel: .done
                        )
                        if let message = viewModel.addressErrorMessage {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(Color.brandErrorRed)
                        }
                    }
                }
            }
        }
    }

    private func hint(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.footnote)
            .foregroundStyle(Color.brandNeutral600)
    }

    private var submitButton: some View {
        PlaceSuggestionSubmitButton(
            titleKey: "placeSuggestion.submitButton.title",
            isLoading: viewModel.isSubmitting
        ) {
            Task { await viewModel.submit() }
            PlaceSuggestionTip.hasUsedDiscover = true
        }
        .disabled(!viewModel.canSubmit)
        .opacity(viewModel.canSubmit || viewModel.isSubmitting ? 1 : 0.4)
        .popoverTip(suggestTip, arrowEdge: .top)
    }
}

#Preview {
    PlaceSuggestionSheetCard(onClose: {}, content: {
        PlaceSuggestionSheetView(onFinished: { _ in }, onClose: {})
    })
    .environment(AppCoordinator())
}
