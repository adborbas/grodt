import Foundation
import Fluent

class TransactionDTOMapper: TransactionDTOMapping {
    private let currencyDTOMapper: CurrencyDTOMapper
    private let database: Database
    
    init(currencyDTOMapper: CurrencyDTOMapper,
         database: Database) {
        self.currencyDTOMapper = currencyDTOMapper
        self.database = database
    }
    
    func transaction(from transaction: Transaction) async throws -> TransactionDTO {
        var brokerageAccount: BrokerageAccountInfoDTO?
        if let brokerAcc = try await transaction.$brokerageAccount.get(on: database) {
            let brokerage = try await brokerAcc.$brokerage.get(on: database)
            brokerageAccount = BrokerageAccountInfoDTO(id: try brokerAcc.requireID(),
                                                       brokerageId: try brokerage.requireID(),
                                                       brokerageName: brokerAcc.brokerage.name,
                                                       displayName: brokerAcc.displayName,
                                                       baseCurrency: currencyDTOMapper.currency(from: brokerAcc.baseCurrency),
                                                       performance: PerformanceDTO.zero)
        }
        let portfolio = try await transaction.$portfolio.get(on: database)
        
        return TransactionDTO(id: transaction.id?.uuidString ?? "",
                              portfolioName: portfolio.name,
                              purchaseDate: transaction.purchaseDate,
                              ticker: transaction.ticker,
                              currency: currencyDTOMapper.currency(from: transaction.currency),
                              fees: transaction.fees,
                              numberOfShares: transaction.numberOfShares,
                              pricePerShareAtPurchase: transaction.pricePerShareAtPurchase,
                              brokerageAccount: brokerageAccount
        )
    }
}
