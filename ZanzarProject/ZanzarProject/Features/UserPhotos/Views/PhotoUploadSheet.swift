import PhotosUI
import SwiftUI

/// Sending a photo of a place, from the library or the camera. Presented as a sheet by the place screen.
struct PhotoUploadSheet: View {
    @State private var viewModel: PhotoUploadViewModel
    @State private var pickerItem: PhotosPickerItem?
    @State private var showsCamera = false
    @State private var cameraMessage: LocalizedStringKey?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    init(placeID: String, placeName: String, fromCheckIn: Bool) {
        _viewModel = State(
            initialValue: PhotoUploadViewModel(placeID: placeID, placeName: placeName, fromCheckIn: fromCheckIn)
        )
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(viewModel.step == .editing
                    ? LocalizedStringKey("userPhotos.editor.title")
                    : LocalizedStringKey("userPhotos.upload.title"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("userPhotos.upload.closeButton.title") { dismiss() }
                            .disabled(viewModel.step == .uploading)
                    }
                }
        }
        // The editor is a drag-heavy surface: a swipe down must not throw the photo away (the Close button still can).
        .interactiveDismissDisabled(
            viewModel.step == .uploading || viewModel.step == .analyzing || viewModel.step == .editing
        )
        .task { await viewModel.start() }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                pickerItem = nil
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.pick(data)
                } else {
                    await viewModel.pick(Data())
                }
            }
        }
        .fullScreenCover(isPresented: $showsCamera) {
            CameraPicker { data in
                Task { await viewModel.pick(data) }
            }
            .ignoresSafeArea()
        }
        .alert("userPhotos.camera.alert.title", isPresented: cameraAlertIsPresented) {
            if cameraMessage == "userPhotos.camera.denied.message" {
                Button("userPhotos.camera.openSettingsButton.title") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
            }
            Button("userPhotos.camera.dismissButton.title", role: .cancel) {}
        } message: {
            if let cameraMessage { Text(cameraMessage) }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.step {
        case .checkingTerms, .preparing, .analyzing:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .editing:
            if let original = viewModel.original {
                PhotoEditorView(
                    image: original,
                    onConfirm: { edit in Task { await viewModel.applyEdit(edit) } },
                    onChooseAnother: viewModel.cancelEditing
                )
            }
        case .needsTerms:
            PhotoTermsView(onAccepted: viewModel.termsAccepted)
        case .choosing:
            choosing
        case .faceWarning:
            faceWarning
        case .preview:
            preview
        case .uploading:
            ProgressView("userPhotos.upload.sending")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .sent:
            sent
        case .failed(let error):
            failed(error)
        }
    }

    private var choosing: some View {
        VStack(spacing: 16) {
            Text(L10n.string("userPhotos.upload.choosing.message", viewModel.placeName))
                .multilineTextAlignment(.center)
            if viewModel.fromCheckIn {
                Label("userPhotos.upload.verified.message", systemImage: "checkmark.seal")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            PhotosPicker(selection: $pickerItem, matching: .images, photoLibrary: .shared()) {
                Label("userPhotos.upload.libraryButton.title", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Button {
                Task { await openCamera() }
            } label: {
                Label("userPhotos.upload.cameraButton.title", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            Text("userPhotos.upload.reviewNotice")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxHeight: .infinity)
    }

    private var faceWarning: some View {
        ScrollView {
            VStack(spacing: 16) {
                photoPreview
                Label("userPhotos.upload.faceWarning.title", systemImage: "person.crop.square")
                    .font(.headline)
                Text("userPhotos.upload.faceWarning.message")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("userPhotos.upload.faceWarning.anotherButton.title") { viewModel.chooseAnother() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button("userPhotos.upload.faceWarning.blurButton.title") {
                    Task { await viewModel.blurFaces() }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                Button("userPhotos.upload.preview.editButton.title") { viewModel.editAgain() }
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
    }

    private var preview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                photoPreview
                if viewModel.hasBlurredFaces {
                    Label("userPhotos.upload.preview.blurredNotice", systemImage: "eye.slash")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Toggle("userPhotos.upload.preview.showNameToggle.label", isOn: $viewModel.showsAuthorName)
                Text(viewModel.showsAuthorName
                    ? LocalizedStringKey("userPhotos.upload.preview.showName.on")
                    : LocalizedStringKey("userPhotos.upload.preview.showName.off"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button {
                    Task { await viewModel.send() }
                } label: {
                    Text("userPhotos.upload.preview.sendButton.title")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Button("userPhotos.upload.preview.editButton.title") { viewModel.editAgain() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                Button("userPhotos.upload.preview.anotherButton.title") { viewModel.chooseAnother() }
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let image = viewModel.image {
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 320)
                .clipShape(.rect(cornerRadius: 16))
                .frame(maxWidth: .infinity)
                .accessibilityLabel(Text("userPhotos.upload.preview.accessibilityLabel"))
        }
    }

    private var sent: some View {
        ContentUnavailableView {
            Label("userPhotos.upload.sent.title", systemImage: "hourglass")
        } description: {
            Text("userPhotos.upload.sent.message")
        } actions: {
            Button("userPhotos.upload.sent.doneButton.title") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func failed(_ error: PhotoUploadError) -> some View {
        ContentUnavailableView {
            Label("userPhotos.upload.failed.title", systemImage: "exclamationmark.triangle")
        } description: {
            Text(LocalizedStringKey(error.messageKey))
        } actions: {
            Button(error.isRetryable
                ? LocalizedStringKey("userPhotos.upload.failed.retryButton.title")
                : LocalizedStringKey("userPhotos.upload.failed.anotherButton.title")) {
                viewModel.recover()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func openCamera() async {
        switch CameraAccess.current {
        case .available:
            showsCamera = true
        case .notDetermined:
            if await CameraAccess.request() {
                showsCamera = true
            } else {
                cameraMessage = "userPhotos.camera.denied.message"
            }
        case .denied:
            cameraMessage = "userPhotos.camera.denied.message"
        case .restricted:
            cameraMessage = "userPhotos.camera.restricted.message"
        case .unavailable:
            cameraMessage = "userPhotos.camera.unavailable.message"
        }
    }

    private var cameraAlertIsPresented: Binding<Bool> {
        Binding(get: { cameraMessage != nil }, set: { if !$0 { cameraMessage = nil } })
    }
}
