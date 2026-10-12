import SwiftUI

/// Where a stamp is in its one-shot press onto the paper.
enum PaperStampPhase: Equatable, Sendable {
    case lifted
    case contact
    case settled

    /// Drops the mark, then lets the paper spring back a hair. With Reduce Motion, it just settles.
    @MainActor
    static func play(
        duration: TimeInterval,
        reduceMotion: Bool,
        update: @escaping (PaperStampPhase) -> Void,
        onContact: @escaping () -> Void = {},
        onSettled: @escaping () -> Void = {}
    ) {
        if reduceMotion {
            update(.settled)
            onSettled()
            return
        }

        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            update(.lifted)
        }

        withAnimation(.easeOut(duration: duration)) {
            update(.contact)
        } completion: {
            onContact()
            withAnimation(.easeOut(duration: duration * 0.28)) {
                update(.settled)
            } completion: {
                onSettled()
            }
        }
    }
}
