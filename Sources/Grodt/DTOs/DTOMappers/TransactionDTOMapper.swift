import Foundation

class TransactionDTOMapper {
    private let currencyDTOMapper: CurrencyDTOMapper
    
    init(currencyDTOMapper: CurrencyDTOMapper) {
        self.currencyDTOMapper = currencyDTOMapper
    }
    
    func transaction(from transaction: Transaction) -> TransactionDTO {
        return TransactionDTO(id: transaction.id?.uuidString ?? "",
                              portfolioName: transaction.portfolio.name,
                              purchaseDate: transaction.purchaseDate,
                              ticker: transaction.ticker,
                              currency: currencyDTOMapper.currency(from: transaction.currency),
                              fees: transaction.fees,
                              numberOfShares: transaction.numberOfShares,
                              pricePerShareAtPurchase: transaction.pricePerShareAtPurchase)
    }
}
