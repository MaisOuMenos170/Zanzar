import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// The share extension's entry point. It reads what was shared, picks up the session the app left in the shared
/// keychain group and hosts the SwiftUI sheet. Nothing is sent until the person confirms it.
final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BrandNeutral50")
        Task { await showSheet() }
    }

    private func showSheet() async {
        let shared = await sharedContent()
        let tokens = KeychainStore().readTokens()
        AuthTokenStore.shared.setTokens(tokens)

        let model = PlaceShareViewModel(
            texts: shared.texts,
            urls: shared.urls,
            // The share sheet never asks for the user's location: the place comes from what was shared.
            service: PlaceSuggestionService(userPosition: { throw CancellationError() }),
            isSignedIn: { tokens != nil }
        )
        let host = UIHostingController(rootView: ShareRootView(model: model) { [weak self] in self?.finish() })
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        host.didMove(toParent: self)
    }

    private func finish() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    /// Text and links from every item: Google Maps hands over "name, address, link" as text, Apple Maps a URL.
    private func sharedContent() async -> (texts: [String], urls: [URL]) {
        var texts: [String] = []
        var urls: [URL] = []
        for item in extensionContext?.inputItems as? [NSExtensionItem] ?? [] {
            if let text = item.attributedContentText?.string, !text.isEmpty { texts.append(text) }
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                   let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                    urls.append(url)
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
                          let text = try? await provider
                              .loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                    texts.append(text)
                }
            }
        }
        return (texts, urls)
    }
}
