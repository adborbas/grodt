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
    
    func brokerageAccountInfo(from brokerageAccount: BrokerageAccount) async throws -> BrokerageAccountInfoDTO {
        try await brokerageAccount.$brokerage.load(on: database)
        let performance = try await brokerageAccountRepository.performance(for: brokerageAccount.requireID())
        
        return try BrokerageAccountInfoDTO(id: brokerageAccount.requireID(),
                                       brokerageId: brokerageAccount.brokerage.requireID(),
                                       brokerageName: brokerageAccount.brokerage.name,
                                       displayName: brokerageAccount.displayName,
                                       baseCurrency: currencyMapper.currency(from: brokerageAccount.baseCurrency),
                                       performance: performance)
    }
}
