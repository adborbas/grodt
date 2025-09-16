import Foundation

struct PortfolioPerformanceTimeSeriesDTO: Codable, Equatable {
    let values: [DatedPerformanceDTO]
}

struct DatedPerformanceDTO: Codable, Equatable {
    let date: Date
    let moneyIn: Decimal
    let moneyOut: Decimal
    let profit: Decimal
    let totalReturn: Decimal
}
