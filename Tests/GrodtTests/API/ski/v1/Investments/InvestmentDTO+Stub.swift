@testable import Grodt
import Foundation

extension InvestmentDetailDTO {
    static func stub(
        name: String = "Apple Inc",
        shortName: String = "AAPL",
        avgBuyPrice: Decimal = 150,
        latestPrice: Decimal = 175,
        totalReturn: Decimal = 0.167,
        profit: Decimal = 25,
        value: Decimal = 175,
        numberOfShares: Decimal = 1,
        currency: CurrencyDTO = CurrencyDTO(code: "USD", symbol: "$"),
        transactions: [TransactionDTO] = []
    ) -> InvestmentDetailDTO {
        InvestmentDetailDTO(
            name: name,
            shortName: shortName,
            avgBuyPrice: avgBuyPrice,
            latestPrice: latestPrice,
            totalReturn: totalReturn,
            profit: profit,
            value: value,
            numberOfShares: numberOfShares,
            currency: currency,
            transactions: transactions
        )
    }
}
