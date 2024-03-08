import Foundation

class TickerDTOMapper {
    func ticker(from ticker: Ticker) -> TickerDTO {
        return TickerDTO(symbol: ticker.symbol, region: ticker.region, name: ticker.name, currency: ticker.currency)
    }
}
