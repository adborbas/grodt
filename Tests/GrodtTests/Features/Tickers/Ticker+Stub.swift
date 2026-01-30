@testable import Grodt
import Foundation

extension Ticker {
    static func stub(
        id: UUID = UUID(),
        symbol: String = "AAPL",
        region: String = "US",
        name: String = "Apple Inc",
        currency: String = "USD"
    ) -> Ticker {
        Ticker(id: id, symbol: symbol, region: region, name: name, currency: currency)
    }
}

extension SymbolSearchResult {
    static func stub(
        symbol: String = "AAPL",
        region: String = "US",
        name: String = "Apple Inc",
        currency: String = "USD"
    ) -> SymbolSearchResult {
        SymbolSearchResult(symbol: symbol, region: region, name: name, currency: currency)
    }
}
