import Foundation

// TODO: this is the domain model the ViewModel/View work with — distinct from
// the wire-format Request/Response structs in API/LoginService.swift.
// Map LoginResponse -> Login inside the ViewModel or Service.
struct Login: Identifiable, Hashable {
    let id: UUID
}
