@testable import Grodt
import Foundation

extension Transaction {
    static func stub(
        id: UUID = UUID(),
        portfolioID: UUID = UUID(),
        brokerageAccountID: UUID? = nil,
        purchaseDate: Date = Date(),
        ticker: String = "AAPL",
        currency: Currency = .stub(),
        fees: Decimal = 0,
        numberOfShares: Decimal = 10,
        pricePerShareAtPurchase: Decimal = 150
    ) -> Transaction {
        Transaction(
            id: id,
            portfolioID: portfolioID,
            brokerageAccountID: brokerageAccountID,
            purchaseDate: purchaseDate,
            ticker: ticker,
            currency: currency,
            fees: fees,
            numberOfShares: numberOfShares,
            pricePerShareAtPurchase: pricePerShareAtPurchase
        )
    }
}

extension Currency {
    static func stub(
        id: UUID = UUID(),
        code: String = "USD",
        symbol: String = "$"
    ) -> Currency {
        Currency(id: id, code: code, symbol: symbol)
    }
}
