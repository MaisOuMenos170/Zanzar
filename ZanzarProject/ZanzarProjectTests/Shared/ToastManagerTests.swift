import Foundation
import Testing
@testable import ZanzarProject

@MainActor
@Suite("ToastManager")
struct ToastManagerTests {
    /// Toasts stay until they are dismissed by hand.
    private func manager() -> ToastManager {
        ToastManager(sleep: { _ in try await Task.sleep(for: .seconds(3600)) })
    }

    /// Toasts leave as soon as the timer gets to run.
    private func quickManager() -> ToastManager {
        ToastManager(sleep: { _ in })
    }

    private func wait(for condition: @MainActor () -> Bool) async {
        for _ in 0..<300 where !condition() {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("a toast shows right away when nothing else is on screen")
    func showsImmediately() {
        let toasts = manager()

        toasts.show("One", style: .positive)

        #expect(toasts.current?.message == "One")
        #expect(toasts.queue.isEmpty)
    }

    @Test("toasts raised meanwhile wait in the order they came")
    func queuesInOrder() {
        let toasts = manager()

        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)
        toasts.show("Three", style: .negative)

        #expect(toasts.current?.message == "One")
        #expect(toasts.queue.map(\.message) == ["Two", "Three"])
    }

    @Test("dismissing the toast on screen brings the next one")
    func dismissAdvances() throws {
        let toasts = manager()
        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)

        toasts.dismiss(try #require(toasts.current).id)

        #expect(toasts.current?.message == "Two")
        #expect(toasts.queue.isEmpty)

        toasts.dismissCurrent()

        #expect(toasts.current == nil)
    }

    @Test("a toast that is still waiting can be taken out of the queue")
    func dismissWaiting() throws {
        let toasts = manager()
        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)
        let waiting = try #require(toasts.queue.first)

        toasts.dismiss(waiting.id)

        #expect(toasts.current?.message == "One")
        #expect(toasts.queue.isEmpty)
    }

    @Test("a toast keeps its style, position and duration")
    func keepsItsSettings() {
        let toasts = manager()

        toasts.show("Down here", style: .negative, position: .bottom, duration: .seconds(9))

        #expect(toasts.current?.style == .negative)
        #expect(toasts.current?.position == .bottom)
        #expect(toasts.current?.duration == .seconds(9))
    }

    @Test("toasts sit at the top and last a few seconds unless told otherwise")
    func defaults() {
        let toasts = manager()

        toasts.show("Plain", style: .positive)

        #expect(toasts.current?.position == .top)
        #expect(toasts.current?.duration == ToastManager.defaultDuration)
    }

    @Test("removeAll drops the toast on screen and the ones waiting")
    func removeAll() {
        let toasts = manager()
        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)

        toasts.removeAll()

        #expect(toasts.current == nil)
        #expect(toasts.queue.isEmpty)
    }

    @Test("a toast leaves by itself and the next one follows")
    func leavesByItself() async {
        let toasts = quickManager()

        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)
        await wait { toasts.current == nil && toasts.queue.isEmpty }

        #expect(toasts.current == nil)
        #expect(toasts.queue.isEmpty)
    }

    @Test("the countdown holds while paused and runs again when resumed")
    func pauseAndResume() async {
        let toasts = ToastManager(sleep: { _ in try await Task.sleep(for: .milliseconds(50)) })
        toasts.show("One", style: .positive)

        toasts.pauseTimer()
        try? await Task.sleep(for: .milliseconds(200))
        #expect(toasts.current?.message == "One")

        toasts.resumeTimer()
        await wait { toasts.current == nil }
        #expect(toasts.current == nil)
    }
}
