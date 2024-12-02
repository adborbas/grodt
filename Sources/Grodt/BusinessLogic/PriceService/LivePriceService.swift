import Foundation
import AlphaSwiftage

class LivePriceService: PriceService {
    private let alphavantage: AlphaVantageService
    
    init(alphavantage: AlphaVantageService) {
        self.alphavantage = alphavantage
    }
    
    func price(for ticker: String) async throws -> Decimal {
        let result = await alphavantage.quote(for: ticker)
        switch result {
        case .success(let quote):
            return quote.price
        case .failure(let error):
            throw error
        }
    }
    
    func historicalPrice(for ticker: String) async throws -> [DatedQuote] {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.universalGMT
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let result = await alphavantage.dailyAdjustedTimeSeries(for: ticker, outputSize: .full)
        switch result {
        case .success(let quotes):
            return quotes.compactMap { dateString, equityDailyData in
                guard let date = dateFormatter.date(from: dateString) else { return nil}
                return DatedQuote(price: equityDailyData.adjustedClose, date: YearMonthDayDate(date))
            }
        case .failure(let error):
            throw error
        }
    }
}
