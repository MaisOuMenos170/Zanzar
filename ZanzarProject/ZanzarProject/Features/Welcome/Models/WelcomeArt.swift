import SwiftUI

/// Where each layer of the welcome illustration sits, measured on the 393 x 852 Figma frame.
/// Generated from "Tela inicial — animação" (Figma node 2702:15779); the pieces are PNG exports at 3x.
enum WelcomeArt {
    static let canvas = CGSize(width: 393, height: 852)

    /// The box that holds the character, with room for the legs to swing. Its layers are measured inside it.
    static let stage = CGRect(x: 62.91, y: 207, width: 250, height: 310)
    /// The character squashes against the ground, so it scales from its feet (centre of the 144 x 480 frame).
    static let squashAnchor = UnitPoint(x: 0.4705, y: 0.5366)
    /// The legs are cut at the hip, as in the design.
    static let hipClip = CGRect(x: 10, y: 168, width: 240, height: 140)

    static let logo = WelcomeLayer("WelcomeLogo", CGRect(x: 44, y: 43, width: 325, height: 251.56))
    static let globe = WelcomeLayer("WelcomeGlobe", CGRect(x: -23, y: 371.97, width: 440, height: 440))
    static let glow = WelcomeLayer("WelcomeGlow", CGRect(x: 42.14, y: 428.35, width: 227.93, height: 227.55))
    static let grid = WelcomeLayer("WelcomeGrid", CGRect(x: -23, y: 371.97, width: 440, height: 440))
    static let center = WelcomeLayer("WelcomeCenter", CGRect(x: 40.94, y: 426, width: 323.18, height: 331.94))
    static let shadow = WelcomeLayer("WelcomeShadow", CGRect(x: 143.93, y: 455.96, width: 108.55, height: 12.53))

    static let body1 = WelcomeLayer("WelcomeCharBody1", CGRect(x: 77.67, y: 10, width: 116.33, height: 134.67))
    static let eyeNear = WelcomeLayer("WelcomeCharEyeNear", CGRect(x: 153.67, y: 98.33, width: 19.67, height: 12))
    static let lidNear = WelcomeLayer("WelcomeCharLidNear", CGRect(x: 153.67, y: 97, width: 19.67, height: 5))
    static let armBack = WelcomeLayer("WelcomeCharArmBack", CGRect(x: 149.33, y: 153.33, width: 34.33, height: 34))
    static let shoeBack = WelcomeLayer("WelcomeCharShoeBack", CGRect(x: 85, y: 222, width: 38, height: 32.33))
    static let legBack = WelcomeLayer("WelcomeCharLegBack", CGRect(x: 94.67, y: 171, width: 49, height: 66.67))
    static let shoeFront = WelcomeLayer("WelcomeCharShoeFront", CGRect(x: 149.33, y: 225, width: 38.33, height: 31.33))
    static let legFront = WelcomeLayer("WelcomeCharLegFront", CGRect(x: 127.33, y: 168, width: 52, height: 73.67))
    static let body2 = WelcomeLayer("WelcomeCharBody2", CGRect(x: 130.67, y: 17.67, width: 53, height: 103.67))
    static let eyeFar = WelcomeLayer("WelcomeCharEyeFar", CGRect(x: 181.67, y: 97.67, width: 7.67, height: 11))
    static let lidFar = WelcomeLayer("WelcomeCharLidFar", CGRect(x: 182, y: 97, width: 6.33, height: 3.67))
    static let body3 = WelcomeLayer("WelcomeCharBody3", CGRect(x: 150.33, y: 107.33, width: 16.33, height: 9.33))
    // swiftlint:disable:next line_length
    static let eyeHighlightA = WelcomeLayer("WelcomeCharEyeHighlightA", CGRect(x: 183, y: 99.67, width: 6, height: 8.67))
    // swiftlint:disable:next line_length
    static let eyeHighlightB = WelcomeLayer("WelcomeCharEyeHighlightB", CGRect(x: 187.33, y: 97.33, width: 1, height: 3))
    static let body4 = WelcomeLayer("WelcomeCharBody4", CGRect(x: 121.33, y: 44.33, width: 39, height: 132))
    static let armFront = WelcomeLayer("WelcomeCharArmFront", CGRect(x: 100.67, y: 151.67, width: 37.67, height: 40.33))
    static let body5 = WelcomeLayer("WelcomeCharBody5", CGRect(x: 50, y: 16, width: 109.33, height: 160.33))
    static let eyeGlow = WelcomeLayer("WelcomeCharEyeGlow", CGRect(x: 181.67, y: 98, width: 6.67, height: 4.67))
    static let body6 = WelcomeLayer("WelcomeCharBody6", CGRect(x: 114.33, y: 37, width: 79.67, height: 77.33))
    static let hip = WelcomeLayer("WelcomeCharHip", CGRect(x: 126, y: 170, width: 29, height: 32))

    static let all: [WelcomeLayer] = [
        logo, globe, glow, grid, center, shadow,
        body1, eyeNear, lidNear, armBack, shoeBack, legBack,
        shoeFront, legFront, body2, eyeFar, lidFar, body3,
        eyeHighlightA, eyeHighlightB, body4, armFront, body5, eyeGlow,
        body6, hip
    ]

    enum Pivot {
        static let eyeNear = UnitPoint(x: 0.6520, y: 0.3419)
        static let lidNear = UnitPoint(x: 0.6538, y: 0.3206)
        static let armBack = UnitPoint(x: 0.6120, y: 0.5097)
        static let legBack = UnitPoint(x: 0.5440, y: 0.5871)
        static let shoeBack = UnitPoint(x: 0.4320, y: 0.7419)
        static let legFront = UnitPoint(x: 0.5760, y: 0.5677)
        static let shoeFront = UnitPoint(x: 0.6600, y: 0.7484)
        static let eyeFar = UnitPoint(x: 0.7483, y: 0.3327)
        static let lidFar = UnitPoint(x: 0.7430, y: 0.3193)
        static let eyeHighlightA = UnitPoint(x: 0.7445, y: 0.3350)
        static let eyeHighlightB = UnitPoint(x: 0.7515, y: 0.3186)
        static let armFront = UnitPoint(x: 0.5360, y: 0.5032)
    }
}
