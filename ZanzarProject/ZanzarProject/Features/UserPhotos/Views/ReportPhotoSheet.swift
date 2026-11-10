import SwiftUI

/// Reporting someone else's photo, with the option to block its author too.
struct ReportPhotoSheet: View {
    let onFinished: () -> Void
    @State private var viewModel: ReportPhotoViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNoteFocused: Bool

    init(photoID: String, placeID: String, onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
        _viewModel = State(initialValue: ReportPhotoViewModel(photoID: photoID, placeID: placeID))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("userPhotos.report.reason.title") {
                    Picker("userPhotos.report.reason.title", selection: $viewModel.reason) {
                        ForEach(PhotoReportReason.allCases) { reason in
                            Text(LocalizedStringKey(reason.titleKey)).tag(Optional(reason))
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    TextField("userPhotos.report.note.placeholder", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($isNoteFocused)
                        // Return adds a line in a multi-line field, so the keyboard needs its own way out.
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("keyboard.doneButton.title") { isNoteFocused = false }
                            }
                        }
                }
                Section {
                    Toggle("userPhotos.report.blockToggle.label", isOn: $viewModel.alsoBlocksAuthor)
                } footer: {
                    Text("userPhotos.report.footer")
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("userPhotos.report.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("userPhotos.report.cancelButton.title") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("userPhotos.report.sendButton.title") {
                        Task { await viewModel.submit() }
                    }
                    .disabled(!viewModel.canSubmit)
                }
            }
            .onChange(of: viewModel.didFinish) { _, finished in
                guard finished else { return }
                onFinished()
                dismiss()
            }
        }
    }
}
