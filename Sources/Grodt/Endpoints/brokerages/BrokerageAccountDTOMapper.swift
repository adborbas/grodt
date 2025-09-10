struct BrokerageAccountDTOMapper {
    private let brokerageAccountRepository: BrokerageAccountRepository
    private let currencyMapper: CurrencyDTOMapper
    
    init(brokerageAccountRepository: BrokerageAccountRepository, currencyMapper: CurrencyDTOMapper) {
        self.brokerageAccountRepository = brokerageAccountRepository
        self.currencyMapper = currencyMapper
    }
    
    func brokerageAccount(from brokerageAccount: BrokerageAccount) async throws -> BrokerageAccountDTO {
        let totals = try await brokerageAccountRepository.totals(for: brokerageAccount.requireID())
        
        return try BrokerageAccountDTO(id: brokerageAccount.requireID(),
                                       brokerageId: brokerageAccount.brokerage.requireID(),
                                       brokerageName: brokerageAccount.brokerage.name,
                                       displayName: brokerageAccount.displayName,
                                       baseCurrency: currencyMapper.currency(from: brokerageAccount.baseCurrency),
                                       totals: totals)
    }
}
