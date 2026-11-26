import SwiftUI

struct SheetHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .scaledFont(size: 22, weight: .bold, design: .rounded)
                    .foregroundStyle(Color.brandSheetTitle)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 8)
            }
            .padding(.top, 4)
            .padding(.bottom, 4)

            Text(subtitle)
                .scaledFont(size: 14)
                .tracking(0.25)
                .foregroundStyle(.black)
        }
        .padding(.trailing, 44)
    }
}

#Preview {
    SheetHeader(title: "Sugerir um lugar", subtitle: "Conheça um lugar e conte pra gente!")
        .padding()
}
