@testable import Grodt
import Foundation

extension TransactionDTO {
    static func stub(
        id: String = UUID().uuidString,
        portfolioName: String = "Test Portfolio",
        type: TransactionTypeDTO = .buy,
        transactionDate: Date = Date(),
        ticker: String = "AAPL",
        currency: CurrencyDTO = CurrencyDTO(code: "USD", symbol: "$"),
        fees: Decimal = 0,
        numberOfShares: Decimal = 10,
        pricePerShare: Decimal = 150,
        brokerageAccount: BrokerageAccountInfoDTO? = nil
    ) -> TransactionDTO {
        TransactionDTO(
            id: id,
            portfolioName: portfolioName,
            type: type,
            transactionDate: transactionDate,
            ticker: ticker,
            currency: currency,
            fees: fees,
            numberOfShares: numberOfShares,
            pricePerShare: pricePerShare,
            brokerageAccount: brokerageAccount
        )
    }
}
