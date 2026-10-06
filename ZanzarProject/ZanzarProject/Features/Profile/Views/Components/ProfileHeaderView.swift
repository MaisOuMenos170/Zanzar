import SwiftUI

struct ProfileHeaderView: View {
    let name: String

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize = 72

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(Color("TabBarSelected"))
                .accessibilityHidden(true)

            Text(name)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ProfileHeaderView(name: "Ana Silva")
        .padding()
}
