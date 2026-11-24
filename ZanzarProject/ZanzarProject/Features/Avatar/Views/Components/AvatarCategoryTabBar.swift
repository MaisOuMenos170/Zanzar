import SwiftUI

struct AvatarCategoryTabBar: View {
    @Binding var selection: AvatarEditorTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AvatarEditorTab.allCases) { tab in
                AvatarCategoryTabButton(tab: tab, isSelected: tab == selection) {
                    selection = tab
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var selection = AvatarEditorTab.hair
    AvatarCategoryTabBar(selection: $selection)
        .padding()
        .background(Color.brandBlue50)
}
