import SwiftUI

/// The app's haptic vocabulary, named by intent. Haptics follow the system haptics setting,
/// not Reduce Motion.
enum Haptic {
    /// A stamp landing on the paper.
    case carimbo
    /// A small stamp landing, such as the check-in mark.
    case carimboLeve
    /// Picking one option among several.
    case selecao
    /// Something good was completed.
    case sucesso
    /// Something needs attention.
    case alerta
    /// A soft touch that confirms without drawing attention.
    case toqueSuave

    var feedback: SensoryFeedback {
        switch self {
        case .carimbo: .impact(flexibility: .rigid, intensity: 0.7)
        case .carimboLeve: .impact(flexibility: .rigid, intensity: 0.55)
        case .selecao: .selection
        case .sucesso: .success
        case .alerta: .warning
        case .toqueSuave: .impact(flexibility: .soft, intensity: 0.5)
        }
    }
}

extension View {
    /// Plays `haptic` whenever `trigger` changes.
    func haptic<T: Equatable>(_ haptic: Haptic, trigger: T) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger)
    }
}
