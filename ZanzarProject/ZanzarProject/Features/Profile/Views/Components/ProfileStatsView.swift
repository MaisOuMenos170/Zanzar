import SwiftUI

struct ProfileStatsView: View {
    let summary: ProfileSummary

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 16) {
                checkIns
                itineraries
                seals
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack(spacing: 28) {
                checkIns
                Divider()
                itineraries
                Divider()
                seals
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
        }
    }

    private var checkIns: some View {
        ProfileStatItem(value: summary.checkInCount, label: "profile.stats.checkInsLabel")
    }

    private var itineraries: some View {
        ProfileStatItem(value: summary.itineraryCount, label: "profile.stats.itinerariesLabel")
    }

    private var seals: some View {
        ProfileStatItem(value: summary.sealCount, label: "profile.stats.sealsLabel")
    }
}

private struct ProfileStatItem: View {
    let value: Int
    let label: LocalizedStringKey

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Text(value, format: .number)
                // Check-ins, itineraries, and seals share this transition on purpose.
                .contentTransition(reduceMotion ? .identity : .numericText(value: Double(value)))
                .animation(reduceMotion ? nil : .default, value: value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
        }
        .frame(minWidth: 56)
        .accessibilityElement(children: .combine)
    }
}
