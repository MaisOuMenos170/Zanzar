import SwiftUI

/// The welcome illustration at one moment of its loop, on the 393 x 852 canvas of the design: the logo, the
/// planet that rises, the character that falls onto it and then walks. It only draws; `WelcomeIllustrationView`
/// owns the clock and the scale.
struct WelcomeCanvasView: View {
    let time: TimeInterval

    private typealias Art = WelcomeArt
    private typealias Pivot = WelcomeArt.Pivot
    private typealias Tracks = WelcomeTracks

    /// The arrival plays once and then holds; the walk, the blinks and the turning globe keep looping.
    private var arrival: TimeInterval { min(time, Tracks.loop - 0.001) }

    var body: some View {
        ZStack {
            Art.logo
                .opacity(Tracks.logoOpacity.value(at: arrival))
                .offset(y: Tracks.logoY.value(at: arrival))
            planet.offset(y: Tracks.planetY.value(at: arrival))
            shadow
            character
                .scaleEffect(x: Tracks.squashX.value(at: arrival), y: Tracks.squashY.value(at: arrival),
                             anchor: Art.squashAnchor)
                .offset(y: Tracks.fallY.value(at: arrival))
            fade
        }
        .frame(width: Art.canvas.width, height: Art.canvas.height)
        .clipped()
    }

    private var planet: some View {
        ZStack {
            Art.globe.rotationEffect(.radians(Tracks.globeRotation.value(at: time)), anchor: anchor(of: Art.globe))
            Art.glow
            Art.grid.rotationEffect(.radians(Tracks.gridRotation.value(at: time)), anchor: anchor(of: Art.grid))
            Art.center
        }
    }

    private var shadow: some View {
        let bounce = Tracks.shadowBounce.value(at: arrival)
        return Art.shadow
            .opacity(Tracks.shadowOpacity.value(at: arrival))
            .scaleEffect(x: Tracks.shadowScaleX.value(at: time) * bounce, y: bounce, anchor: anchor(of: Art.shadow))
    }

    /// Hides the lower part of the planet behind the buttons.
    private var fade: some View {
        LinearGradient(
            stops: [
                .init(color: Self.fadeColor.opacity(0), location: 0),
                .init(color: Self.fadeColor.opacity(0.92), location: 0.45),
                .init(color: Self.fadeColor, location: 0.75)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(width: Art.canvas.width, height: Self.fadeHeight)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .opacity(Tracks.fadeOpacity.value(at: arrival))
    }

    private static let fadeColor = Color(red: 0.94, green: 0.96, blue: 1)
    private static let fadeHeight: CGFloat = 190

    private func anchor(of layer: WelcomeLayer) -> UnitPoint {
        layer.center(in: Art.canvas)
    }

    /// Pieces are listed from back to front, as in the design. Arms, legs and shoes swing from their joints;
    /// the shoes sit inside the legs, so a leg carries its shoe along.
    private var character: some View {
        ZStack {
            Art.body1
            Art.eyeNear.scaleEffect(x: 1, y: Tracks.eyeNearScaleY.value(at: time), anchor: Pivot.eyeNear)
            Art.lidNear.offset(y: Tracks.lidNearY.value(at: time))
            Art.armBack.rotationEffect(.radians(Tracks.armBackRotation.value(at: time)), anchor: Pivot.armBack)
            Art.hip
            legs
            Art.body2
            Art.eyeFar.scaleEffect(x: 1, y: Tracks.eyeFarScaleY.value(at: time), anchor: Pivot.eyeFar)
            Art.lidFar.offset(y: Tracks.lidFarY.value(at: time))
            Art.body3
            Art.eyeHighlightA
                .scaleEffect(x: 1, y: Tracks.eyeHighlightAScaleY.value(at: time), anchor: Pivot.eyeHighlightA)
            Art.eyeHighlightB.offset(y: Tracks.eyeHighlightBY.value(at: time))
            Art.body4
            Art.armFront.rotationEffect(.radians(Tracks.armFrontRotation.value(at: time)), anchor: Pivot.armFront)
            Art.body5
            Art.eyeGlow.opacity(Tracks.eyeGlowOpacity.value(at: time))
            Art.body6
        }
        .frame(width: Art.stage.width, height: Art.stage.height)
        .position(x: Art.stage.midX, y: Art.stage.midY + Tracks.bob.value(at: time))
    }

    /// Cut at the hip, so a swinging leg never shows above it.
    private var legs: some View {
        ZStack {
            ZStack {
                Art.shoeBack.rotationEffect(.radians(Tracks.shoeBackRotation.value(at: time)), anchor: Pivot.shoeBack)
                Art.legBack
            }
            .rotationEffect(.radians(Tracks.legBackRotation.value(at: time)), anchor: Pivot.legBack)
            .offset(y: Tracks.legBackY.value(at: time))

            ZStack {
                Art.shoeFront
                    .rotationEffect(.radians(Tracks.shoeFrontRotation.value(at: time)), anchor: Pivot.shoeFront)
                Art.legFront
            }
            .rotationEffect(.radians(Tracks.legFrontRotation.value(at: time)), anchor: Pivot.legFront)
            .offset(y: Tracks.legFrontY.value(at: time))
        }
        .clipShape(Path(Art.hipClip))
    }
}

#Preview {
    WelcomeCanvasView(time: WelcomeTracks.stillTime)
        .background(Color.brandBlue50)
}
