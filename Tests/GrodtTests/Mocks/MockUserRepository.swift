@testable import Grodt
import Foundation

final class MockUserRepository: UserRepository, @unchecked Sendable {
    var userResult: Result<User?, Error> = .success(nil)
    var allUsersResult: Result<[User], Error> = .success([])
    var setMonthlyEmailEnabledResult: Result<UserPreferences, Error> = .success(UserPreferences.stub())

    private(set) var setMonthlyEmailEnabledCalled = false
    private(set) var setMonthlyEmailEnabledCalledWith: Bool?

    func allUsers(with: Set<UserExpansion>) async throws -> [User] {
        try allUsersResult.get()
    }

    func user(for userID: User.IDValue, with expansions: Set<UserExpansion>) async throws -> User? {
        try userResult.get()
    }

    @discardableResult
    func setMonthlyEmailEnabled(_ enabled: Bool, for user: User) async throws -> UserPreferences {
        setMonthlyEmailEnabledCalled = true
        setMonthlyEmailEnabledCalledWith = enabled
        return try setMonthlyEmailEnabledResult.get()
    }
}
