import Fluent

struct BrokerageDTOMapper {
    private let brokerageRepository: BrokerageRepository
    private let accountDTOMapper: BrokerageAccountDTOMapper
    private let database: Database
    
    init(brokerageRepository: BrokerageRepository,
         accountDTOMapper: BrokerageAccountDTOMapper,
         database: Database) {
        self.brokerageRepository = brokerageRepository
        self.accountDTOMapper = accountDTOMapper
        self.database = database
    }
    
    func brokerage(from brokerage: Brokerage) async throws -> BrokerageDTO {
        try await brokerage.$accounts.load(on: database)
        let accountDTOs = try await brokerage.accounts.asyncMap {
            try await accountDTOMapper.brokerageAccount(from: $0)
        }
        let totals = try await brokerageRepository.totals(for: brokerage.requireID())
        return try BrokerageDTO(
            id: brokerage.requireID(),
            name: brokerage.name,
            accounts: accountDTOs,
            totals: totals
        )
    }
}


