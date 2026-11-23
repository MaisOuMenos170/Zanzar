import SwiftUI
import TipKit

struct PlaceDetailView: View {
    let place: MapPlace

    @State private var viewModel: PlaceDetailViewModel
    @State private var mediaPolicy = PlaceMediaAccessPolicy.shared
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(ToastManager.self) private var toasts
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsPhotoUpload = false
    /// The content rises in once when it first loads, not again when a nested screen is popped.
    @State private var contentShown = false

    // Tips
    private let checkInTip = PlaceDetailCheckInTip()
    private let addPhotoTip = PlaceDetailAddPhotoTip()
    private let directionsTip = PlaceDetailDirectionsTip()

    init(place: MapPlace) {
        self.place = place
        _viewModel = State(initialValue: PlaceDetailViewModel(place: place))
    }

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                content(for: detail)
            } else if viewModel.isLoading {
                PlaceDetailSkeleton()
            } else {
                ContentUnavailableView(
                    "placeDetail.errorState.title",
                    systemImage: "exclamationmark.triangle",
                    description: Text(viewModel.errorMessage ?? "placeDetail.errorState.message")
                )
            }
        }
        .background(Color.profileBackground)
        .screenTitle("placeDetail.header.title")
        .toolbar {
            if let detail = viewModel.detail {
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: PlaceLink.url(for: detail.id),
                        subject: Text(detail.displayName),
                        message: Text(detail.displayName)
                    ) {
                        Label("placeDetail.shareButton.label", systemImage: "square.and.arrow.up")
                    }
                    // Pushed from the check-in tab, the screen inherits that tab's orange tint; this button stays black.
                    .tint(.black)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .task {
            // The view reappears when a nested detail is popped; what is already on screen is still current.
            guard viewModel.detail == nil else { return }
            await viewModel.load()
            viewModel.updateCellularImagesPromptIfNeeded(using: mediaPolicy)
        }
        .task {
            await viewModel.loadSavedState()
        }
        .onChange(of: mediaPolicy.usesCellular) { _, _ in
            viewModel.updateCellularImagesPromptIfNeeded(using: mediaPolicy)
        }
        .onChange(of: viewModel.displayedPhotos) { _, _ in
            viewModel.updateCellularImagesPromptIfNeeded(using: mediaPolicy)
        }
        .modifier(PlaceDetailUserPhotoFlows(
            showsPhotoUpload: $showsPhotoUpload,
            placeID: place.id,
            detail: viewModel.detail,
            reloadUserPhotos: viewModel.loadUserPhotos
        ))
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
        .haptic(.alerta, trigger: viewModel.checkInWarning, when: { _, warning in warning != nil })
        .haptic(.alerta, trigger: viewModel.errorMessage, when: { _, message in message != nil })
    }

    /// The bookmark in the corner of the photo box: white behind it, so it reads over a photo too.
    private var bookmarkButton: some View {
        Button {
            Task { showSaveToast(for: await viewModel.toggleSaved()) }
        } label: {
            Label(
                viewModel.isSaved ? "placeDetail.saveButton.remove" : "placeDetail.saveButton.save",
                systemImage: viewModel.isSaved ? "bookmark.fill" : "bookmark"
            )
            .labelStyle(.iconOnly)
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(Color.brandOrange600)
            .contentTransition(.symbolEffect(.replace))
            .frame(width: 36, height: 36)
            .background(Color.brandNeutral50, in: .circle)
            .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .motion(Motion.suave, value: viewModel.isSaved)
        .haptic(.selecao, trigger: viewModel.isSaved)
    }

    private func showSaveToast(for outcome: PlaceDetailViewModel.SaveOutcome?) {
        switch outcome {
        case .saved:
            toasts.show(L10n.string("placeDetail.saveButton.savedToast"), style: .positive, position: .bottom)
        case .removed:
            toasts.show(L10n.string("placeDetail.saveButton.removedToast"), style: .positive, position: .bottom)
        case .failed(let message):
            toasts.show(message, style: .negative, position: .bottom)
        case nil:
            break
        }
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
        ScrollView {
            detailBody(for: detail)
                .padding(.top, 8)
                .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private func detailBody(for detail: PlaceDetail) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                PlaceDetailTitleRow(
                    name: detail.displayName,
                    distanceText: detail.distanceText,
                    openingHoursText: detail.openingHoursText,
                    isOpen: detail.isOpen,
                    latitude: detail.latitude,
                    longitude: detail.longitude
                )
                .entrance(contentShown, order: 0)
                .popoverTip(directionsTip, arrowEdge: .top)

                PlacePhotoCard(
                    tags: detail.tags.map(\.label),
                    showsPhotos: !viewModel.displayedPhotos.isEmpty,
                    addPhotoHint: detail.hasCheckedIn
                        ? "placeDetail.addPhotoButton.verifiedHint"
                        : "placeDetail.addPhotoButton.hint",
                    onAddPhoto: {
                        showsPhotoUpload = true
                        PlaceDetailAddPhotoTip.hasViewedPlaceDetail = true
                    },
                    accessory: { bookmarkButton },
                    photos: {
                        PlaceDetailPhotoCarousel(
                            photos: viewModel.displayedPhotos,
                            placeName: detail.displayName,
                            mediaPolicy: mediaPolicy,
                            height: .placePhotoCardHeight
                        )
                    }
                )
                .entrance(contentShown, order: 1)
                .popoverTip(addPhotoTip, arrowEdge: .top)

                PlaceDetailCheckInButton(
                    hasCheckedIn: detail.hasCheckedIn,
                    isLoading: viewModel.isCheckingIn
                ) {
                    viewModel.requestCheckIn()
                    PlaceDetailCheckInTip.hasViewedPlaceDetail = true
                }
                .entrance(contentShown, order: 1)
                .popoverTip(checkInTip, arrowEdge: .top)
            }

            PlaceDetailDescriptionSection(description: detail.description)
                .entrance(contentShown, order: 2)

            PlaceDetailStatsCard(
                totalCheckIns: detail.totalCheckIns,
                category: detail.category,
                hasCheckedIn: detail.hasCheckedIn,
                isInActiveItinerary: detail.isInActiveItinerary
            )
            .entrance(contentShown, order: 2)
        }
        .padding(.horizontal, 16)
        .onAppear {
            contentShown = true
        }
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
    .environment(ToastManager())
}
