@testable import Grodt
import Foundation

extension Transaction {
    static func stub(
        id: UUID = UUID(),
        portfolioID: UUID = UUID(),
        brokerageAccountID: UUID? = nil,
        type: TransactionType = .buy,
        transactionDate: Date = Date(),
        ticker: String = "AAPL",
        currency: Currency = .stub(),
        fees: Decimal = 0,
        numberOfShares: Decimal = 10,
        pricePerShare: Decimal = 150
    ) -> Transaction {
        Transaction(
            id: id,
            portfolioID: portfolioID,
            brokerageAccountID: brokerageAccountID,
            type: type,
            transactionDate: transactionDate,
            ticker: ticker,
            currency: currency,
            fees: fees,
            numberOfShares: numberOfShares,
            pricePerShare: pricePerShare
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
