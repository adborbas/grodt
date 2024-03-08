import Foundation

struct PortfolioDTO: Codable, Equatable {
    let id: String
    let name: String
    let currency: CurrencyDTO
    let performance: PerformanceDTO
    let transactions: [TransactionDTO]
}
