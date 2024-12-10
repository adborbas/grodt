import Foundation

struct PortfolioInfoDTO: Codable, Equatable {
    let id: String
    let name: String
    let currency: CurrencyDTO
    let performance: PortfolioPerformanceDTO
}
