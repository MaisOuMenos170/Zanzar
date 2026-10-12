import Foundation

nonisolated enum PlaceDisplayNameResolver {
    static func displayName(nickname: String?, name: String) -> String {
        guard let nickname, !nickname.isEmpty else { return name }
        return nickname
    }
}
