import SwiftUI

struct AvatarOptionGrid: View {
    let tab: AvatarEditorTab
    let selectedValue: Int
    let onSelect: (Int) -> Void

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 16), count: tab.gridColumnCount)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 24) {
                if tab.allowsNone {
                    AvatarOptionButton(
                        accessibilityLabel: Text("avatarEditor.option.none.accessibilityLabel"),
                        isSelected: selectedValue == Avatar.none
                    ) {
                        onSelect(Avatar.none)
                    } content: {
                        AvatarNoOptionView()
                    }
                }
                ForEach(1...tab.optionCount, id: \.self) { id in
                    AvatarOptionButton(
                        accessibilityLabel: Text("avatarEditor.option.accessibilityLabel \(id)"),
                        isSelected: selectedValue == id
                    ) {
                        onSelect(id)
                    } content: {
                        optionPicture(for: id)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.brandNeutral50)
                .shadow(color: .black.opacity(0.03), radius: 2, y: 4)
        }
    }

    @ViewBuilder
    private func optionPicture(for id: Int) -> some View {
        switch tab {
        case .skin:
            Image("Pele/\(id)")
                .resizable()
                .scaledToFit()
                .frame(width: 94)
        case .hair:
            Image("CabelosMiniatura/\(id)")
                .frame(height: 78)
        case .eyes:
            swatch(AvatarCatalog.eyeColors[id - 1])
        case .eyebrow:
            swatch(AvatarCatalog.eyebrowColors[id - 1])
        case .eyelash:
            swatch(AvatarCatalog.eyelashColors[id - 1])
        }
    }

    private func swatch(_ hex: String) -> some View {
        Circle()
            .fill(Color(hex: hex) ?? .clear)
            .frame(width: 56, height: 56)
    }
}

#Preview {
    AvatarOptionGrid(tab: .hair, selectedValue: Avatar.none) { _ in }
        .frame(height: 360)
        .padding()
        .background(Color.brandBlue50)
}
