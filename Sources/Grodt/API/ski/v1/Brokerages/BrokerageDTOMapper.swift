import Fluent

struct BrokerageDTOMapper: BrokerageDTOMapping {
    private let brokerageRepository: BrokerageRepository
    private let accountDTOMapper: BrokerageAccountDTOMapper
    private let performanceRepository: PostgresBrokerageDailyPerformanceRepository
    private let performanceDTOMapper: DatedPerformanceDTOMapper
    private let database: Database
    
    init(brokerageRepository: BrokerageRepository,
         accountDTOMapper: BrokerageAccountDTOMapper,
         performanceRepository: PostgresBrokerageDailyPerformanceRepository,
         performanceDTOMapper: DatedPerformanceDTOMapper,
         database: Database) {
        self.brokerageRepository = brokerageRepository
        self.accountDTOMapper = accountDTOMapper
        self.database = database
        self.performanceRepository = performanceRepository
        self.performanceDTOMapper = performanceDTOMapper
    }
    
    func brokerage(from brokerage: Brokerage) async throws -> BrokerageDTO {
        try await brokerage.$accounts.load(on: database)
        let accountDTOs = try await brokerage.accounts.asyncMap {
            try await accountDTOMapper.brokerageAccountInfo(from: $0)
        }
        let performance = try await brokerageRepository.performance(for: brokerage.requireID())
        
        let rows = try await performanceRepository.readSeries(for: brokerage.requireID(), from: nil, to: nil)
        let values =  rows.map { performanceDTOMapper.performancePoint(from: $0)  }
            .sorted { $0.date < $1.date }
        
        return try BrokerageDTO(
            id: brokerage.requireID(),
            name: brokerage.name,
            accounts: accountDTOs,
            performance: performance,
            historicalPerformance: PerformanceTimeSeriesDTO(values: values)
        )
    }
}


