import SwiftUI

/// What happens to a photo, in plain language. Shown before the first upload and again in "Photos and privacy".
/// The texts are marked for legal review in docs/fotos-de-usuario-termo.md.
struct PhotoTermsContent: View {
    private struct TermsSection: Identifiable {
        /// The key segment shared by `userPhotos.terms.<id>.title` and `.body`.
        let id: String
        let symbol: String

        var title: LocalizedStringKey { LocalizedStringKey("userPhotos.terms.\(id).title") }
        var body: LocalizedStringKey { LocalizedStringKey("userPhotos.terms.\(id).body") }
    }

    private let sections = [
        TermsSection(id: "review", symbol: "checkmark.shield"),
        TermsSection(id: "timing", symbol: "clock"),
        TermsSection(id: "notAllowed", symbol: "hand.raised"),
        TermsSection(id: "location", symbol: "location.slash"),
        TermsSection(id: "ai", symbol: "cpu"),
        TermsSection(id: "license", symbol: "doc.text"),
        TermsSection(id: "control", symbol: "trash"),
        TermsSection(id: "data", symbol: "lock")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(sections) { section in
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(section.title)
                            .font(.headline)
                        Text(section.body)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    Image(systemName: section.symbol)
                        .foregroundStyle(Color("TabBarSelected"))
                }
            }
        }
    }
}
