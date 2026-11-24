import CoreLocation
import SwiftUI

/// The place that was read, ready to be confirmed: where it is, which one it is when there are several, an optional
/// note and the send button.
struct ShareReadyView: View {
    @Bindable var model: PlaceShareViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SheetHeader(
                        title: "placeShare.header.title",
                        subtitle: "placeShare.header.subtitle"
                    )
                    if let coordinate = mapCoordinate {
                        SharePlaceMap(coordinate: coordinate)
                    }
                    placeSection
                    PlaceSuggestionNoteField(text: $model.note)
                    errors
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)

            PlaceSuggestionSubmitButton(
                titleKey: "placeSuggestion.submitButton.title",
                isLoading: model.phase == .submitting
            ) {
                Task { await model.submit() }
            }
            .disabled(!model.canSubmit)
            .opacity(model.canSubmit || model.phase == .submitting ? 1 : 0.4)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .haptic(.selecao, trigger: model.selectedPlace)
        .motion(Motion.suave, value: model.isManualChosen)
    }

    /// Where the pin goes: the chosen place, else the position the link carried.
    private var mapCoordinate: CLLocationCoordinate2D? {
        if let place = model.selectedPlace {
            return CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
        }
        return model.hint.coordinate.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    @ViewBuilder
    private var placeSection: some View {
        if model.candidates.isEmpty {
            notFound
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text("placeShare.candidates.title")
                    .font(.system(size: 14))
                    .foregroundStyle(.black)
                ForEach(model.candidates) { place in
                    PlaceShareCandidateRow(place: place, isSelected: model.selectedPlace == place) {
                        model.select(place)
                    }
                }
                manualOption
            }
        }
    }

    /// Nothing on the map matched: what was read goes to the team as it is, and the sheet says so.
    private var notFound: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("placeShare.manual.title")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.brandSheetTitle)
            Text("placeShare.manual.message")
                .font(.system(size: 14))
                .foregroundStyle(Color.brandNeutral600)
            if let address = model.manualLocation?.address {
                VStack(alignment: .leading, spacing: 2) {
                    Text("placeShare.address.label")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(address)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.brandPurple50, in: .rect(cornerRadius: 8))
                .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(Color.brandPurple400, lineWidth: 1) }
                .accessibilityElement(children: .combine)
            }
        }
    }

    @ViewBuilder
    private var manualOption: some View {
        if model.isManualChosen {
            Label("placeShare.manual.option", systemImage: "checkmark.circle.fill")
                .font(.footnote)
                .foregroundStyle(Color.brandPurple500)
        } else if model.manualLocation != nil {
            Button("placeShare.manual.option") { model.chooseManual() }
                .font(.footnote.weight(.semibold))
                .tint(Color.brandPurple500)
        }
    }

    @ViewBuilder
    private var errors: some View {
        ForEach([model.searchErrorMessage, model.submitErrorMessage].compactMap { $0 }, id: \.self) { message in
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.brandErrorRed)
        }
    }
}
