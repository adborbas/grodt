import Foundation

protocol InMemoryTickerPriceCache {
    func price(for ticker: String, on date: YearMonthDayDate) -> Decimal?
    func setPrice(_ price: Decimal, for ticker: String, on date: YearMonthDayDate)
}
