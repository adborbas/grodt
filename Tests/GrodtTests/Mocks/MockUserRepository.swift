@testable import Grodt
import Foundation

final class MockUserRepository: UserRepository, @unchecked Sendable {
    var userResult: Result<User?, Error> = .success(nil)
    var allUsersResult: Result<[User], Error> = .success([])
    var setMonthlyEmailConfigResult: Result<UserPreferences, Error> = .success(UserPreferences.stub())

    private(set) var setMonthlyEmailConfigCalled = false
    private(set) var setMonthlyEmailConfigCalledWith: UserPreferencesPayload.MonthlyEmailConfig?

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
}
