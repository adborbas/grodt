@testable import Grodt
import Foundation

final class MockBrokerageRepository: BrokerageRepository, @unchecked Sendable {
    var listResult: Result<[Brokerage], Error> = .success([])
    var findResult: Result<Brokerage?, Error> = .success(nil)
    var createResult: Result<Void, Error> = .success(())
    var updateResult: Result<Void, Error> = .success(())
    var deleteResult: Result<Void, Error> = .success(())
    var accountsCountResult: Result<Int, Error> = .success(0)
    var performanceResult: Result<PerformanceDTO, Error> = .success(.zero)

    private(set) var createCalled = false
    private(set) var createCalledWith: Brokerage?
    private(set) var updateCalled = false
    private(set) var updateCalledWith: Brokerage?
    private(set) var deleteCalled = false
    private(set) var deleteCalledWith: Brokerage?

    func list(for userID: User.IDValue) async throws -> [Brokerage] {
        try listResult.get()
    }

    func find(_ id: Brokerage.IDValue, for userID: User.IDValue) async throws -> Brokerage? {
        try findResult.get()
    }

    func create(_ brokerage: Brokerage) async throws {
        createCalled = true
        createCalledWith = brokerage
        try createResult.get()
    }

    func update(_ brokerage: Brokerage) async throws {
        updateCalled = true
        updateCalledWith = brokerage
        try updateResult.get()
    }

    func delete(_ brokerage: Brokerage) async throws {
        deleteCalled = true
        deleteCalledWith = brokerage
        try deleteResult.get()
    }

    func accountsCount(for brokerageID: Brokerage.IDValue) async throws -> Int {
        try accountsCountResult.get()
    }

    func performance(for brokerageID: Brokerage.IDValue) async throws -> PerformanceDTO {
        try performanceResult.get()
    }
}
