import SwiftUI

/// The explanation the user reads and accepts before the first photo. `onAccepted` runs once they may send photos.
struct PhotoTermsView: View {
    let onAccepted: () -> Void
    @State private var viewModel = PhotoTermsViewModel()

    private static let latestBirthDate = Calendar.current.date(byAdding: .year, value: -10, to: .now) ?? .now
    private static let suggestedBirthDate = Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("userPhotos.terms.intro")
                    .font(.body)

                PhotoTermsContent()

                VStack(alignment: .leading, spacing: 12) {
                    Text("userPhotos.terms.birthDate.title")
                        .font(.headline)
                    Text("userPhotos.terms.birthDate.message")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    DatePicker(
                        "userPhotos.terms.birthDate.label",
                        selection: birthDateBinding,
                        in: ...Self.latestBirthDate,
                        displayedComponents: .date
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("userPhotos.terms.acceptToggle.label", isOn: $viewModel.acceptsTerms)
                    Toggle("userPhotos.terms.aiToggle.label", isOn: $viewModel.acceptsAIAnalysis)
                }

                if viewModel.isUnderage {
                    Label("userPhotos.terms.underage.message", systemImage: "person.badge.clock")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.subheadline)
                }

                Button {
                    Task {
                        if await viewModel.submit() {
                            onAccepted()
                        }
                    }
                } label: {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("userPhotos.terms.acceptButton.title")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canSubmit || viewModel.isUnderage)
            }
            .padding(16)
        }
    }

    private var birthDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.birthDate ?? Self.suggestedBirthDate },
            set: { viewModel.birthDate = $0 }
        )
    }
}
