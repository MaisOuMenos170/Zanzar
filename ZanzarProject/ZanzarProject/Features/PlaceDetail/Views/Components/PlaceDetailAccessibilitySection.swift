import SwiftUI

/// The accessibility resources a source confirms for the place, with the source and when it was checked.
/// Shown only for a place that has them: no section means "not checked yet", not "not accessible".
struct PlaceDetailAccessibilitySection: View {
    let accessibility: PlaceAccessibility

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("placeDetail.accessibility.title")
                    .typography(.subtitle1)
                    .bold()
            } icon: {
                Image(systemName: "accessibility")
                    .accessibilityHidden(true)
            }
            .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(accessibility.features, id: \.self) { feature in
                    Label {
                        Text(LocalizedStringKey(feature.titleKey))
                            .typography(.body2)
                    } icon: {
                        Image(systemName: feature.symbolName)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                    }
                }
            }

            Text("placeDetail.accessibility.disclaimer")
                .typography(.caption1)
                .foregroundStyle(Color.brandNeutral600)
                .fixedSize(horizontal: false, vertical: true)

            Link(destination: accessibility.sourceURL) {
                Text("placeDetail.accessibility.source \(accessibility.sourceLabel) \(accessibility.checkedAt.formatted(date: .abbreviated, time: .omitted))")
                    .typography(.caption1)
                    .multilineTextAlignment(.leading)
            }
            .tint(Color.brandPurple500)
        }
        .foregroundStyle(Color.brandNeutral950)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
