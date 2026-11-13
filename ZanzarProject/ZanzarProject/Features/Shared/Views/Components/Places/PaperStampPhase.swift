import SwiftUI

/// Where a stamp is in its one-shot press onto the paper.
enum PaperStampPhase: Equatable, Sendable {
    case lifted
    case contact
    case settled

    /// Drops the mark, then lets the paper spring back a hair. With Reduce Motion, it just settles.
    @MainActor
    static func play(
        size: Motion.StampSize,
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

        withAnimation(Motion.carimbo(duration: size.duration)) {
            update(.contact)
        } completion: {
            onContact()
            withAnimation(Motion.carimbo(duration: size.duration * 0.28)) {
                update(.settled)
            } completion: {
                onSettled()
            }
        }
    }
}
