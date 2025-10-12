import Foundation
import Fluent

protocol UserRepository {
    func allUsers() async throws -> [User]
    func user(for userID: User.IDValue) async throws -> User?
    func updatePreferences(_ payload: UserPreferencesPayload, for user: User) async throws
}

class PostgresUserRepository: UserRepository {
    let database: Database

    init(database: Database) {
        self.database = database
    }

    private func userQuery() -> QueryBuilder<User> {
        return User.query(on: database)
            .with(\.$portfolios) { portfolio in
                portfolio.with(\.$transactions)
                portfolio.with(\.$historicalDailyPerformance)
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

    func updatePreferences(_ payload: UserPreferencesPayload, for user: User) async throws {
        try await user.$preferences.load(on: database)
        user.preferences!.data = payload
        try await user.preferences!.save(on: database)
    }
}
