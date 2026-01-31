@testable import Grodt

final class MockTickerDTOMapper: TickerDTOMapping, @unchecked Sendable {
    var tickerResult: TickerDTO = TickerDTO(symbol: "AAPL", region: "US", name: "Apple Inc", currency: "USD")

    func ticker(from ticker: Ticker) -> TickerDTO {
        tickerResult
    }
}
