import SwiftUI
import TipKit

/// The "Ajustes" half of the profile: notifications, privacy and the account.
struct ProfileSettingsView: View {
    /// How many photos and suggested places the user sent, and how many people they blocked.
    /// Each is `nil` until its list has loaded.
    let photosCount: Int?
    let suggestionsCount: Int?
    let blockedCount: Int?
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void

    @State private var showsMailComposer = false

    private let myPhotosTip = ProfileMyPhotosTip()
    private let mySuggestionsTip = ProfileMySuggestionsTip()
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ProximityAlertSettingsSection()
            submissionsSection
            privacySection
            accountSection
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showsMailComposer) {
            MailComposeView(
                recipient: SupportContact.email ?? SupportContact.defaultEmail,
                subject: L10n.string("profile.settings.support.mailSubject")
            )
            .ignoresSafeArea()
        }
    }

    private var submissionsSection: some View {
        ProfileSettingsSection(title: "profile.settings.submissions.title") {
            NavigationLink(value: Route.myPhotos) {
                ProfileSettingsRow(title: Text("profile.settings.photos.title")) {
                    countAndChevron(photosCount)
                }
            }
            .buttonStyle(.plain)
            .popoverTip(myPhotosTip, arrowEdge: .bottom)

            NavigationLink(value: Route.mySuggestions) {
                ProfileSettingsRow(title: Text("profile.settings.suggestions.title")) {
                    countAndChevron(suggestionsCount)
                }
            }
            .buttonStyle(.plain)
            .popoverTip(mySuggestionsTip, arrowEdge: .bottom)
        }
    }

    private var privacySection: some View {
        ProfileSettingsSection(title: "profile.settings.privacy.title") {
            NavigationLink(value: Route.blockedProfiles) {
                ProfileSettingsRow(title: Text("profile.settings.blocked.title")) {
                    countAndChevron(blockedCount)
                }
            }
            .buttonStyle(.plain)

            NavigationLink(value: Route.photoPrivacy) {
                ProfileSettingsRow(title: Text("profile.settings.terms.title")) {
                    chevron
                }
            }
            .buttonStyle(.plain)

            supportRow
        }
    }

    /// Opens the mail sheet of the system. Without a Mail account on the device it hands the address to
    /// whatever app handles `mailto:`.
    private var supportRow: some View {
        Button(action: contactSupport) {
            ProfileSettingsRow(
                title: Text("profile.settings.support.title"),
                subtitle: Text(verbatim: SupportContact.email ?? SupportContact.defaultEmail)
            ) {
                icon("envelope")
            }
        }
        .buttonStyle(.plain)
    }

    private func contactSupport() {
        if MailComposeView.canSend {
            showsMailComposer = true
        } else if let url = SupportContact.mailURL {
            openURL(url)
        }
    }

    private var accountSection: some View {
        ProfileSettingsSection(title: "profile.settings.account.title") {
            Button(action: onSignOut) {
                ProfileSettingsRow(
                    title: Text("profile.settings.signOut.title"),
                    subtitle: Text("profile.settings.signOut.subtitle")
                ) {
                    icon("rectangle.portrait.and.arrow.forward", color: Color.brandNeutral950)
                }
            }
            .buttonStyle(.plain)

            Button(action: onDeleteAccount) {
                ProfileSettingsRow(
                    title: Text("profile.settings.deleteAccount.title"),
                    subtitle: Text("profile.settings.deleteAccount.subtitle"),
                    isDestructive: true
                ) {
                    icon("trash", color: Color.brandErrorRed)
                }
            }
            .buttonStyle(.plain)
        }
    }

    /// "(10) ›": how many there are, once known, and the chevron of a row that opens a list.
    private func countAndChevron(_ count: Int?) -> some View {
        HStack(spacing: 4) {
            if let count {
                Text(verbatim: "(\(count))")
                    .typography(.caption1)
                    .foregroundStyle(Color.brandNeutral600)
            }
            chevron
        }
    }

    /// A trailing icon in a fixed-width slot, so icons of different widths line up on the same trailing edge.
    private func icon(_ systemName: String, color: Color = Color.brandNeutral950) -> some View {
        Image(systemName: systemName)
            .font(.body)
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .accessibilityHidden(true)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.callout.weight(.semibold))
            .foregroundStyle(Color.brandNeutral950)
            .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            ProfileSettingsView(photosCount: 10, suggestionsCount: 21, blockedCount: 5, onSignOut: {}, onDeleteAccount: {})
                .padding()
        }
        .background(Color.profileBackground)
    }
    .environment(AppCoordinator())
}
