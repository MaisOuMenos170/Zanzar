import SwiftUI

/// The sheet of a roteiro (Figma "checkin v2", nodes 1931:4071, 1937:6463, 2005:11919, 2005:12148 and 2313:6808):
/// who finished it, what it asks for, the seals the user has, the places to go next and the button to start it
/// or to leave it.
struct ItineraryDetailView: View {
    @Bindable var viewModel: ItineraryDetailViewModel
    let onItineraryChanged: () -> Void
    let onSelectPlace: (MapPlace) -> Void
    /// The content rises in once when it first loads.
    @State private var contentShown = false
    @State private var startCount = 0
    @State private var abandonCount = 0
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(NearbyPlacesStore.self) private var nearbyPlacesStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                detailContent(for: detail)
            } else if viewModel.isLoading {
                ProgressView("itinerary.detail.loadingIndicator.title")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView {
                    Label("itinerary.detail.errorState.title", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(viewModel.errorMessage ?? "itinerary.detail.errorState.message")
                } actions: {
                    Button("itinerary.detail.errorState.retryButton.title") {
                        Task { await viewModel.load() }
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .haptic(.sucesso, trigger: startCount)
        .haptic(.toqueSuave, trigger: abandonCount)
        .alert("itinerary.detail.actionError.title", isPresented: $viewModel.showsActionError) {
            Button("itinerary.detail.actionError.dismissButton.title", role: .cancel) {
                viewModel.actionErrorMessage = nil
            }
        } message: {
            if let actionErrorMessage = viewModel.actionErrorMessage {
                Text(actionErrorMessage)
            }
        }
    }

    /// Spacing as in the design: 24 between the blocks, 16 between the text and the ticket, and the title and
    /// the text inset 8 more than the cards.
    private func detailContent(for detail: ItineraryDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    intro(for: detail)
                        .padding(.horizontal, 8)
                        .entrance(contentShown, order: 0)

                    ItineraryTicketCard(
                        slots: viewModel.sealSlots,
                        collectedCount: viewModel.collectedCount,
                        tags: detail.objectives,
                        isActive: viewModel.isCurrentItineraryActive
                    )
                    .entrance(contentShown, order: 1)
                }

                suggestedPlaces(for: detail)
                    .entrance(contentShown, order: 2)
            }
            .padding(.horizontal, 16)
            .onAppear {
                contentShown = true
            }
        }
        .scrollIndicators(.hidden)
        // The close button floats over the top of the sheet, on the row of the title, as in the design.
        .ignoresSafeArea(edges: .top)
        .scrollEdgeEffectHidden(true, for: .top)
        .contentMargins(.top, 28, for: .scrollContent)
        .safeAreaInset(edge: .bottom, spacing: 24) {
            actionButton
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .close) {
                    coordinator.dismissSheet()
                }
            }
        }
    }

    /// The name, who finished the roteiro and what it asks for.
    private func intro(for detail: ItineraryDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(detail.name)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.brandSheetTitle)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Leaves room for the close button.
                .padding(.trailing, 40)
                .padding(.top, 4)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 16) {
                completersRow(for: detail)
                goal(for: detail)
            }
        }
    }

    private func completersRow(for detail: ItineraryDetail) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ItineraryCompletersView(
                avatars: detail.recentCompleters,
                completedCount: detail.completedCount,
                seed: detail.slug
            )
            Spacer(minLength: 0)
            if !detail.routeStops.isEmpty {
                viewRouteButton(stops: detail.routeStops)
            }
        }
    }

    private func viewRouteButton(stops: [ItineraryDetailPlace]) -> some View {
        Button {
            if let url = ItineraryRouteLink.url(for: stops) {
                openURL(url)
            }
        } label: {
            HStack(spacing: 4) {
                Text("itinerary.detail.viewRoute")
                    .typography(.subtitle2)
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.semibold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color.brandOrange600)
            .contentShape(.rect.inset(by: -10))
        }
        .buttonStyle(.plain)
    }

    /// What the roteiro asks for. A free route says it with the category and how many places; a fixed one has a
    /// text of its own.
    @ViewBuilder
    private func goal(for detail: ItineraryDetail) -> some View {
        if detail.routeType == .free, let category = detail.targetCategory, let count = detail.targetCount {
            let name = Text("“\(L10n.string(category.titleKey))”").bold()
            Text("itinerary.detail.goal \(count) \(name)")
                .typography(.body2)
                .foregroundStyle(.black)
        } else if !detail.description.isEmpty {
            Text(detail.description)
                .typography(.body2)
                .foregroundStyle(.black)
        }
    }

    @ViewBuilder
    private func suggestedPlaces(for detail: ItineraryDetail) -> some View {
        let places = detail.suggestedPlaces(from: nearbyPlacesStore.places)
        if !places.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                Text("itinerary.detail.nearbyPlaces")
                    .typography(.subtitle1)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                    .accessibilityAddTraits(.isHeader)

                HStack(alignment: .top, spacing: 8) {
                    ForEach(places.enumerated(), id: \.element.id) { index, place in
                        CheckInPlaceTile(
                            place: place,
                            palette: CheckInPlaceTile.Palette(position: index == 0 ? 0 : 1)
                        ) {
                            onSelectPlace(place)
                        }
                        .frame(height: 124)
                    }
                    if places.count == 1 {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if viewModel.isCurrentItineraryActive {
            Button(action: abandon) {
                actionLabel("itinerary.detail.abandonButton", foreground: Color.brandErrorRed, background: .clear)
                    .overlay { Capsule().strokeBorder(Color.brandErrorRed, lineWidth: 1) }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isPerformingAction)
        } else {
            VStack(spacing: 8) {
                Button(action: start) {
                    actionLabel(
                        "itinerary.detail.startButton",
                        foreground: .white,
                        background: viewModel.hasDifferentActiveItinerary
                            ? Color.brandPurple500.opacity(0.4) : Color.brandPurple500
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isPerformingAction || viewModel.hasDifferentActiveItinerary)

                if viewModel.hasDifferentActiveItinerary {
                    Text("itinerary.detail.actionError.alreadyActive")
                        .typography(.caption1)
                        .foregroundStyle(Color.brandNeutral600)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }

    /// A pill the width of the sheet that shows a spinner in place of its text while the request runs.
    private func actionLabel(_ title: LocalizedStringKey, foreground: Color, background: Color) -> some View {
        Text(title)
            .typography(.subtitle2)
            .foregroundStyle(foreground)
            .opacity(viewModel.isPerformingAction ? 0 : 1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(background, in: .capsule)
            .overlay {
                if viewModel.isPerformingAction {
                    ProgressView()
                        .tint(foreground)
                        .transition(.opacity)
                }
            }
            .contentShape(.capsule)
            .motion(Motion.suave, value: viewModel.isPerformingAction)
    }

    private func start() {
        guard !viewModel.hasDifferentActiveItinerary else { return }
        Task {
            if await viewModel.activateItinerary() {
                startCount += 1
                onItineraryChanged()
                coordinator.dismissSheet()
            }
        }
    }

    private func abandon() {
        Task {
            if await viewModel.abandonItinerary() {
                abandonCount += 1
                onItineraryChanged()
                coordinator.dismissSheet()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ItineraryDetailView(
            viewModel: ItineraryDetailViewModel(slug: "centro-historico"),
            onItineraryChanged: {},
            onSelectPlace: { _ in }
        )
    }
    .environment(AppCoordinator())
    .environment(NearbyPlacesStore())
}
