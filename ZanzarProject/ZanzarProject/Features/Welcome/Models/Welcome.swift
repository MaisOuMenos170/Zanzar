import Foundation

// TODO: this is the domain model the ViewModel/View work with — distinct from
// the wire-format Request/Response structs in API/WelcomeService.swift.
// Map WelcomeResponse -> Welcome inside the ViewModel or Service.
struct Welcome: Identifiable, Hashable {
    let id: UUID
}
