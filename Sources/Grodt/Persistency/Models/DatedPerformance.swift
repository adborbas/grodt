import Foundation

struct DatedPerformance: Codable, Equatable {
    let moneyIn: Decimal
    let value: Decimal
    let date: YearMonthDayDate
}
