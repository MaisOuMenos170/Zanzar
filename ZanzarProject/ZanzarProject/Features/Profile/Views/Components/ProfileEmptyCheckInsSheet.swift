import SwiftUI

/// A blank sheet for someone who has not checked in yet. It does not move.
struct ProfileEmptyCheckInsSheet: View {
    var body: some View {
        Text("profile.recentCheckIns.empty")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color("PlaceDetailStatsBackground"), in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color(.systemGray), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
    }
}

#Preview {
    ProfileEmptyCheckInsSheet()
        .padding()
}
