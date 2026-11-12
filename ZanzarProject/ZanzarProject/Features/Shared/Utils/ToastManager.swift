import Observation
import SwiftUI

/// Owns the toasts of the app. Any screen raises one with `show`, so a toast can outlive the screen that raised it.
///
/// One toast is on screen at a time and the others wait in a queue, oldest first. Each toast leaves by itself after
/// its duration, or sooner when it is dismissed. `ToastOverlay` draws the one on screen.
@MainActor
@Observable
final class ToastManager {
    static let defaultDuration = Duration.seconds(4)

    /// The toast on screen.
    private(set) var current: ToastItem?
    /// The toasts waiting for their turn, oldest first.
    private(set) var queue: [ToastItem] = []

    /// Waits for a toast's duration. A parameter so tests do not have to wait for real time.
    private let sleep: @Sendable (Duration) async throws -> Void
    @ObservationIgnored private var timer: Task<Void, Never>?

    init(sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.sleep = sleep
    }

    /// Shows the toast now, or after the ones already waiting.
    func show(
        _ message: String,
        style: ToastStyle,
        position: ToastPosition = .top,
        duration: Duration = ToastManager.defaultDuration
    ) {
        queue.append(ToastItem(message: message, style: style, position: position, duration: duration))
        presentNextIfIdle()
    }

    /// Takes a toast away, whether it is on screen or still waiting.
    func dismiss(_ id: ToastItem.ID) {
        if current?.id == id {
            timer?.cancel()
            timer = nil
            current = nil
            presentNextIfIdle()
        } else {
            queue.removeAll { $0.id == id }
        }
    }

    func dismissCurrent() {
        guard let id = current?.id else { return }
        dismiss(id)
    }

    /// Drops the toast on screen and every one waiting.
    func removeAll() {
        queue.removeAll()
        dismissCurrent()
    }

    /// Holds the countdown while the user is dragging the toast.
    func pauseTimer() {
        timer?.cancel()
        timer = nil
    }

    /// Starts the countdown again, from the full duration, once the user lets go.
    func resumeTimer() {
        guard timer == nil, current != nil else { return }
        startTimer()
    }

    private func presentNextIfIdle() {
        guard current == nil, !queue.isEmpty else { return }
        let next = queue.removeFirst()
        current = next
        // The overlay appears without moving focus, so VoiceOver has to be told about it.
        AccessibilityNotification.Announcement(next.message).post()
        startTimer()
    }

    private func startTimer() {
        guard let toast = current else { return }
        timer?.cancel()
        let sleep = sleep
        // The waiting needs nothing from the main actor; only taking the toast away does.
        timer = Task { @concurrent [weak self] in
            do {
                try await sleep(toast.duration)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.dismiss(toast.id) }
        }
    }
}
