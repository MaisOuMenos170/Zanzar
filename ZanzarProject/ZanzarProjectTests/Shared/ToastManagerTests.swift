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

    /// Toasts leave as soon as their timer gets to run.
    private func quickManager() -> ToastManager {
        ToastManager(sleep: { _ in })
    }

    private func wait(for condition: @MainActor () -> Bool) async {
        for _ in 0..<300 where !condition() {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test("a toast shows right away")
    func showsImmediately() {
        let toasts = manager()

        toasts.show("One", style: .positive)

        #expect(toasts.current?.message == "One")
        #expect(toasts.toasts.count == 1)
    }

    @Test("toasts pile up with the newest in front")
    func newestInFront() {
        let toasts = manager()

        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)
        toasts.show("Three", style: .negative)

        #expect(toasts.toasts.map(\.message) == ["One", "Two", "Three"])
        #expect(toasts.current?.message == "Three")
    }

    @Test("dismissing the toast in front brings back the one behind it")
    func dismissFront() {
        let toasts = manager()
        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)

        toasts.dismissCurrent()

        #expect(toasts.current?.message == "One")

        toasts.dismissCurrent()

        #expect(toasts.current == nil)
    }

    @Test("a toast behind the front one can be taken out on its own")
    func dismissBehind() throws {
        let toasts = manager()
        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)
        let behind = try #require(toasts.toasts.first)

        toasts.dismiss(behind.id)

        #expect(toasts.toasts.map(\.message) == ["Two"])
    }

    @Test("a message already in the pile is not added again")
    func repeatedMessageIsNotAdded() throws {
        let toasts = manager()
        toasts.show("One", style: .negative)
        let original = try #require(toasts.current)

        toasts.show("One", style: .negative)

        #expect(toasts.toasts.count == 1)
        #expect(toasts.current?.id == original.id)
    }

    @Test("a repeated message that was behind comes to the front")
    func repeatedMessageComesToFront() throws {
        let toasts = manager()
        toasts.show("One", style: .negative)
        let original = try #require(toasts.current)
        toasts.show("Two", style: .negative)

        toasts.show("One", style: .negative)

        #expect(toasts.toasts.map(\.message) == ["Two", "One"])
        #expect(toasts.current?.id == original.id)
    }

    @Test("the same text with another style is a different toast")
    func sameTextOtherStyle() {
        let toasts = manager()

        toasts.show("Done", style: .positive)
        toasts.show("Done", style: .negative)

        #expect(toasts.toasts.count == 2)
    }

    @Test("a newer toast pushes the oldest out once the pile is full")
    func pileIsCapped() {
        let toasts = manager()

        for number in 1...(ToastManager.maxStored + 2) {
            toasts.show("Toast \(number)", style: .negative)
        }

        #expect(toasts.toasts.count == ToastManager.maxStored)
        #expect(toasts.toasts.first?.message == "Toast 3")
        #expect(toasts.current?.message == "Toast 7")
    }

    @Test("only the newest few are drawn")
    func visibleToasts() {
        let toasts = manager()

        for number in 1...5 {
            toasts.show("Toast \(number)", style: .negative)
        }

        #expect(toasts.visibleToasts.map(\.message) == ["Toast 3", "Toast 4", "Toast 5"])
    }

    @Test("a toast for the other edge is not drawn with the one in front")
    func visibleToastsShareAnEdge() {
        let toasts = manager()

        toasts.show("Below", style: .negative, position: .bottom)
        toasts.show("Above", style: .negative, position: .top)

        #expect(toasts.visibleToasts.map(\.message) == ["Above"])
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

    @Test("removeAll empties the pile")
    func removeAll() {
        let toasts = manager()
        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)

        toasts.removeAll()

        #expect(toasts.current == nil)
        #expect(toasts.toasts.isEmpty)
    }

    @Test("toasts leave by themselves")
    func leaveByThemselves() async {
        let toasts = quickManager()

        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)
        await wait { toasts.toasts.isEmpty }

        #expect(toasts.toasts.isEmpty)
    }

    @Test("each toast counts down on its own, even from behind")
    func independentCountdowns() async {
        let toasts = ToastManager(sleep: { try await Task.sleep(for: $0) })
        toasts.show("Short", style: .negative, duration: .milliseconds(30))
        toasts.show("Long", style: .positive, duration: .seconds(3600))

        await wait { toasts.toasts.count == 1 }

        #expect(toasts.toasts.map(\.message) == ["Long"])
    }

    @Test("the countdowns hold while paused and run again when resumed")
    func pauseAndResume() async {
        let toasts = ToastManager(sleep: { _ in try await Task.sleep(for: .milliseconds(50)) })
        toasts.show("One", style: .positive)
        toasts.show("Two", style: .negative)

        toasts.pauseTimers()
        try? await Task.sleep(for: .milliseconds(200))
        #expect(toasts.toasts.count == 2)

        toasts.resumeTimers()
        await wait { toasts.toasts.isEmpty }
        #expect(toasts.toasts.isEmpty)
    }
}
