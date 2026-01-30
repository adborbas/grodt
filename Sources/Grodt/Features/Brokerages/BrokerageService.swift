import Vapor
import Fluent

protocol BrokerageServicing: Sendable {
    func allBrokerages(for userID: UUID) async throws -> [BrokerageDTO]
    func createBrokerage(named: String, for userID: UUID) async throws -> BrokerageDTO
    func brokerageDetail(id: UUID, for userID: UUID) async throws -> BrokerageDTO
    func updateBrokerage(id: UUID, update: CreateUpdateBrokerageRequestDTO, for userID: UUID) async throws -> BrokerageDTO
    func deleteBrokerage(id: UUID, for userID: UUID) async throws
}

struct BrokerageService: BrokerageServicing {
    private let brokerageRepository: BrokerageRepository
    private let dtoMapper: BrokerageDTOMapping

    init(brokerageRepository: BrokerageRepository,
         dtoMapper: BrokerageDTOMapping) {
        self.brokerageRepository = brokerageRepository
        self.dtoMapper = dtoMapper
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
                         for userID: UUID) async throws -> BrokerageDTO {
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
}
