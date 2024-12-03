import Foundation

class DictionaryInMemoryTickerPriceCache: InMemoryTickerPriceCache {
    private var dictionary = [QuoteKey: Decimal]()
    
    func price(for ticker: String, on date: YearMonthDayDate) -> Decimal? {
        return dictionary[QuoteKey(ticker, date)]
    }
    
    func setPrice(_ price: Decimal, for ticker: String, on date: YearMonthDayDate) {
        dictionary[QuoteKey(ticker, date)] = price
    }
}

fileprivate struct QuoteKey: Hashable {
    let ticker: String
    let date: YearMonthDayDate
    
    init(_ ticker: String, _ date: YearMonthDayDate) {
        self.ticker = ticker
        self.date = date
    }
}
