import Observation
import SwiftUI

/// Owns the toasts of the app. Any screen raises one with `show`, so a toast can outlive the screen that raised it.
///
/// Toasts pile up: the newest is in front and the older ones wait behind it. Each one has its own countdown that
/// starts when it is raised, so a message that is no longer news is gone by the time the ones in front of it leave.
/// A message already in the pile is not added again; it comes to the front and its countdown starts over.
/// `ToastOverlay` draws the pile.
@MainActor
@Observable
final class ToastManager {
    static let defaultDuration = Duration.seconds(4)
    /// How many toasts of the pile can be seen at once.
    static let maxVisible = 3
    /// How many toasts the pile keeps; a newer one pushes the oldest out.
    static let maxStored = 5

    /// The pile, oldest first. The last one is in front.
    private(set) var toasts: [ToastItem] = []

    /// The toast in front.
    var current: ToastItem? {
        toasts.last
    }

    /// The toasts to draw, oldest first, so the last one is in front. They all sit on the edge of the one in front;
    /// a toast that asked for the other edge waits until the front one leaves.
    var visibleToasts: [ToastItem] {
        guard let front = toasts.last else { return [] }
        return Array(toasts.filter { $0.position == front.position }.suffix(Self.maxVisible))
    }

    /// Waits for a toast's duration. A parameter so tests do not have to wait for real time.
    private let sleep: @Sendable (Duration) async throws -> Void
    @ObservationIgnored private var timers: [ToastItem.ID: Task<Void, Never>] = [:]

    init(sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.sleep = sleep
    }

    /// Puts the toast in front of the pile.
    func show(
        _ message: String,
        style: ToastStyle,
        position: ToastPosition = .top,
        duration: Duration = ToastManager.defaultDuration
    ) {
        if let index = toasts.firstIndex(where: { $0.message == message && $0.style == style }) {
            let repeated = toasts.remove(at: index)
            toasts.append(repeated)
            startTimer(for: repeated)
            return
        }

        let toast = ToastItem(message: message, style: style, position: position, duration: duration)
        toasts.append(toast)
        if toasts.count > Self.maxStored {
            dismiss(toasts[0].id)
        }
        // The overlay appears without moving focus, so VoiceOver has to be told about it.
        AccessibilityNotification.Announcement(message).post()
        startTimer(for: toast)
    }

    /// Takes a toast out of the pile, whether it is in front or behind.
    func dismiss(_ id: ToastItem.ID) {
        timers[id]?.cancel()
        timers[id] = nil
        toasts.removeAll { $0.id == id }
    }

    func dismissCurrent() {
        guard let id = current?.id else { return }
        dismiss(id)
    }

    /// Empties the pile.
    func removeAll() {
        for timer in timers.values {
            timer.cancel()
        }
        timers.removeAll()
        toasts.removeAll()
    }

    /// Holds every countdown while the user is dragging the toast.
    func pauseTimers() {
        for timer in timers.values {
            timer.cancel()
        }
        timers.removeAll()
    }

    /// Starts the countdowns again, from the full duration, once the user lets go.
    func resumeTimers() {
        for toast in toasts where timers[toast.id] == nil {
            startTimer(for: toast)
        }
    }

    private func startTimer(for toast: ToastItem) {
        timers[toast.id]?.cancel()
        let sleep = sleep
        // The waiting needs nothing from the main actor; only taking the toast away does.
        timers[toast.id] = Task { @concurrent [weak self] in
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
