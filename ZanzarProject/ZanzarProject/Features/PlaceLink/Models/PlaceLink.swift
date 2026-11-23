import Foundation

/// The link the app shares for a place, and the reading of one that opens the app.
///
/// Two forms open a place: the shared `https://<api host>/p/<placeId>` (a Universal Link, so iOS opens the app
/// straight from it; the backend serves the page people without the app see) and `lero://place/<placeId>`, the
/// scheme that page's button uses.
nonisolated enum PlaceLink {
    static let scheme = "lero"
    private static let sharedPath = "p"
    private static let schemeHost = "place"
    /// The backend accepts ids up to this long.
    private static let maximumIDLength = 512

    /// The link to share for `placeID`.
    static func url(for placeID: String, baseURL: URL = APIConfiguration.baseURL) -> URL {
        baseURL.appending(path: sharedPath).appending(path: placeID)
    }

    /// The place a link points to, or `nil` when it is not a place link of this app.
    static func placeID(from url: URL, baseURL: URL = APIConfiguration.baseURL) -> String? {
        let components = url.pathComponents.filter { $0 != "/" }
        let id: String?
        switch url.scheme?.lowercased() {
        case scheme:
            id = url.host()?.lowercased() == schemeHost && components.count == 1 ? components[0] : nil
        case "https", "http":
            let sameHost = url.host()?.lowercased() == baseURL.host()?.lowercased()
            id = sameHost && components.count == 2 && components[0] == sharedPath ? components[1] : nil
        default:
            id = nil
        }
        guard let id, !id.isEmpty, id.count <= maximumIDLength else { return nil }
        return id
    }
}
