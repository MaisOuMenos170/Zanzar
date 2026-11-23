import SwiftUI

struct ListLoadingView: View {
    var body: some View {
        ProgressView()
            .frame(maxWidth: .infinity, minHeight: 400)
            .padding(.vertical, 48)
    }
}
