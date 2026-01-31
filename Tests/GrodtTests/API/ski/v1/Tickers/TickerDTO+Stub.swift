@testable import Grodt
import Foundation

extension TickerDTO {
    static func stub(
        symbol: String = "AAPL",
        region: String = "United States",
        name: String = "Apple Inc",
        currency: String = "USD"
    ) -> TickerDTO {
        TickerDTO(
            symbol: symbol,
            region: region,
            name: name,
            currency: currency
        )
    }
}
