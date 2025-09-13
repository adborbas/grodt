import Fluent

struct BrokerageAccountDTOMapper {
    private let brokerageAccountRepository: BrokerageAccountRepository
    private let currencyMapper: CurrencyDTOMapper
    private let database: Database
    
    init(brokerageAccountRepository: BrokerageAccountRepository,
         currencyMapper: CurrencyDTOMapper,
         database: Database) {
        self.brokerageAccountRepository = brokerageAccountRepository
        self.currencyMapper = currencyMapper
        self.database = database
    }
    
    func brokerageAccount(from brokerageAccount: BrokerageAccount) async throws -> BrokerageAccountDTO {
        try await brokerageAccount.$brokerage.load(on: database)
        let totals = try await brokerageAccountRepository.totals(for: brokerageAccount.requireID())
        
        return try BrokerageAccountDTO(id: brokerageAccount.requireID(),
                                       brokerageId: brokerageAccount.brokerage.requireID(),
                                       brokerageName: brokerageAccount.brokerage.name,
                                       displayName: brokerageAccount.displayName,
                                       baseCurrency: currencyMapper.currency(from: brokerageAccount.baseCurrency),
                                       totals: totals ?? PerformanceTotalsDTO())
    }
}
