import SwiftUI

/// 16pt square checkbox with a pink border, used for the sign-up terms acceptance.
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.brandNeutral50)
                    .strokeBorder(Color.brandPink200, lineWidth: 1)
                    .frame(width: 16, height: 16)
                    .overlay {
                        if configuration.isOn {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.brandPink300)
                        }
                    }
                configuration.label
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? Text("accessibility.checked") : Text("accessibility.unchecked"))
    }
}
