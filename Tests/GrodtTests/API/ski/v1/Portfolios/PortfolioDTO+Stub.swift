@testable import Grodt
import Foundation

extension PortfolioDTO {
    static func stub(
        id: UUID = UUID(),
        name: String = "Test Portfolio",
        currencyCode: String = "EUR"
    ) -> PortfolioDTO {
        PortfolioDTO(
            id: id.uuidString,
            name: name,
            currency: CurrencyDTO(code: currencyCode, symbol: "€"),
            performance: .zero,
            investments: [],
            transactions: []
        )
    }
}
