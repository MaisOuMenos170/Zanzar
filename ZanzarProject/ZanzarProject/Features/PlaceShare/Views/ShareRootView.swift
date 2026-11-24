import SwiftUI

/// The share sheet: reading, confirming, or the one thing there is to say when the place cannot be sent.
struct ShareRootView: View {
    @State private var model: PlaceShareViewModel
    let onClose: () -> Void

    init(model: PlaceShareViewModel, onClose: @escaping () -> Void) {
        _model = State(initialValue: model)
        self.onClose = onClose
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.brandNeutral50.ignoresSafeArea())
            .sheetCloseButton(action: onClose)
            .motion(Motion.suave, value: model.phase)
            .task { await model.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .reading:
            ShareReadingView(onClose: onClose)
        case .ready, .submitting:
            ShareReadyView(model: model, onClose: onClose)
        case .unreadable:
            ShareMessageView(
                face: "CarinhaChoro",
                title: Text("placeShare.unreadable.title"),
                message: Text("placeShare.unreadable.message"),
                onClose: onClose
            )
        case .outsideArea:
            ShareMessageView(
                face: "CarinhaChoro",
                title: Text("placeShare.outsideArea.title"),
                message: Text("placeShare.outsideArea.message"),
                onClose: onClose
            )
        case .signedOut:
            ShareMessageView(
                face: "CarinhaBocejando",
                title: Text("placeShare.signedOut.title"),
                message: Text("placeShare.signedOut.message"),
                onClose: onClose
            )
        case .done(let outcome):
            doneView(for: outcome)
        }
    }

    /// The same words the app uses when "Sugerir um lugar" is answered.
    private func doneView(for outcome: PlaceSuggestionOutcome) -> some View {
        let title: Text
        let message: Text
        switch outcome {
        case .success:
            title = Text("placeSuggestion.successAlert.title")
            message = Text("placeSuggestion.successAlert.message")
        case .published(let placeName):
            title = Text("placeSuggestion.publishedAlert.title")
            message = Text(L10n.string("placeSuggestion.publishedAlert.message", placeName))
        case .refused(let reason):
            title = Text("placeSuggestion.refusedAlert.title")
            message = Text(LocalizedStringKey(reason.messageKey))
        case .failure(let text):
            title = Text("placeSuggestion.failureAlert.title")
            message = Text(text)
        }
        return ShareMessageView(
            face: outcome.isGoodNews ? "CarinhaFeliz" : "CarinhaChoro",
            title: title,
            message: message,
            celebrates: outcome.isGoodNews,
            onClose: onClose
        )
        // Good news closes by itself once it has been read; the rest waits for the person.
        .task {
            guard outcome.isGoodNews else { return }
            try? await Task.sleep(for: .seconds(2.4))
            onClose()
        }
    }
}
