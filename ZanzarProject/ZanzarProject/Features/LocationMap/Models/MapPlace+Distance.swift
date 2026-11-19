import Foundation

extension MapPlace {
    /// "240 m" or "1,3 km": nobody needs the exact meter, so it is rounded to tens of meters up close and to
    /// hundreds of meters from afar. `nil` when the user's position was not known.
    var roundedDistanceText: String? {
        guard let meters = distanceMeters else { return nil }
        let step = meters < 1000 ? 10.0 : 100.0
        let rounded = (meters / step).rounded() * step
        return Measurement(value: rounded, unit: UnitLength.meters).formatted(
            .measurement(
                width: .abbreviated,
                usage: .road,
                numberFormatStyle: .number.precision(.fractionLength(0...1))
            )
        )
    }
}
