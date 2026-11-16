import SwiftUI

/// The "Ajustes" half of the profile: notifications, privacy and the account.
struct ProfileSettingsView: View {
    /// `nil` until the list of blocked people has loaded.
    let blockedCount: Int?
    let onSignOut: () -> Void
    let onDeleteAccount: () -> Void

    @State private var showsMailComposer = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ProximityAlertSettingsSection()
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

    private var privacySection: some View {
        ProfileSettingsSection(title: "profile.settings.privacy.title") {
            NavigationLink(value: Route.blockedProfiles) {
                ProfileSettingsRow(
                    title: Text("profile.settings.blocked.title"),
                    subtitle: blockedSubtitle
                ) {
                    chevron
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

    private var blockedSubtitle: Text {
        if let blockedCount {
            Text("profile.settings.blocked.subtitle \(blockedCount)")
        } else {
            Text("profile.settings.blocked.subtitleUnknown")
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
            ProfileSettingsView(blockedCount: 2, onSignOut: {}, onDeleteAccount: {})
                .padding()
        }
        .background(Color.profileBackground)
    }
    .environment(AppCoordinator())
}
