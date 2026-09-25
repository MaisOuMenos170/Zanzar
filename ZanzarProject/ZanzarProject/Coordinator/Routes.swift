import Foundation

enum Route: Hashable {
    case signUp
    case login
}

enum Sheet: Identifiable, Hashable {
    // TODO: add one case per presented sheet

    var id: Self {
        switch self {}
    }
}

enum FullScreenCover: Identifiable, Hashable {
    // TODO: add one case per presented full-screen cover

    var id: Self {
        switch self {}
    }
}
