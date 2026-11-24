import SwiftUI

struct EditNameSheetView: View {
    @State private var viewModel: EditNameViewModel
    @FocusState private var isNameFocused: Bool
    private let onSaved: () -> Void
    private let onClose: () -> Void

    init(currentName: String, onSaved: @escaping () -> Void, onClose: @escaping () -> Void) {
        _viewModel = State(initialValue: EditNameViewModel(currentName: currentName))
        self.onSaved = onSaved
        self.onClose = onClose
    }

    init(viewModel: EditNameViewModel, onSaved: @escaping () -> Void = {}, onClose: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                SheetHeader(
                    title: "profile.editName.title",
                    subtitle: "profile.editName.subtitle"
                )

                VStack(alignment: .leading, spacing: 8) {
                    PlaceSuggestionTextField(
                        labelKey: "profile.editName.field.label",
                        placeholderKey: "profile.editName.field.placeholder",
                        text: $viewModel.name,
                        isFocused: $isNameFocused,
                        isRequired: true,
                        autocapitalization: .never
                    )
                    Text("profile.editName.hint")
                        .font(.footnote)
                        .foregroundStyle(viewModel.showsInvalidHint ? Color.brandErrorRed : Color.brandNeutral600)
                        // The hint turns red without changing words, so say that the name is not valid.
                        .accessibilityValue(viewModel.showsInvalidHint ? Text("accessibility.invalid") : Text(verbatim: ""))
                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Color.brandErrorRed)
                            .announced(message)
                    }
                }
            }
            .padding(.horizontal, 3)

            PlaceSuggestionSubmitButton(
                titleKey: "profile.editName.updateButton.title",
                isLoading: viewModel.isSaving
            ) {
                Task {
                    if await viewModel.save() { onSaved() }
                }
            }
            .disabled(!viewModel.canSave)
            .opacity(viewModel.canSave || viewModel.isSaving ? 1 : 0.4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        // The Figma sheet ends 40pt below the button, counting the home indicator area.
        .padding(.bottom, max(8, 40 - ScreenInsets.bottom))
        .sheetCloseButton(hugsContent: true, isDisabled: viewModel.isSaving, action: onClose)
        .onChange(of: viewModel.name) { _, newValue in
            // Never more than the backend takes, and never a line break.
            let cleaned = String(newValue.replacing("\n", with: "").prefix(EditNameViewModel.lengthRange.upperBound))
            if cleaned != newValue { viewModel.name = cleaned }
        }
        // The keyboard comes once the card has settled: both moving at the same time makes the slide stutter.
        .task {
            try? await Task.sleep(for: .milliseconds(450))
            isNameFocused = true
        }
    }
}

#Preview {
    PlaceSuggestionSheetCard(onClose: {}, content: {
        EditNameSheetView(currentName: "Aline", onSaved: {}, onClose: {})
    })
}
