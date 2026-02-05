import Foundation
import Fluent

protocol UserRepository {
    func allUsers(with: Set<UserExpansion>) async throws -> [User]
    func user(for userID: User.IDValue, with: Set<UserExpansion>) async throws -> User?
    @discardableResult
    func setMonthlyEmailEnabled(_ enabled: Bool, for user: User) async throws -> UserPreferences
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
    private let secretsEncryptor: SecretsEncrypting

    init(database: Database, secretsEncryptor: SecretsEncrypting) {
        self.database = database
        self.secretsEncryptor = secretsEncryptor
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

    @discardableResult
    func setMonthlyEmailEnabled(_ enabled: Bool, for user: User) async throws -> UserPreferences {
        try await user.$preferences.load(on: database)
        user.preferences!.data.isMonthlyEmailEnabled = enabled
        try await user.preferences!.save(on: database)
        return user.preferences!
    }
}
