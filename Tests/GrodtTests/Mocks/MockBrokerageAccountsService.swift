@testable import Grodt
import Vapor

final class MockBrokerageAccountsService: BrokerageAccountsServicing, @unchecked Sendable {
    var allAccountsResult: Result<[BrokerageAccountInfoDTO], Error> = .success([])
    var detailResult: Result<BrokerageAccountDTO, Error> = .success(BrokerageAccountDTO.stub())
    var updateResult: Result<HTTPStatus, Error> = .success(.ok)
    var deleteResult: Result<HTTPStatus, Error> = .success(.noContent)
    var createResult: Result<BrokerageAccountDTO, Error> = .success(BrokerageAccountDTO.stub())

    func allAccounts(for userID: User.IDValue) async throws -> [BrokerageAccountInfoDTO] {
        try allAccountsResult.get()
    }

    func detail(for id: UUID, userID: User.IDValue) async throws -> BrokerageAccountDTO {
        try detailResult.get()
    }

    func update(id: UUID, displayName: String, userID: User.IDValue) async throws -> HTTPStatus {
        try updateResult.get()
    }

    func delete(id: UUID, userID: User.IDValue) async throws -> HTTPStatus {
        try deleteResult.get()
    }

    func create(_ request: CreateBrokerageAccountDTO, on brokerageID: Brokerage.IDValue, for userID: User.IDValue) async throws -> BrokerageAccountDTO {
        try createResult.get()
    }
}
