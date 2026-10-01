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
                    name: detail.name,
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
                            Task {
                                await viewModel.performCheckIn()
                            }
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

                    PlaceDetailStatsCard(totalCheckIns: detail.totalCheckIns)

                    PlaceDetailReactionsSection(
                        reactions: detail.reactions,
                        canReact: detail.hasCheckedIn && detail.selectedReactionTag == nil,
                        isSubmitting: viewModel.isSubmittingReaction
                    ) { impressionTag in
                        Task {
                            await viewModel.selectReaction(impressionTag)
                        }
                    }

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
                        }
                    }

                    PlaceDetailDirectionsButton(
                        latitude: detail.latitude,
                        longitude: detail.longitude,
                        placeName: detail.name
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
