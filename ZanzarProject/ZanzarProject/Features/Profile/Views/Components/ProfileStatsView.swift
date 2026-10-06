import SwiftUI

struct ProfileStatsView: View {
    let summary: ProfileSummary

    var body: some View {
        HStack(spacing: 28) {
            ProfileStatItem(value: summary.checkInCount, label: "profile.stats.checkInsLabel")
            Divider()
            ProfileStatItem(value: summary.itineraryCount, label: "profile.stats.itinerariesLabel")
            Divider()
            ProfileStatItem(value: summary.sealCount, label: "profile.stats.sealsLabel")
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileStatItem: View {
    let value: Int
    let label: LocalizedStringKey

    var body: some View {
        VStack(spacing: 0) {
            Text(value, format: .number)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
        }
        .frame(minWidth: 56)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ProfileStatsView(summary: .sample)
        .padding()
}
