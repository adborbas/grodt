import Foundation

struct InvestmentDetailDTO: Codable, Equatable {
    let name: String
    let shortName: String
    let avgBuyPrice: Decimal
    let latestPrice: Decimal
    let totalReturn: Decimal
    let profit: Decimal
    let value: Decimal
    let numberOfShares: Decimal
    let currency: CurrencyDTO
    let transactions: [TransactionDTO]
}
