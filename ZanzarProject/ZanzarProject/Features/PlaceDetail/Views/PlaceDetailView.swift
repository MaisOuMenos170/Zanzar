import SwiftUI

struct PlaceDetailView: View {
    let place: MapPlace

    @State private var viewModel: PlaceDetailViewModel
    @State private var mediaPolicy = PlaceMediaAccessPolicy.shared
    @Environment(AppCoordinator.self) private var coordinator
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
            await viewModel.load()
            viewModel.updateCellularImagesPromptIfNeeded(using: mediaPolicy)
        }
        .onChange(of: mediaPolicy.usesCellular) { _, _ in
            viewModel.updateCellularImagesPromptIfNeeded(using: mediaPolicy)
        }
        .onChange(of: viewModel.detail?.heroPhotoReference) { _, _ in
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
        .animation(.default, value: viewModel.earnedSealPresentation != nil)
        .animation(.default, value: viewModel.showsCompletedItineraryAlert)
    }

    private func checkInConfirmationMessage(for placeName: String) -> AttributedString {
        var name = AttributedString(placeName)
        name.inlinePresentationIntent = .stronglyEmphasized
        return AttributedString(localized: "placeDetail.checkInConfirmation.message.prefix")
            + name
            + AttributedString(localized: "placeDetail.checkInConfirmation.message.suffix")
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PlaceDetailHeaderView(
                    name: detail.displayName,
                    distanceText: detail.distanceText,
                    openingHoursText: detail.openingHoursText,
                    onBack: { coordinator.pop() }
                )

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            PlaceDetailHeroImage(
                                photoReference: detail.heroPhotoReference,
                                mediaPolicy: mediaPolicy
                            )

                            if !detail.tags.isEmpty {
                                HStack(spacing: 8) {
                                    ForEach(detail.tags) { tag in
                                        PlaceDetailTagBadge(label: tag.label, style: tag.style)
                                    }
                                }
                            }
                        }

                        PlaceDetailCheckInButton(
                            hasCheckedIn: detail.hasCheckedIn,
                            isLoading: viewModel.isCheckingIn
                        ) {
                            viewModel.requestCheckIn()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("placeDetail.detailsSection.title")
                                .font(.headline)
                                .bold()
                                .foregroundStyle(.primary)

                            Text(detail.description)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    PlaceDetailStatsCard(
                        totalCheckIns: detail.totalCheckIns,
                        category: detail.category,
                        hasCheckedIn: detail.hasCheckedIn,
                        isInActiveItinerary: detail.isInActiveItinerary
                    )

                    PlaceDetailReactionsSection(reactions: detail.reactions)

                    if !detail.nearbyPlaces.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("placeDetail.nearbySection.title")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)

                            ScrollView(.horizontal) {
                                HStack(spacing: 8) {
                                    ForEach(detail.nearbyPlaces) { nearbyPlace in
                                        PlaceDetailNearbyPlaceCard(
                                            place: nearbyPlace,
                                            mediaPolicy: mediaPolicy
                                        ) {
                                            coordinator.push(.placeDetail(nearbyPlace.mapPlace))
                                        }
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                            // Without this the scroll view clips the cards' shadows at its bounds.
                            .scrollClipDisabled()
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
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
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
}
