import Foundation

/// One animated value on a loop (an angle, an offset, an opacity): keyframes in seconds, read at any time.
/// The welcome illustration reads every track from the same clock, so its pieces never drift apart.
struct WelcomeTrack {
    struct Key {
        let time: Double
        let value: Double
        let ease: Ease

        init(_ time: Double, _ value: Double, _ ease: Ease = .linear) {
            self.time = time
            self.value = value
            self.ease = ease
        }
    }

    enum Ease {
        case linear
        case easeIn
        case easeOut
        case easeInOut
        case step
        case bezier(Double, Double, Double, Double)

        func progress(_ fraction: Double) -> Double {
            switch self {
            case .linear: fraction
            case .easeIn: Self.solve(0.42, 0, 1, 1, at: fraction)
            case .easeOut: Self.solve(0, 0, 0.58, 1, at: fraction)
            case .easeInOut: Self.solve(0.42, 0, 0.58, 1, at: fraction)
            case .step: 0
            case .bezier(let startX, let startY, let endX, let endY):
                Self.solve(startX, startY, endX, endY, at: fraction)
            }
        }

        /// A CSS `cubic-bezier` with control points (startX, startY) and (endX, endY): finds the curve parameter
        /// whose x matches `fraction`, then reads y.
        private static func solve(
            _ startX: Double, _ startY: Double, _ endX: Double, _ endY: Double, at fraction: Double
        ) -> Double {
            func coordinate(_ first: Double, _ second: Double, _ along: Double) -> Double {
                let rest = 1 - along
                return 3 * first * along * rest * rest + 3 * second * along * along * rest + along * along * along
            }
            var low = 0.0
            var high = 1.0
            for _ in 0..<24 {
                let middle = (low + high) / 2
                if coordinate(startX, endX, middle) < fraction { low = middle } else { high = middle }
            }
            return coordinate(startY, endY, (low + high) / 2)
        }
    }

    let period: Double
    let keys: [Key]

    init(period: Double, _ keys: [Key]) {
        precondition(!keys.isEmpty, "A track needs at least one key")
        self.period = period
        self.keys = keys
    }

    func value(at time: TimeInterval) -> Double {
        let wrapped = time.truncatingRemainder(dividingBy: period)
        let local = wrapped < 0 ? wrapped + period : wrapped
        guard let next = keys.firstIndex(where: { $0.time > local }) else { return keys[keys.count - 1].value }
        guard next > 0 else { return keys[0].value }
        let from = keys[next - 1]
        let target = keys[next]
        let fraction = (local - from.time) / (target.time - from.time)
        return from.value + (target.value - from.value) * from.ease.progress(fraction)
    }
}
