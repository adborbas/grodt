@testable import Grodt
import Foundation

final class MockPortfolioRepository: PortfolioRepository, @unchecked Sendable {
    var allPortfoliosResult: Result<[Portfolio], Error> = .success([])
    var portfolioResult: Result<Portfolio?, Error> = .success(nil)
    var createResult: Result<Portfolio, Error>?
    var updateResult: Result<Portfolio, Error>?
    var deleteResult: Result<Void, Error> = .success(())
    var expandPortfolioResult: Result<Portfolio, Error>?
    var allTransactionsResult: Result<[Transaction], Error> = .success([])
    var transactionsResult: Result<[Transaction], Error> = .success([])

    private(set) var createCalled = false
    private(set) var createCalledWith: Portfolio?
    private(set) var updateCalled = false
    private(set) var updateCalledWith: Portfolio?
    private(set) var deleteCalled = false
    private(set) var deleteCalledWithUserID: UUID?
    private(set) var deleteCalledWithPortfolioID: UUID?

    func allPortfolios(for userID: User.IDValue) async throws -> [Portfolio] {
        try allPortfoliosResult.get()
    }

    func portfolio(for userID: User.IDValue, with id: Portfolio.IDValue) async throws -> Portfolio? {
        try portfolioResult.get()
    }

    func create(_ portfolio: Portfolio) async throws -> Portfolio {
        createCalled = true
        createCalledWith = portfolio
        if let result = createResult {
            return try result.get()
        }
        return portfolio
    }

    func update(_ portfolio: Portfolio) async throws -> Portfolio {
        updateCalled = true
        updateCalledWith = portfolio
        if let result = updateResult {
            return try result.get()
        }
        return portfolio
    }

    func delete(for userID: User.IDValue, with id: Portfolio.IDValue) async throws {
        deleteCalled = true
        deleteCalledWithUserID = userID
        deleteCalledWithPortfolioID = id
        try deleteResult.get()
    }

    func expandPortfolio(on transaction: Transaction) async throws -> Portfolio {
        guard let result = expandPortfolioResult else {
            throw TestError.notImplemented
        }
        return try result.get()
    }

    func allTransactions(for userID: User.IDValue) async throws -> [Transaction] {
        try allTransactionsResult.get()
    }

    func transactions(for userID: User.IDValue, ticker: String) async throws -> [Transaction] {
        try transactionsResult.get()
    }
}

enum TestError: Error {
    case notImplemented
}
