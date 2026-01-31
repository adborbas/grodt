import Foundation
import Vapor

protocol BrokerageAccountsServicing: Sendable {
    func allAccounts(for userID: User.IDValue) async throws -> [BrokerageAccountInfoDTO]
    func detail(for id: UUID, userID: User.IDValue) async throws -> BrokerageAccountDTO
    func update(id: UUID, displayName: String, userID: User.IDValue) async throws -> HTTPStatus
    func delete(id: UUID, userID: User.IDValue) async throws -> HTTPStatus
    func create(_ request: CreateBrokerageAccountDTO, on brokerageID: Brokerage.IDValue, for userID: User.IDValue) async throws -> BrokerageAccountDTO
}
