struct BrokerageDTOMapper {
    private let brokerageRepository: BrokerageRepository
    private let accountDTOMapper: BrokerageAccountDTOMapper
    
    init(brokerageRepository: BrokerageRepository, accountDTOMapper: BrokerageAccountDTOMapper) {
        self.brokerageRepository = brokerageRepository
        self.accountDTOMapper = accountDTOMapper
    }
    
    func brokerage(from brokerage: Brokerage) async throws -> BrokerageDTO {
        let accounts = try await brokerage.accounts.asyncMap { try await accountDTOMapper.brokerageAccount(from: $0) }
        let totals = try await brokerageRepository.totals(for: brokerage.requireID())
        return try BrokerageDTO(id: brokerage.requireID(),
                            name: brokerage.name,
                            accounts: accounts,
                            totals: totals)
    }
}


