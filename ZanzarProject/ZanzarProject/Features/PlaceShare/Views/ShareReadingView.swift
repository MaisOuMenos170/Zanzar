import SwiftUI

/// While the link is followed and the place looked up: the sleepy Lero and a card that is about to fill in.
struct ShareReadingView: View {
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulsing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SheetHeader(title: "placeShare.header.title", subtitle: "placeShare.header.subtitle")

            VStack(spacing: 8) {
                Image("CarinhaBocejando")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .accessibilityHidden(true)
                Text("placeShare.reading.title")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.brandSheetTitle)
                Text("placeShare.reading.subtitle")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.brandNeutral600)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)

            VStack(spacing: 8) {
                placeholder(height: 132)
                placeholder(height: 56)
            }
            .opacity(isPulsing ? 0.5 : 1)
            .accessibilityHidden(true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { isPulsing = true }
        }
    }

    private func placeholder(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.brandNeutral100)
            .frame(height: height)
    }
}

#Preview {
    ShareReadingView(onClose: {})
}
