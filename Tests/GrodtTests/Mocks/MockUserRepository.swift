@testable import Grodt
import Foundation

final class MockUserRepository: UserRepository, @unchecked Sendable {
    var userResult: Result<User?, Error> = .success(nil)
    var allUsersResult: Result<[User], Error> = .success([])
    var setMonthlyEmailConfigResult: Result<UserPreferences, Error> = .success(UserPreferences.stub())
    var setMailjetApiSecretResult: Result<Void, Error> = .success(())
    var getMailjetApiSecretResult: Result<String?, Error> = .success(nil)
    var findByEmailResult: Result<User?, Error> = .success(nil)
    var updateNameResult: Result<Void, Error> = .success(())
    var updateEmailResult: Result<Void, Error> = .success(())
    var updatePasswordHashResult: Result<Void, Error> = .success(())
    var deleteAllTokensResult: Result<Void, Error> = .success(())

    private(set) var setMonthlyEmailConfigCalled = false
    private(set) var setMonthlyEmailConfigCalledWith: UserPreferencesPayload.MonthlyEmailConfig?
    private(set) var setMailjetApiSecretCalled = false
    private(set) var setMailjetApiSecretCalledWith: String?
    private(set) var updateNameCalled = false
    private(set) var updateNameCalledWith: String?
    private(set) var updateEmailCalled = false
    private(set) var updateEmailCalledWith: String?
    private(set) var updatePasswordHashCalled = false
    private(set) var deleteAllTokensCalled = false
    private(set) var deleteAllTokensCalledWith: User.IDValue?

    func allUsers(with: Set<UserExpansion>) async throws -> [User] {
        try allUsersResult.get()
    }

    func user(for userID: User.IDValue, with expansions: Set<UserExpansion>) async throws -> User? {
        try userResult.get()
    }

    @discardableResult
    func setMonthlyEmailConfig(_ config: UserPreferencesPayload.MonthlyEmailConfig, for user: User) async throws -> UserPreferences {
        setMonthlyEmailConfigCalled = true
        setMonthlyEmailConfigCalledWith = config
        return try setMonthlyEmailConfigResult.get()
    }

    func setMailjetApiSecret(_ secret: String?, for user: User) async throws {
        setMailjetApiSecretCalled = true
        setMailjetApiSecretCalledWith = secret
        try setMailjetApiSecretResult.get()
    }

    func getMailjetApiSecret(for user: User) async throws -> String? {
        try getMailjetApiSecretResult.get()
    }

    func findByEmail(_ email: String) async throws -> User? {
        try findByEmailResult.get()
    }

    func updateName(_ name: String, for user: User) async throws {
        updateNameCalled = true
        updateNameCalledWith = name
        try updateNameResult.get()
    }

    func updateEmail(_ email: String, for user: User) async throws {
        updateEmailCalled = true
        updateEmailCalledWith = email
        try updateEmailResult.get()
    }

    func updatePasswordHash(_ passwordHash: String, for user: User) async throws {
        updatePasswordHashCalled = true
        try updatePasswordHashResult.get()
    }

    func deleteAllTokens(for userID: User.IDValue) async throws {
        deleteAllTokensCalled = true
        deleteAllTokensCalledWith = userID
        try deleteAllTokensResult.get()
    }
}
