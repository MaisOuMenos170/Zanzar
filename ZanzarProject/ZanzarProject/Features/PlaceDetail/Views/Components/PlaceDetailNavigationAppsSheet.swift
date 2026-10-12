import SwiftUI

struct PlaceDetailNavigationAppsSheet: View {
    let apps: [PlaceDetailNavigationApp]
    let onSelect: (PlaceDetailNavigationApp) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var contentHeight: CGFloat = 300

    var body: some View {
        NavigationStack {
            appList
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.height
                } action: { height in
                    contentHeight = height
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationTitle("placeDetail.navigationSheet.title")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close) {
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.height(contentHeight + 62)])
        .presentationBackground(Color(.systemGroupedBackground))
    }

    private var appList: some View {
        VStack(spacing: 0) {
            ForEach(apps) { app in
                if app != apps.first {
                    Divider()
                }
                Button {
                    onSelect(app)
                    dismiss()
                } label: {
                    Text("placeDetail.navigationSheet.openIn \(app.displayName)")
                        .font(.body)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 16)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 28))
    }
}
