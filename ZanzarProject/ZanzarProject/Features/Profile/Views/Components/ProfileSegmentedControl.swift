import SwiftUI

/// "Meu passaporte | Ajustes": a white pill whose selected option is a coral pill with a soft sheen.
struct ProfileSegmentedControl: View {
    @Binding var selection: ProfileSection
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(spacing: 4) {
            ForEach(ProfileSection.allCases) { section in
                option(section)
            }
        }
        .padding(4)
        .background(Color.brandNeutral50, in: .capsule)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 4)
        .motion(Motion.toque, value: selection)
        .haptic(.selecao, trigger: selection)
    }

    private func option(_ section: ProfileSection) -> some View {
        let isSelected = selection == section
        return Button {
            selection = section
        } label: {
            Text(section.titleKey)
                .typography(.caption3)
                .foregroundStyle(isSelected ? Color.brandNeutral50 : Color.brandNeutral700)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .frame(minHeight: 32)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.brandOrange600)
                            .overlay { DiagonalStripes.pill }
                            .clipShape(.capsule)
                            .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                    }
                }
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var section = ProfileSection.passport
    ProfileSegmentedControl(selection: $section)
        .padding()
        .background(Color.profileBackground)
}
