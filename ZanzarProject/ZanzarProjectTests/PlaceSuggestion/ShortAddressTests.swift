import Testing
@testable import ZanzarProject

@Suite("ShortAddress")
struct ShortAddressTests {
    @Test("drops only the postal code")
    func dropsThePostalCode() {
        let full = "Rua XV de Novembro, 1234, Centro, Curitiba - PR, 80020-310, Brasil"
        #expect(ShortAddress.format(full) == "Rua XV de Novembro, 1234, Centro, Curitiba - PR, Brasil")
    }

    @Test("drops a postal code without a dash")
    func dropsPlainPostalCode() {
        #expect(ShortAddress.format("Av. Batel, 500, 80420090, Brazil") == "Av. Batel, 500, Brazil")
    }

    @Test("leaves an address without a postal code as it is")
    func keepsAddressWithoutPostalCode() {
        #expect(ShortAddress.format("Rua das Flores, 10, Centro") == "Rua das Flores, 10, Centro")
    }

    @Test("leaves something typed by hand as it is")
    func keepsTypedText() {
        #expect(ShortAddress.format("  Casa do Sapo ") == "Casa do Sapo")
        #expect(ShortAddress.format("perto da praça") == "perto da praça")
    }
}
