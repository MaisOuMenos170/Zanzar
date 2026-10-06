import Foundation
import Observation

@Observable
final class ProfileViewModel {
    let summary: ProfileSummary
    let recentCheckIns: [ProfileCheckIn]

    var showsSignOutConfirmation = false
    var signOutFailed = false

    init(
        summary: ProfileSummary = .sample,
        recentCheckIns: [ProfileCheckIn] = ProfileCheckIn.samples
    ) {
        self.summary = summary
        self.recentCheckIns = recentCheckIns
    }

    func signOut(using authSession: AuthSession) {
        do {
            try authSession.signOut()
        } catch {
            signOutFailed = true
        }
    }
}

extension ProfileSummary {
    static let sample = ProfileSummary(name: "Ana Silva", checkInCount: 21, itineraryCount: 3, sealCount: 4)
}

extension ProfileCheckIn {
    static let samples: [ProfileCheckIn] = {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 13)) ?? .now
        return (0..<4).map { index in
            ProfileCheckIn(
                id: UUID(),
                placeName: "Parque Tanguá",
                date: date,
                impressionImageName: "ProfileCheckInEmoji",
                reactionImageName: index == 0 ? "ProfileReactionMascot" : nil
            )
        }
    }()
}
