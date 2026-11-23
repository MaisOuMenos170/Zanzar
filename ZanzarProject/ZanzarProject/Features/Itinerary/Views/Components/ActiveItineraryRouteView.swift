import SwiftUI

struct ActiveItineraryRouteView: View {
    let progress: ActiveItineraryProgress
    let avatar: Avatar

    @State private var avatarIndex = 0
    @State private var showsHalo = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private typealias Geometry = ActiveItineraryRouteGeometry

    var body: some View {
        GeometryReader { proxy in
            let scale = proxy.size.width / Geometry.designWidth
            let centers = Geometry.stopCenters(count: progress.total)
                .map { CGPoint(x: $0.x * scale, y: $0.y) }

            ZStack(alignment: .topLeading) {
                Image(.checkInActiveRoutePath)
                    .resizable()
                    .frame(width: Geometry.pathFrame.width * scale, height: Geometry.pathFrame.height)
                    .position(x: Geometry.pathFrame.midX * scale, y: Geometry.pathFrame.midY)

                if let current = centers[safe: progress.currentIndex] {
                    Circle()
                        .fill(Self.halo)
                        .frame(width: 53, height: 53)
                        .position(current)
                        .opacity(showsHalo ? 1 : 0)
                }

                ForEach(centers.indices, id: \.self) { index in
                    StopMarker(color: color(for: progress.state(at: index)))
                        .position(centers[index])
                }

                if let position = centers[safe: min(avatarIndex, progress.currentIndex)] {
                    AvatarMarker(avatar: avatar)
                        .position(position)
                }
            }
        }
        .frame(height: Geometry.height)
        .accessibilityHidden(true)
        .task(id: progress.completed) { await walkToCurrentStop() }
    }

    private func color(for state: ActiveItineraryProgress.StopState) -> Color {
        switch state {
        case .done: Self.done
        case .current, .upcoming: Color.brandPurple500
        case .destination: Self.destination
        }
    }

    private func walkToCurrentStop() async {
        let target = progress.currentIndex
        guard !reduceMotion else {
            avatarIndex = target
            showsHalo = true
            return
        }
        showsHalo = false
        guard avatarIndex < target else {
            withAnimation(.easeOut(duration: 0.3)) { showsHalo = true }
            return
        }
        do {
            try await Task.sleep(for: .milliseconds(450))
            for index in (avatarIndex + 1)...target {
                withAnimation(.smooth(duration: 0.55)) { avatarIndex = index }
                try await Task.sleep(for: .milliseconds(700))
            }
        } catch {
            return
        }
        withAnimation(.easeOut(duration: 0.3)) { showsHalo = true }
    }

    private static let done = Color(red: 99 / 255, green: 186 / 255, blue: 36 / 255)
    private static let destination = Color(red: 249 / 255, green: 108 / 255, blue: 92 / 255)
    private static let halo = Color(red: 249 / 255, green: 224 / 255, blue: 177 / 255)
}

private struct StopMarker: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 30.944, height: 30.944)
            .overlay { Circle().strokeBorder(.white, lineWidth: 3) }
            .shadow(color: .black.opacity(0.25), radius: 3.2)
    }
}

private struct AvatarMarker: View {
    let avatar: Avatar

    var body: some View {
        AvatarPortraitView(avatar: avatar, fallbackBackground: Color.brandPurple400)
            .frame(width: 37, height: 37)
            .overlay { Circle().strokeBorder(.white, lineWidth: 3.588) }
            .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1.196)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ActiveItineraryRouteView(
        progress: ActiveItineraryProgress(previewItinerary),
        avatar: .placeholder
    )
    .frame(width: 360)
    .background(Color.brandPurple50)
}

private let previewItinerary = ActiveItinerary(
    templateID: "1",
    slug: "centro-historico",
    name: "Bora passear no centro histórico?",
    description: "",
    category: "historic",
    routeType: .fixed,
    objectives: [],
    targetCategory: nil,
    targetCount: nil,
    startedAt: .now,
    places: (0..<4).map { index in
        ItinerarySlot(
            id: "\(index)",
            placeID: "p\(index)",
            placeName: "Parada \(index + 1)",
            isCompleted: index < 2,
            completedAt: nil,
            stampID: nil
        )
    }
)
