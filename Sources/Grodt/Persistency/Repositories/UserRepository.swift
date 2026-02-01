import Foundation
import Fluent

protocol UserRepository {
    func allUsers(with: Set<UserExpansion>) async throws -> [User]
    func user(for userID: User.IDValue, with: Set<UserExpansion>) async throws -> User?
    func findByEmail(_ email: String) async throws -> User?
    @discardableResult
    func setMonthlyEmailConfig(_ config: UserPreferencesPayload.MonthlyEmailConfig, for user: User) async throws -> UserPreferences
    func setMailjetApiSecret(_ secret: String?, for user: User) async throws
    func getMailjetApiSecret(for user: User) async throws -> String?

    // Profile updates
    func updateName(_ name: String, for user: User) async throws
    func updateEmail(_ email: String, for user: User) async throws
    func updatePasswordHash(_ passwordHash: String, for user: User) async throws
    func deleteAllTokens(for userID: User.IDValue) async throws
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
    func setMonthlyEmailConfig(_ config: UserPreferencesPayload.MonthlyEmailConfig, for user: User) async throws -> UserPreferences {
        try await user.$preferences.load(on: database)
        user.preferences!.data.monthlyEmail = config
        try await user.preferences!.save(on: database)
        return user.preferences!
    }

    func setMailjetApiSecret(_ secret: String?, for user: User) async throws {
        try await user.$secrets.load(on: database)
        let encryptedSecret = try secret.map { try secretsEncryptor.encrypt($0) }
        user.secrets!.data.mailjetApiSecret = encryptedSecret
        try await user.secrets!.save(on: database)
    }

    func getMailjetApiSecret(for user: User) async throws -> String? {
        try await user.$secrets.load(on: database)
        guard let encryptedSecret = user.secrets?.data.mailjetApiSecret else {
            return nil
        }
        return try secretsEncryptor.decrypt(encryptedSecret)
    }

    func findByEmail(_ email: String) async throws -> User? {
        return try await User.query(on: database)
            .filter(\.$email == email)
            .first()
    }

    func updateName(_ name: String, for user: User) async throws {
        user.name = name
        try await user.save(on: database)
    }

    func updateEmail(_ email: String, for user: User) async throws {
        user.email = email
        try await user.save(on: database)
    }

    func updatePasswordHash(_ passwordHash: String, for user: User) async throws {
        user.passwordHash = passwordHash
        try await user.save(on: database)
    }

    func deleteAllTokens(for userID: User.IDValue) async throws {
        try await UserToken.query(on: database)
            .filter(\.$user.$id == userID)
            .delete()
    }
}
