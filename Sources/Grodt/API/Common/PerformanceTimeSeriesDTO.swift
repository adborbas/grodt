import Foundation

struct PerformanceTimeSeriesDTO: Codable, Equatable {
    let values: [DatedPerformanceDTO]
}

struct DatedPerformanceDTO: Codable, Equatable {
    let date: Date
    let invested: Decimal
    let currentValue: Decimal
    let profit: Decimal
    let totalReturn: Decimal
}
