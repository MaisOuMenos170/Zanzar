import SwiftUI

/// The three big numbers of the passport: check-ins, completed roteiros and seals.
struct ProfileStatsView: View {
    let summary: ProfileSummary

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        AdaptiveStack(horizontalAlignment: .leading, verticalAlignment: .top, spacing: 8) {
            checkInsTile
            VStack(spacing: 8) {
                itinerariesTile
                sealsTile
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var checkInsTile: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("profile.stats.checkInsLabel")
                .typography(.overline)
                .textCase(.uppercase)
                .foregroundStyle(Color.brandOrange600)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.brandNeutral50, in: .capsule)

            Spacer(minLength: 0)

            number(summary.checkInCount, style: .display1)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 176, alignment: .topLeading)
        .background(alignment: .topLeading) {
            LinearGradient(
                angle: 145,
                stops: [
                    .init(color: .brandOrange100, location: 0.236),
                    .init(color: .brandOrange300, location: 0.961)
                ]
            )
            .overlay(alignment: .topLeading) {
                Image("ProfileTileCheckIns")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 141)
                    .offset(x: 61, y: 14)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var itinerariesTile: some View {
        HStack(spacing: 10) {
            number(summary.itineraryCount, style: .display2)
            VStack(alignment: .leading, spacing: 0) {
                Text("profile.stats.itinerariesTitle")
                    .typography(.subtitle4)
                Text("profile.stats.itinerariesSubtitle")
                    .typography(.caption1)
            }
            .foregroundStyle(Color.brandNeutral900)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(alignment: .topLeading) {
            LinearGradient(
                angle: 137,
                stops: [
                    .init(color: .brandYellow300, location: 0.318),
                    .init(color: .brandYellow500, location: 1)
                ]
            )
            .overlay(alignment: .topLeading) {
                Image("ProfileTileItineraries")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 162)
                    .scaleEffect(x: -1)
                    .offset(x: 149.5, y: -18)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private var sealsTile: some View {
        HStack(spacing: 10) {
            number(summary.sealCount, style: .display2)
            Text("profile.stats.sealsTitle")
                .typography(.subtitle4)
                .foregroundStyle(Color.brandNeutral900)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(alignment: .topLeading) {
            LinearGradient(
                angle: 137.5,
                stops: [
                    .init(color: .brandPurple100, location: 0.318),
                    .init(color: .brandPurple400, location: 1)
                ]
            )
            .overlay(alignment: .topLeading) {
                // Placeholder until the seal art for this tile is delivered.
                Image(systemName: "seal.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 122.7)
                    .foregroundStyle(Color.brandNeutral50.opacity(0.45))
                    .offset(x: 92.5, y: 12)
                    .accessibilityHidden(true)
            }
        }
        .clipShape(.rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func number(_ value: Int, style: AppTypography) -> some View {
        Text(value, format: .number)
            .typography(style)
            .foregroundStyle(Color.brandNeutral950)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .contentTransition(reduceMotion ? .identity : .numericText(value: Double(value)))
            .animation(reduceMotion ? nil : .default, value: value)
    }
}

private extension LinearGradient {
    /// A gradient along a CSS-style angle (0° points up, 90° points right).
    init(angle degrees: Double, stops: [Gradient.Stop]) {
        let radians = Angle.degrees(degrees).radians
        let dx = sin(radians) / 2
        let dy = -cos(radians) / 2
        self.init(
            stops: stops,
            startPoint: UnitPoint(x: 0.5 - dx, y: 0.5 - dy),
            endPoint: UnitPoint(x: 0.5 + dx, y: 0.5 + dy)
        )
    }
}

#if DEBUG
#Preview {
    ProfileStatsView(summary: Profile.preview.summary)
        .padding()
        .background(Color.profileBackground)
}
#endif
