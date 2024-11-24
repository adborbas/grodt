import Foundation
import Fluent

protocol UserRepository {
    func allUsers() async throws -> [User]
    func user(for userID: User.IDValue) async throws -> User?
    
}

class PostgresUserRepository: UserRepository {
    private let database: Database

    init(database: Database) {
        self.database = database
    }

    private func userQuery() -> QueryBuilder<User> {
        return User.query(on: database)
            .with(\.$portfolios) { portfolio in
                portfolio.with(\.$transactions)
                portfolio.with(\.$historicalPerformance)
            }
    }

    func allUsers() async throws -> [User] {
        return try await userQuery().all()
    }

    func user(for userID: User.IDValue) async throws -> User? {
        return try await userQuery()
            .filter(\.$id == userID)
            .first()
    }
}
