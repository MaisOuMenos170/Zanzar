import SwiftUI

struct CheckboxBoxView: View {
    let isOn: Bool

    @ScaledMetric(relativeTo: .subheadline) private var size: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.white)
            .strokeBorder(Color.brandBlue200, lineWidth: 1)
            .frame(width: size, height: size)
            .overlay {
                if isOn {
                    Image(systemName: "checkmark")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.brandPurple500)
                }
            }
    }
}

#Preview {
    HStack {
        CheckboxBoxView(isOn: false)
        CheckboxBoxView(isOn: true)
    }
    .padding()
}
