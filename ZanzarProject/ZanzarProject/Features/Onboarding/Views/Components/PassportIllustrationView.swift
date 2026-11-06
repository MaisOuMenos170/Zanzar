import SwiftUI

/// The passport scene on its 393×640 design canvas: torn paper and ticket behind a tilted card, a dashed arrow
/// around it, and, depending on `stage`, the hand holding the stamp or the finished LERO stamp.
struct PassportIllustrationView: View {
    static let canvasSize = CGSize(width: 393, height: 640)

    let avatar: Avatar
    let name: String
    let stage: PassportStampStage
    /// Press phase of the stamp: the LERO mark drops in and the paper gives a little at the moment of contact.
    let phase: PaperStampPhase

    var body: some View {
        ZStack {
            ForEach(PassportArtPiece.tornPaper) { PassportArtImage(piece: $0) }
            PassportTicketView()
            PassportArtImage(piece: PassportArtPiece.arrows)

            Group {
                PassportCardView(avatar: avatar, name: name, stampCount: 0)

                if stage == .stamped {
                    PassportLeroStampView()
                        .paperStampPress(phase: phase, role: .mark, travel: 20)
                }
            }
            .paperStampPress(phase: phase, role: .sheet)

            if stage == .handOver {
                PassportArtImage(piece: PassportArtPiece.handMotion)
                PassportArtImage(piece: PassportArtPiece.hand)
                    .offset(y: phase == .lifted ? -24 : 0)
            }
        }
        .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
    }
}
