@testable import Grodt
import Vapor

final class MockBrokerageAccountRepository: BrokerageAccountRepository, @unchecked Sendable {
    var allResult: Result<[BrokerageAccount], Error> = .success([])
    var findResult: Result<BrokerageAccount?, Error> = .success(nil)
    var createResult: Result<Void, Error> = .success(())
    var updateResult: Result<Void, Error> = .success(())
    var deleteResult: Result<Void, Error> = .success(())
    var performanceResult: Result<PerformanceDTO, Error> = .success(.zero)

    private(set) var createCalled = false
    private(set) var updateCalled = false
    private(set) var deleteCalled = false

    func all(for userID: User.IDValue) async throws -> [BrokerageAccount] {
        try allResult.get()
    }

    func find(_ id: BrokerageAccount.IDValue, for userID: User.IDValue) async throws -> BrokerageAccount? {
        try findResult.get()
    }

    func create(_ account: BrokerageAccount) async throws {
        createCalled = true
        try createResult.get()
    }

    func update(_ account: BrokerageAccount) async throws {
        updateCalled = true
        try updateResult.get()
    }

    func delete(_ account: BrokerageAccount) async throws {
        deleteCalled = true
        try deleteResult.get()
    }

    func performance(for accountID: BrokerageAccount.IDValue) async throws -> PerformanceDTO {
        try performanceResult.get()
    }
}
