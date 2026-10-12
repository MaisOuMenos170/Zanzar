import Foundation

/// The installed navigation apps offered for one presentation of the picker sheet.
struct PlaceDetailNavigationAppOptions: Identifiable {
    let id = UUID()
    let apps: [PlaceDetailNavigationApp]
}
