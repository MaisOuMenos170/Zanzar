import SwiftUI

/// Color-wheel button that edits the circle color behind the avatar. The system color picker is the control that
/// receives the tap; the wheel is drawn over it and lets touches through.
struct AvatarBackgroundPicker: View {
    @Binding var color: Color

    private static let wheel = AngularGradient(
        colors: [.red, .yellow, .green, .cyan, .blue, .purple, .pink, .red],
        center: .center
    )

    var body: some View {
        ColorPicker(
            "avatarEditor.backgroundPicker.accessibilityLabel",
            selection: $color,
            supportsOpacity: false
        )
        .labelsHidden()
        // The system swatch is about 28pt; scale it so it stays under the 36pt wheel but keeps a comfortable tap area.
        .scaleEffect(1.15)
        .frame(width: 36, height: 36)
        .overlay {
            Circle()
                .fill(Self.wheel)
                .overlay {
                    Circle().strokeBorder(.white, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    @Previewable @State var color = Color.orange
    AvatarBackgroundPicker(color: $color)
        .padding()
}
