import SwiftUI

/// The title and subtitle at the top of a sheet. The close button is not here: it is the system's, put on the
/// sheet with `sheetCloseButton`, and this leaves room for it beside the title.
struct SheetHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.brandSheetTitle)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 8)
            }
            .padding(.top, 4)
            .padding(.bottom, 4)

            Text(subtitle)
                .font(.system(size: 14))
                .tracking(0.25)
                .foregroundStyle(.black)
        }
        // Room for the close button, which floats over the corner and reaches the line under the title.
        .padding(.trailing, 44)
    }
}

#Preview {
    SheetHeader(title: "Sugerir um lugar", subtitle: "Conheça um lugar e conte pra gente!")
        .padding()
}
