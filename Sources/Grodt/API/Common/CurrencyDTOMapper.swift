import Foundation

class CurrencyDTOMapper {
    func currency(from currency: Currency) -> CurrencyDTO {
        return CurrencyDTO(code: currency.code, symbol: currency.symbol)
    }
}
