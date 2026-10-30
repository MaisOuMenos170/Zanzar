import SwiftUI

struct PlaceDetailView: View {
    let place: MapPlace

    @State private var viewModel: PlaceDetailViewModel
    @State private var mediaPolicy = PlaceMediaAccessPolicy.shared
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(NearbyPlacesStore.self) private var nearbyPlaces
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    init(place: MapPlace) {
        self.place = place
        _viewModel = State(initialValue: PlaceDetailViewModel(place: place))
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                content(for: detail)
            } else if viewModel.isLoading {
                ProgressView("placeDetail.loadingIndicator.title")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    "placeDetail.errorState.title",
                    systemImage: "exclamationmark.triangle",
                    description: Text(viewModel.errorMessage ?? "placeDetail.errorState.message")
                )
            }
        }
        .background(.background)
        .navigationBarBackButtonHidden()
        .task {
            // The view reappears when a nested detail is popped; what is already on screen is still current.
            guard viewModel.detail == nil else { return }
            await viewModel.load(nearbyPlaces: nearbyPlaces.places)
            viewModel.updateCellularImagesPromptIfNeeded(using: mediaPolicy)
        }
        .onChange(of: mediaPolicy.usesCellular) { _, _ in
            viewModel.updateCellularImagesPromptIfNeeded(using: mediaPolicy)
        }
        .onChange(of: viewModel.detail?.photos) { _, _ in
            viewModel.updateCellularImagesPromptIfNeeded(using: mediaPolicy)
        }
        .alert("placeDetail.cellularPrompt.title", isPresented: $viewModel.showsCellularImagesPrompt) {
            Button("placeDetail.cellularPrompt.allowButton.title") {
                viewModel.allowCellularImages()
            }
            Button("placeDetail.cellularPrompt.declineButton.title", role: .cancel) {}
        } message: {
            Text("placeDetail.cellularPrompt.message")
        }
        .alert("placeDetail.errorAlert.title", isPresented: errorAlertIsPresented) {
            Button("placeDetail.errorAlert.dismissButton.title", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("placeDetail.checkInConfirmation.title", isPresented: $viewModel.showsCheckInConfirmation) {
            Button("placeDetail.checkInConfirmation.cancelButton.title", role: .cancel) {}
            Button("placeDetail.checkInConfirmation.confirmButton.title") {
                Task { await viewModel.confirmCheckIn() }
            }
        } message: {
            if let placeName = viewModel.detail?.displayName {
                Text(checkInConfirmationMessage(for: placeName))
            }
        }
        .alert(checkInWarningTitle, isPresented: checkInWarningIsPresented) {
            Button("placeDetail.errorAlert.dismissButton.title", role: .cancel) {
                viewModel.checkInWarning = nil
            }
        } message: {
            Text(checkInWarningMessage)
        }
        .overlay {
            if let presentation = viewModel.earnedSealPresentation {
                SealEarnedAlertView(
                    placeName: presentation.placeName,
                    category: presentation.category,
                    onAccept: viewModel.dismissEarnedSealAlert
                )
                .transition(.opacity)
            } else if viewModel.showsCompletedItineraryAlert {
                ItineraryCompletedAlertView(onAccept: viewModel.dismissCompletedItineraryAlert)
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .default, value: viewModel.earnedSealPresentation != nil)
        .animation(reduceMotion ? nil : .default, value: viewModel.showsCompletedItineraryAlert)
    }

    private func checkInConfirmationMessage(for placeName: String) -> AttributedString {
        var name = AttributedString(placeName)
        name.inlinePresentationIntent = .stronglyEmphasized
        return AttributedString(localized: "placeDetail.checkInConfirmation.message.prefix")
            + name
            + AttributedString(localized: "placeDetail.checkInConfirmation.message.suffix")
    }

    private var checkInWarningIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.checkInWarning != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.checkInWarning = nil
                }
            }
        )
    }

    private var checkInWarningTitle: LocalizedStringKey {
        switch viewModel.checkInWarning {
        case .tooFar:
            "placeDetail.checkInWarning.tooFar.title"
        case .locationRequired:
            "placeDetail.checkInWarning.locationRequired.title"
        case .locationUncertain, nil:
            "placeDetail.checkInWarning.locationUncertain.title"
        }
    }

    private var checkInWarningMessage: LocalizedStringKey {
        switch viewModel.checkInWarning {
        case .tooFar:
            "placeDetail.checkInWarning.tooFar.message"
        case .locationRequired:
            "placeDetail.checkInWarning.locationRequired.message"
        case .locationUncertain, nil:
            "placeDetail.checkInWarning.locationUncertain.message"
        }
    }

    private var errorAlertIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && viewModel.detail != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    private func content(for detail: PlaceDetail) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            PlaceDetailHeaderView(
                name: detail.displayName,
                distanceText: detail.distanceText,
                walkingTimeText: detail.walkingTimeText,
                openingHoursText: detail.openingHoursText,
                isOpen: detail.isOpen,
                onBack: { coordinator.pop() }
            )
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(Color(.systemBackground))

            ScrollView {
                detailBody(for: detail)
                    .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func detailBody(for detail: PlaceDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                PlaceDetailHeroSection(
                    photos: detail.photos,
                    placeName: detail.displayName,
                    tags: detail.tags,
                    mediaPolicy: mediaPolicy
                )

                PlaceDetailCheckInButton(
                    hasCheckedIn: detail.hasCheckedIn,
                    isLoading: viewModel.isCheckingIn
                ) {
                    viewModel.requestCheckIn()
                }

                PlaceDetailDescriptionSection(description: detail.description)
            }

            PlaceDetailStatsCard(
                totalCheckIns: detail.totalCheckIns,
                category: detail.category,
                hasCheckedIn: detail.hasCheckedIn,
                isInActiveItinerary: detail.isInActiveItinerary
            )

            PlaceDetailReactionsSection(reactions: detail.reactions)

            if !detail.nearbyPlaces.isEmpty {
                PlaceDetailNearbySection(
                    places: detail.nearbyPlaces,
                    mediaPolicy: mediaPolicy
                ) { place in
                    coordinator.push(.placeDetail(place))
                }
            }

            PlaceDetailDirectionsButton(
                latitude: detail.latitude,
                longitude: detail.longitude,
                placeName: detail.displayName
            )
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        PlaceDetailView(
            place: MapPlace(
                id: "preview",
                name: "Jardim Botânico",
                latitude: -25.4,
                longitude: -49.2,
                category: .park,
                distanceMeters: 1300
            )
        )
    }
    .environment(AppCoordinator())
    .environment(NearbyPlacesStore())
}
