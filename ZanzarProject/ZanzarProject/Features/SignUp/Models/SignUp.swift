import Foundation

// TODO: this is the domain model the ViewModel/View work with — distinct from
// the wire-format Request/Response structs in API/SignUpService.swift.
// Map SignUpResponse -> SignUp inside the ViewModel or Service.
struct SignUp: Identifiable, Hashable {
    let id: UUID
}
