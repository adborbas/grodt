import Foundation

struct DatedQuote: Codable {
    let price: Decimal
    let date: YearMonthDayDate
}
