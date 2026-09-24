import SwiftUI

struct BackendProbeResultRow: View {
    let titleKey: LocalizedStringKey
    let value: String

    var body: some View {
        LabeledContent(titleKey, value: value)
            .font(.body)
    }
}
