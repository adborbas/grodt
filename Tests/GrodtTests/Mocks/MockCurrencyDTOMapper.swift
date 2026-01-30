@testable import Grodt

final class MockCurrencyDTOMapper: CurrencyDTOMapping, @unchecked Sendable {
    var currencyResult: CurrencyDTO = CurrencyDTO(code: "EUR", symbol: "€")

    func currency(from currency: Currency) -> CurrencyDTO {
        currencyResult
    }
}
