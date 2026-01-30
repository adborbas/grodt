import Foundation

protocol TickerDTOMapping: Sendable {
    func ticker(from ticker: Ticker) -> TickerDTO
}

extension TickerDTOMapper: TickerDTOMapping { }
