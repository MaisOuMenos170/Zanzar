import SwiftUI

struct PlaceDetailCheckInButton: View {
    let hasCheckedIn: Bool
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        if hasCheckedIn {
            Text("placeDetail.checkInButton.doneTitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color("PlaceDetailCheckInDoneBackground"), in: .capsule)
                .overlay {
                    Capsule()
                        .strokeBorder(Color("PlaceDetailCheckInDoneBorder"), lineWidth: 1)
                }
                .accessibilityAddTraits(.isStaticText)
        } else {
            Button("placeDetail.checkInButton.title", action: action)
                .buttonStyle(AuthPrimaryButtonStyle())
                .disabled(isLoading)
                .overlay {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
        }
    }
}
