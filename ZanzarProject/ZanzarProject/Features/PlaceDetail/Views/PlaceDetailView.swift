import SwiftUI

struct PlaceDetailView: View {
    let place: MapPlace

    @State private var viewModel: PlaceDetailViewModel
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
        .background(.white)
        .navigationBarBackButtonHidden()
        .task {
            await viewModel.load()
        }
    }

    private func content(for detail: PlaceDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PlaceDetailHeaderView(
                    name: detail.name,
                    distanceText: detail.distanceText,
                    openingHoursKey: detail.openingHoursText,
                    onBack: { coordinator.pop() }
                )

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            PlaceDetailHeroImage()

                            HStack(spacing: 8) {
                                ForEach(detail.tags) { tag in
                                    PlaceDetailTagBadge(labelKey: tag.labelKey, style: tag.style)
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

                            Text(detail.description.localizedString)
                                .font(.caption)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    PlaceDetailStatsCard(totalCheckIns: detail.totalCheckIns)

                    PlaceDetailReactionsSection(reactions: detail.reactions)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("placeDetail.nearbySection.title")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)

                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(detail.nearbyPlaces) { nearbyPlace in
                                    PlaceDetailNearbyPlaceCard(place: nearbyPlace)
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }

                    PlaceDetailDirectionsButton {
                        // TODO: open Maps directions when coordinates are wired
                    }
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
