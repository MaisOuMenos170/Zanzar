/// Generated from the motion of "Tela inicial — animação" (Figma node 2702:15779). Times are in seconds;
/// the app plays the loop on one clock, so every piece stays in step.
enum WelcomeTracks {
    static let loop = 8.8
    /// A pose to rest on when motion is reduced: the arrival is over and the buttons are in.
    static let stillTime = 4.4

    /// The arrival (first ~4.5 s of the loop, played once): logo, planet, landing, then the buttons.
    static let logoOpacity = WelcomeTrack(period: 8.8, [
            .init(0, 0), .init(1.95, 0, .easeOut), .init(2.5, 1), .init(8.8, 1)
    ])

    static let logoY = WelcomeTrack(period: 8.8, [
            .init(0, 24), .init(1.95, 24, .bezier(0.45, 1.45, 0.8, 1)), .init(2.5, 0), .init(8.8, 0)
    ])

    static let planetY = WelcomeTrack(period: 8.8, [
            .init(0, 460), .init(0.1, 460, .bezier(0.45, 1.45, 0.8, 1)), .init(1.1, 0), .init(8.8, 0)
    ])

    static let shadowBounce = WelcomeTrack(period: 8.8, [
            .init(0, 1), .init(1.1, 1, .easeOut), .init(1.2, 1.1, .easeOut), .init(1.45, 0.72, .easeIn),
            .init(1.7, 1.05, .easeOut), .init(1.82, 0.9, .easeIn), .init(1.94, 1), .init(8.8, 1)
    ])

    static let shadowOpacity = WelcomeTrack(period: 8.8, [
            .init(0, 0), .init(1.1, 0, .easeOut), .init(1.25, 1), .init(8.8, 1)
    ])

    static let fallY = WelcomeTrack(period: 8.8, [
            .init(0, -560), .init(0.5, -560, .easeIn), .init(1.2, 0, .easeOut), .init(1.45, -28, .easeIn),
            .init(1.7, 0, .easeOut), .init(1.82, -8, .easeIn), .init(1.94, 0), .init(8.8, 0)
    ])

    static let squashX = WelcomeTrack(period: 8.8, [
            .init(0, 1), .init(0.5, 1, .easeIn), .init(1.12, 0.96, .easeOut), .init(1.2, 1.13, .easeOut),
    // swiftlint:disable:next line_length
            .init(1.45, 0.95, .easeIn), .init(1.7, 1.07, .easeOut), .init(1.82, 0.98, .easeIn), .init(1.94, 1.03, .easeOut),
            .init(2.1, 1), .init(8.8, 1)
    ])

    static let squashY = WelcomeTrack(period: 8.8, [
            .init(0, 1), .init(0.5, 1, .easeIn), .init(1.12, 1.05, .easeOut), .init(1.2, 0.84, .easeOut),
    // swiftlint:disable:next line_length
            .init(1.45, 1.06, .easeIn), .init(1.7, 0.92, .easeOut), .init(1.82, 1.03, .easeIn), .init(1.94, 0.97, .easeOut),
            .init(2.1, 1), .init(8.8, 1)
    ])

    static let fadeOpacity = WelcomeTrack(period: 8.8, [
            .init(0, 0), .init(3.9, 0, .easeOut), .init(4.4, 1), .init(8.8, 1)
    ])

    /// The globe and its grid turn once per loop (radians).
    static let globeRotation = WelcomeTrack(period: 8.8, [
            .init(0, 0), .init(8.8, -6.28318)
    ])

    static let gridRotation = WelcomeTrack(period: 8.8, [
            .init(0, 0), .init(8.8, -6.28318)
    ])

    /// The walk: one step cycle of 1.1 s that repeats eight times per loop.
    static let shadowScaleX = WelcomeTrack(period: 1.1, [
            .init(0, 1.065), .init(0.046, 1.039), .init(0.092, 1.018), .init(0.138, 1.002),
            .init(0.183, 0.992), .init(0.229, 0.987), .init(0.275, 0.987), .init(0.321, 0.993),
            .init(0.367, 1.003), .init(0.413, 1.019), .init(0.458, 1.04), .init(0.504, 1.048),
            .init(0.55, 1.032), .init(0.596, 1.006), .init(0.642, 0.985), .init(0.688, 0.971),
            .init(0.733, 0.963), .init(0.779, 0.96), .init(0.825, 0.963), .init(0.871, 0.972),
            .init(0.917, 0.985), .init(0.963, 1.004), .init(1.008, 1.028), .init(1.054, 1.055),
            .init(1.1, 1.065)
    ])

    static let bob = WelcomeTrack(period: 1.1, [
            .init(0, 5.42), .init(0.046, 3.27), .init(0.092, 1.47), .init(0.138, 0.15),
            .init(0.183, -0.7), .init(0.229, -1.1), .init(0.275, -1.07), .init(0.321, -0.62),
            .init(0.367, 0.26), .init(0.413, 1.58), .init(0.458, 3.33), .init(0.504, 4.04),
            .init(0.55, 2.7), .init(0.596, 0.5), .init(0.642, -1.22), .init(0.688, -2.4),
            .init(0.733, -3.08), .init(0.779, -3.3), .init(0.825, -3.06), .init(0.871, -2.37),
            .init(0.917, -1.23), .init(0.963, 0.36), .init(1.008, 2.36), .init(1.054, 4.6),
            .init(1.1, 5.42)
    ])

    static let armBackRotation = WelcomeTrack(period: 1.1, [
            .init(0, 0.43092), .init(0.046, 0.40422), .init(0.092, 0.40596), .init(0.138, 0.43581),
            .init(0.183, 0.49201), .init(0.229, 0.57055), .init(0.275, 0.66619), .init(0.321, 0.77213),
            .init(0.367, 0.88157), .init(0.413, 0.98664), .init(0.458, 1.08053), .init(0.504, 1.15663),
            .init(0.55, 1.20969), .init(0.596, 1.23639), .init(0.642, 1.23465), .init(0.688, 1.2048),
            .init(0.733, 1.1486), .init(0.779, 1.07006), .init(0.825, 0.97442), .init(0.871, 0.86848),
            .init(0.917, 0.75904), .init(0.963, 0.65397), .init(1.008, 0.56008), .init(1.054, 0.48398),
            .init(1.1, 0.43092)
    ])

    static let armFrontRotation = WelcomeTrack(period: 1.1, [
            .init(0, -0.20141), .init(0.046, -0.17715), .init(0.092, -0.17872), .init(0.138, -0.20612),
            .init(0.183, -0.25761), .init(0.229, -0.32952), .init(0.275, -0.41713), .init(0.321, -0.51435),
            .init(0.367, -0.61453), .init(0.413, -0.71105), .init(0.458, -0.79709), .init(0.504, -0.86673),
            .init(0.55, -0.9156), .init(0.596, -0.93986), .init(0.642, -0.93829), .init(0.688, -0.91089),
            .init(0.733, -0.8594), .init(0.779, -0.78749), .init(0.825, -0.69988), .init(0.871, -0.60266),
            .init(0.917, -0.50248), .init(0.963, -0.40596), .init(1.008, -0.31992), .init(1.054, -0.25028),
            .init(1.1, -0.20141)
    ])

    static let legBackRotation = WelcomeTrack(period: 1.1, [
            .init(0, 0.04067), .init(0.046, 0.02286), .init(0.092, -0.02827), .init(0.138, -0.10716),
            .init(0.183, -0.20717), .init(0.229, -0.32062), .init(0.275, -0.44087), .init(0.321, -0.56095),
            .init(0.367, -0.67439), .init(0.413, -0.7744), .init(0.458, -0.85347), .init(0.504, -0.90443),
            .init(0.55, -0.92223), .init(0.596, -0.83688), .init(0.642, -0.75468), .init(0.688, -0.67439),
            .init(0.733, -0.59586), .init(0.779, -0.51801), .init(0.825, -0.44087), .init(0.871, -0.36355),
            .init(0.917, -0.28589), .init(0.963, -0.20717), .init(1.008, -0.12706), .init(1.054, -0.04468),
            .init(1.1, 0.04067)
    ])

    static let legBackY = WelcomeTrack(period: 1.1, [
            .init(0, 0), .init(0.046, -1.81), .init(0.092, -3.5), .init(0.138, -4.95),
            .init(0.183, -6.06), .init(0.229, -6.76), .init(0.275, -7), .init(0.321, -6.76),
            .init(0.367, -6.06), .init(0.413, -4.95), .init(0.458, -3.5), .init(0.504, -1.81),
            .init(0.55, 0), .init(1.1, 0)
    ])

    static let shoeBackRotation = WelcomeTrack(period: 1.1, [
            .init(0, -0.62797), .init(0.046, -0.55135), .init(0.092, -0.44279), .init(0.138, -0.31922),
            .init(0.183, -0.19268), .init(0.229, -0.07034), .init(0.275, 0.04224), .init(0.321, 0.14207),
            .init(0.367, 0.22776), .init(0.413, 0.2981), .init(0.458, 0.35168), .init(0.504, 0.38537),
            .init(0.55, 0.39706), .init(0.596, 0.36146), .init(0.642, 0.26581), .init(0.688, 0.15219),
            .init(0.733, 0.04032), .init(0.779, -0.07034), .init(0.825, -0.18029), .init(0.871, -0.29007),
            .init(0.917, -0.4002), .init(0.963, -0.50475), .init(1.008, -0.57858), .init(1.054, -0.61924),
            .init(1.1, -0.62797)
    ])

    static let legFrontRotation = WelcomeTrack(period: 1.1, [
            .init(0, 0.00122), .init(0.046, 0.07941), .init(0.092, 0.15516), .init(0.138, 0.22916),
            .init(0.183, 0.30212), .init(0.229, 0.3742), .init(0.275, 0.44611), .init(0.321, 0.51784),
            .init(0.367, 0.58992), .init(0.413, 0.66288), .init(0.458, 0.73688), .init(0.504, 0.81263),
            .init(0.55, 0.89082), .init(0.596, 0.87458), .init(0.642, 0.82781), .init(0.688, 0.7552),
            .init(0.733, 0.66288), .init(0.779, 0.55763), .init(0.825, 0.44611), .init(0.871, 0.33441),
            .init(0.917, 0.22916), .init(0.963, 0.13701), .init(1.008, 0.06423), .init(1.054, 0.01745),
            .init(1.1, 0.00122)
    ])

    static let legFrontY = WelcomeTrack(period: 1.1, [
            .init(0, 0), .init(0.55, 0), .init(0.596, -1.81), .init(0.642, -3.5),
            .init(0.688, -4.95), .init(0.733, -6.06), .init(0.779, -6.76), .init(0.825, -7),
            .init(0.871, -6.76), .init(0.917, -6.06), .init(0.963, -4.95), .init(1.008, -3.5),
            .init(1.054, -1.81), .init(1.1, 0)
    ])

    static let shoeFrontRotation = WelcomeTrack(period: 1.1, [
            .init(0, 0.6627), .init(0.046, 0.6339), .init(0.092, 0.54472), .init(0.138, 0.43686),
            .init(0.183, 0.33056), .init(0.229, 0.2255), .init(0.275, 0.12095), .init(0.321, 0.01658),
            .init(0.367, -0.08779), .init(0.413, -0.1864), .init(0.458, -0.25394), .init(0.504, -0.28815),
            .init(0.55, -0.2892), .init(0.596, -0.21433), .init(0.642, -0.11013), .init(0.688, 0.00681),
            .init(0.733, 0.12566), .init(0.779, 0.23946), .init(0.825, 0.34348), .init(0.871, 0.43476),
            .init(0.917, 0.51243), .init(0.963, 0.57544), .init(1.008, 0.62273), .init(1.054, 0.6524),
            .init(1.1, 0.6627)
    ])

    static let eyeNearScaleY = WelcomeTrack(period: 8.8, [
            .init(0, 1), .init(1.25, 1, .easeIn), .init(1.335, 0.04, .easeOut), .init(1.42, 1),
            .init(4.35, 1, .easeIn), .init(4.435, 0.04, .easeOut), .init(4.52, 1), .init(4.58, 1, .easeIn),
            .init(4.665, 0.04, .easeOut), .init(4.75, 1), .init(7.15, 1, .easeIn), .init(7.235, 0.04, .easeOut),
            .init(7.32, 1), .init(8.8, 1)
    ])

    static let lidNearY = WelcomeTrack(period: 8.8, [
            .init(0, 0), .init(1.25, 0, .easeIn), .init(1.335, 6.5, .easeOut), .init(1.42, 0),
            .init(4.35, 0, .easeIn), .init(4.435, 6.5, .easeOut), .init(4.52, 0), .init(4.58, 0, .easeIn),
            .init(4.665, 6.5, .easeOut), .init(4.75, 0), .init(7.15, 0, .easeIn), .init(7.235, 6.5, .easeOut),
            .init(7.32, 0), .init(8.8, 0)
    ])

    static let eyeFarScaleY = WelcomeTrack(period: 8.8, [
            .init(0, 1), .init(1.25, 1, .easeIn), .init(1.335, 0.04, .easeOut), .init(1.42, 1),
            .init(4.35, 1, .easeIn), .init(4.435, 0.04, .easeOut), .init(4.52, 1), .init(4.58, 1, .easeIn),
            .init(4.665, 0.04, .easeOut), .init(4.75, 1), .init(7.15, 1, .easeIn), .init(7.235, 0.04, .easeOut),
            .init(7.32, 1), .init(8.8, 1)
    ])

    static let lidFarY = WelcomeTrack(period: 8.8, [
            .init(0, 0), .init(1.25, 0, .easeIn), .init(1.335, 5.5, .easeOut), .init(1.42, 0),
            .init(4.35, 0, .easeIn), .init(4.435, 5.5, .easeOut), .init(4.52, 0), .init(4.58, 0, .easeIn),
            .init(4.665, 5.5, .easeOut), .init(4.75, 0), .init(7.15, 0, .easeIn), .init(7.235, 5.5, .easeOut),
            .init(7.32, 0), .init(8.8, 0)
    ])

    static let eyeHighlightAScaleY = WelcomeTrack(period: 8.8, [
            .init(0, 1), .init(1.25, 1, .easeIn), .init(1.335, 0.04, .easeOut), .init(1.42, 1),
            .init(4.35, 1, .easeIn), .init(4.435, 0.04, .easeOut), .init(4.52, 1), .init(4.58, 1, .easeIn),
            .init(4.665, 0.04, .easeOut), .init(4.75, 1), .init(7.15, 1, .easeIn), .init(7.235, 0.04, .easeOut),
            .init(7.32, 1), .init(8.8, 1)
    ])

    static let eyeHighlightBY = WelcomeTrack(period: 8.8, [
            .init(0, 0), .init(1.25, 0, .easeIn), .init(1.335, 5.5, .easeOut), .init(1.42, 0),
            .init(4.35, 0, .easeIn), .init(4.435, 5.5, .easeOut), .init(4.52, 0), .init(4.58, 0, .easeIn),
            .init(4.665, 5.5, .easeOut), .init(4.75, 0), .init(7.15, 0, .easeIn), .init(7.235, 5.5, .easeOut),
            .init(7.32, 0), .init(8.8, 0)
    ])

    static let eyeGlowOpacity = WelcomeTrack(period: 8.8, [
            .init(0, 0.32), .init(1.25, 0.32, .easeIn), .init(1.335, 0, .easeOut), .init(1.42, 0.32),
            .init(4.35, 0.32, .easeIn), .init(4.435, 0, .easeOut), .init(4.52, 0.32), .init(4.58, 0.32, .easeIn),
            .init(4.665, 0, .easeOut), .init(4.75, 0.32), .init(7.15, 0.32, .easeIn), .init(7.235, 0, .easeOut),
            .init(7.32, 0.32), .init(8.8, 0.32)
    ])

}
