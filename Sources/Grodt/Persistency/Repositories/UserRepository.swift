import Foundation
import Fluent

protocol UserRepository {
    func allUsers(with: Set<UserExpansion>) async throws -> [User]
    func user(for userID: User.IDValue, with: Set<UserExpansion>) async throws -> User?
    func setMonthlyEmailConfig(_ config: UserPreferencesPayload.MonthlyEmailConfig, for user: User) async throws
    func setMailjetApiSecret(_ secret: String?, for user: User) async throws
}

extension UserRepository {
    func allUsers() async throws -> [User] { try await allUsers(with: []) }
    func user(for userID: User.IDValue) async throws -> User? { try await user(for: userID, with: []) }
}

enum UserExpansion {
    case portfolio, preferences, secrets
}

class PostgresUserRepository: UserRepository {
    private let database: Database

    init(database: Database) {
        self.database = database
    }

    private func userQuery(with: Set<UserExpansion> = []) -> QueryBuilder<User> {
        var query = User.query(on: database)

        if with.contains(.portfolio) {
            query = query.with(\.$portfolios) { portfolio in
                portfolio.with(\.$transactions)
                portfolio.with(\.$historicalDailyPerformance)
            }
        }
        if with.contains(.preferences) {
            query = query.with(\.$preferences)
        }
        if with.contains(.secrets) {
            query = query.with(\.$secrets)
        }

        return query
    }

    func allUsers(with: Set<UserExpansion> = []) async throws -> [User] {
        return try await userQuery(with: with).all()
    }

    func user(for userID: User.IDValue, with: Set<UserExpansion> = []) async throws -> User? {
        return try await userQuery(with: with)
            .filter(\.$id == userID)
            .first()
    }

    func setMonthlyEmailConfig(_ config: UserPreferencesPayload.MonthlyEmailConfig, for user: User) async throws {
        try await user.$preferences.load(on: database)
        user.preferences!.data.monthlyEmail = config
        try await user.preferences!.save(on: database)
    }

    func setMailjetApiSecret(_ secret: String?, for user: User) async throws {
        try await user.$secrets.load(on: database)
        user.secrets!.data.mailjetApiSecret = secret
        try await user.secrets!.save(on: database)
    }
}
