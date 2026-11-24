import SwiftUI

struct AvatarNoOptionView: View {
    var body: some View {
        Image(systemName: "nosign")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color.brandNeutral700)
            .frame(width: 56, height: 56)
    }
}

#Preview {
    AvatarNoOptionView()
}
