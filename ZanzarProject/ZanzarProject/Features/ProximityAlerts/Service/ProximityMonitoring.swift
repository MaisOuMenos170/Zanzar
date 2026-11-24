import Foundation

/// Watches circles around places and reports when the user walks into one. The real one wraps `CLMonitor`.
protocol ProximityMonitoring: AnyObject {
    /// Region monitoring only wakes a closed app with "Always" location.
    var isAuthorized: Bool { get }
    /// Ids of the places the user has just come within range of. Must be consumed from launch on, because that
    /// is how a relaunched app finds out why it was woken.
    var entries: AsyncStream<String> { get }

    /// Brings the underlying monitor back to life. Call it at every launch, including the background relaunch
    /// iOS does for a region event, otherwise that event is never delivered.
    func resume() async

    /// Makes `places` the monitored set: adds new ones, drops the others, leaves the rest untouched.
    func monitor(_ places: [ProximityPlaceSnapshot], radius: Double) async
    func stopMonitoring() async
}
