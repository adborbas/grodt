@testable import Grodt
import Foundation

extension TransactionDTO {
    static func stub(
        id: String = UUID().uuidString,
        portfolioName: String = "Test Portfolio",
        purchaseDate: Date = Date(),
        ticker: String = "AAPL",
        currency: CurrencyDTO = CurrencyDTO(code: "USD", symbol: "$"),
        fees: Decimal = 0,
        numberOfShares: Decimal = 10,
        pricePerShareAtPurchase: Decimal = 150,
        brokerageAccount: BrokerageAccountInfoDTO? = nil
    ) -> TransactionDTO {
        TransactionDTO(
            id: id,
            portfolioName: portfolioName,
            purchaseDate: purchaseDate,
            ticker: ticker,
            currency: currency,
            fees: fees,
            numberOfShares: numberOfShares,
            pricePerShareAtPurchase: pricePerShareAtPurchase,
            brokerageAccount: brokerageAccount
        )
    }
}
