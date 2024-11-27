import Foundation

struct DatedPortfolioPerformance: Codable {
    let moneyIn: Decimal
    let value: Decimal
    let date: YearMonthDayDate
}
