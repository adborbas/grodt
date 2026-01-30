import Foundation

protocol CurrencyDTOMapping: Sendable {
    func currency(from currency: Currency) -> CurrencyDTO
}

extension CurrencyDTOMapper: CurrencyDTOMapping { }
