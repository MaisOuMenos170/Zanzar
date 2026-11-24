import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(alignment: .top, spacing: 16) {
                CheckboxBoxView(isOn: configuration.isOn)
                    .padding(.top, 2)
                configuration.label
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? Text("accessibility.checked") : Text("accessibility.unchecked"))
    }
}
