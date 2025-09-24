import Vapor
import Fluent

struct BrokerageService {
    private let brokerageRepository: BrokerageRepository
    private let dtoMapper: BrokerageDTOMapper
    private let accountsRepository: BrokerageAccountRepository
    private let currencyMapper: CurrencyDTOMapper
    private let performanceRepository: PostgresBrokerageDailyPerformanceRepository
    private let performanceDTOMapper: DatedPerformanceDTOMapper
    
    init(brokerageRepository: BrokerageRepository,
         dtoMapper: BrokerageDTOMapper,
         accounts: BrokerageAccountRepository,
         currencyMapper: CurrencyDTOMapper,
         performanceRepository: PostgresBrokerageDailyPerformanceRepository,
         performanceDTOMapper: DatedPerformanceDTOMapper) {
        self.brokerageRepository = brokerageRepository
        self.dtoMapper = dtoMapper
        self.accountsRepository = accounts
        self.currencyMapper = currencyMapper
        self.performanceRepository = performanceRepository
        self.performanceDTOMapper = performanceDTOMapper
    }
    
    func allBrokerages(for userID: UUID) async throws -> [BrokerageDTO] {
        let brokerages = try await brokerageRepository.list(for: userID)
        return try await brokerages.concurrentMap {try await dtoMapper.brokerage(from: $0) }
    }
    
    func createBrokerage(named: String, for userID: UUID) async throws -> BrokerageDTO {
        let brokerage = Brokerage(userID: userID, name: named)
        try await brokerageRepository.create(brokerage)
        return try await dtoMapper.brokerage(from: brokerage)
    }
    
    func brokerageDetail(id: UUID,
                         for userID: UUID,
                         on db: Database) async throws -> BrokerageDTO {
        guard let brokerage = try await brokerageRepository.find(id, for: userID) else {
            throw Abort(.notFound)
        }
        return try await dtoMapper.brokerage(from: brokerage)
    }
    
    func updateBrokerage(id: UUID,
                         update: CreateUpdateBrokerageRequestDTO,
                         for userID: UUID) async throws -> BrokerageDTO {
        guard let brokerage = try await brokerageRepository.find(id, for: userID) else {
            throw Abort(.notFound)
        }
        brokerage.name = update.name
        try await brokerageRepository.update(brokerage)
        return try await dtoMapper.brokerage(from: brokerage)
    }
    
    func deleteBrokerage(id: UUID,
                         for userID: UUID) async throws {
        guard let brokerage = try await brokerageRepository.find(id, for: userID) else {
            throw Abort(.notFound)
        }
        try await brokerageRepository.delete(brokerage)
    }
    
    func performance(id: UUID,
                     for userID: UUID) async throws -> PerformanceTimeSeriesDTO {
        let rows = try await performanceRepository.readSeries(for: id, from: nil, to: nil)
        
        let values =  rows.map { performanceDTOMapper.performancePoint(from: $0)  }
            .sorted { $0.date < $1.date }
        return PerformanceTimeSeriesDTO(values: values)
    }
}
