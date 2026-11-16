import SwiftUI

/// The spinner of a profile list while it loads, in the middle of the space the list will take.
struct ListLoadingView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, minHeight: 400)
            .padding(.vertical, 48)
    }
}
