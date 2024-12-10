import Foundation

class TickerChangeHandler: TickersControllerDelegate {
    private let priceService: PriceService

    init(
         priceService: PriceService) {
        self.priceService = priceService
    }
    
    func tickerCreated(_ ticker: Ticker) {
        Task {
            _ = try await priceService.historicalPrice(for: ticker.symbol)
            _ = try await priceService.price(for: ticker.symbol)
        }
    }
}
