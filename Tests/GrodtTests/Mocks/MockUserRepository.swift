@testable import Grodt
import Foundation

final class MockUserRepository: UserRepository, @unchecked Sendable {
    var userResult: Result<User?, Error> = .success(nil)
    var allUsersResult: Result<[User], Error> = .success([])
    var setMonthlyEmailConfigResult: Result<UserPreferences, Error> = .success(UserPreferences.stub())
    var setMailjetApiSecretResult: Result<Void, Error> = .success(())
    var getMailjetApiSecretResult: Result<String?, Error> = .success(nil)

    private(set) var setMonthlyEmailConfigCalled = false
    private(set) var setMonthlyEmailConfigCalledWith: UserPreferencesPayload.MonthlyEmailConfig?
    private(set) var setMailjetApiSecretCalled = false
    private(set) var setMailjetApiSecretCalledWith: String?

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
}
