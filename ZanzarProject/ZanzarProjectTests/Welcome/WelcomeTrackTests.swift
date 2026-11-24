import Testing
import UIKit
@testable import ZanzarProject

@MainActor
@Suite("WelcomeTrack")
struct WelcomeTrackTests {
    private let ramp = WelcomeTrack(period: 10, [.init(0, 0), .init(10, 100)])

    @Test("reads the keys and interpolates between them")
    func interpolates() {
        #expect(ramp.value(at: 0) == 0)
        #expect(abs(ramp.value(at: 2.5) - 25) < 0.001)
    }

    @Test("starts over after one period, also for negative times")
    func wraps() {
        #expect(abs(ramp.value(at: 12.5) - 25) < 0.001)
        #expect(abs(ramp.value(at: -7.5) - 25) < 0.001)
    }

    @Test("holds the last value after the last key")
    func holdsLast() {
        let track = WelcomeTrack(period: 10, [.init(0, 5), .init(4, 9)])
        #expect(track.value(at: 8) == 9)
    }

    @Test("a step key holds its value until the next key")
    func step() {
        let track = WelcomeTrack(period: 10, [.init(0, -36, .step), .init(5, 36)])
        #expect(track.value(at: 4.99) == -36)
        #expect(track.value(at: 5.01) == 36)
    }

    @Test("ease in-out is symmetric and slower at both ends")
    func easeInOut() {
        let track = WelcomeTrack(period: 10, [.init(0, 0, .easeInOut), .init(10, 100)])
        #expect(abs(track.value(at: 5) - 50) < 0.5)
        #expect(track.value(at: 1) < 10)
        #expect(track.value(at: 9) > 90)
    }

    @Test("a bezier with overshoot goes past the end value, then settles")
    func overshoot() {
        let track = WelcomeTrack(period: 10, [.init(0, 0, .bezier(0.45, 1.45, 0.8, 1)), .init(10, 100)])
        #expect(track.value(at: 6) > 100)
        #expect(abs(track.value(at: 9.999) - 100) < 1)
    }

    @Test("the walk repeats every 1.1 s, eight times per loop")
    func walkRepeats() {
        for time in stride(from: 0.0, to: 1.1, by: 0.11) {
            #expect(abs(WelcomeTracks.bob.value(at: time) - WelcomeTracks.bob.value(at: time + 1.1 * 3)) < 0.0001)
            let leg = WelcomeTracks.legFrontRotation
            #expect(abs(leg.value(at: time) - leg.value(at: time + 1.1 * 7)) < 0.0001)
        }
    }

    @Test("the globe turns once per loop")
    func globeTurnsOnce() {
        let start = WelcomeTracks.globeRotation.value(at: 0)
        let end = WelcomeTracks.globeRotation.value(at: WelcomeTracks.loop - 0.0001)
        #expect(abs(abs(end - start) - 2 * .pi) < 0.001)
    }

    @Test("the planet rises and the character falls onto it, then both stay put")
    func arrival() {
        #expect(WelcomeTracks.planetY.value(at: 0) == 460)
        #expect(abs(WelcomeTracks.planetY.value(at: 1.1)) < 0.001)
        #expect(WelcomeTracks.fallY.value(at: 0) == -560)
        #expect(abs(WelcomeTracks.fallY.value(at: 1.2)) < 0.001)
        #expect(WelcomeTracks.fallY.value(at: 1.45) < -20)
        #expect(abs(WelcomeTracks.fallY.value(at: 3)) < 0.001)
    }

    @Test("the character squashes on landing and ends at its normal size")
    func squash() {
        #expect(WelcomeTracks.squashY.value(at: 1.2) < 0.9)
        #expect(WelcomeTracks.squashX.value(at: 1.2) > 1.1)
        #expect(WelcomeTracks.squashX.value(at: 3) == 1)
        #expect(WelcomeTracks.squashY.value(at: 3) == 1)
    }

    @Test("the logo, the fade and the buttons' moment come in order")
    func order() {
        #expect(WelcomeTracks.logoOpacity.value(at: 1.9) == 0)
        #expect(WelcomeTracks.logoOpacity.value(at: 2.6) == 1)
        #expect(WelcomeTracks.fadeOpacity.value(at: 3.8) == 0)
        #expect(WelcomeTracks.fadeOpacity.value(at: WelcomeTracks.stillTime) == 1)
    }

    @Test("every layer of the artwork is in the asset catalog")
    func imagesExist() {
        for layer in WelcomeArt.all {
            #expect(UIImage(named: layer.image) != nil, "Missing image \(layer.image)")
        }
    }
}
