import Foundation

struct DatedPortfolioPerformance: Codable, Equatable {
    let moneyIn: Decimal
    let value: Decimal
    let date: YearMonthDayDate
}
