@testable import Grodt
import Vapor
import Fluent

final class MockBrokerageService: BrokerageServicing, @unchecked Sendable {
    var allBrokeragesResult: Result<[BrokerageDTO], Error> = .success([])
    var createBrokerageResult: Result<BrokerageDTO, Error>?
    var brokerageDetailResult: Result<BrokerageDTO, Error>?
    var updateBrokerageResult: Result<BrokerageDTO, Error>?
    var deleteBrokerageResult: Result<Void, Error> = .success(())

    func allBrokerages(for userID: UUID) async throws -> [BrokerageDTO] {
        try allBrokeragesResult.get()
    }

    func createBrokerage(named: String, for userID: UUID) async throws -> BrokerageDTO {
        guard let result = createBrokerageResult else {
            throw Abort(.notImplemented)
        }
        return try result.get()
    }

    func brokerageDetail(id: UUID, for userID: UUID, on db: Database) async throws -> BrokerageDTO {
        guard let result = brokerageDetailResult else {
            throw Abort(.notImplemented)
        }
        return try result.get()
    }

    func updateBrokerage(id: UUID, update: CreateUpdateBrokerageRequestDTO, for userID: UUID) async throws -> BrokerageDTO {
        guard let result = updateBrokerageResult else {
            throw Abort(.notImplemented)
        }
        return try result.get()
    }

    func deleteBrokerage(id: UUID, for userID: UUID) async throws {
        try deleteBrokerageResult.get()
    }
}
