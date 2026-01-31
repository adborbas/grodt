@testable import Grodt
import Foundation

extension User {
    static func stub(
        id: UUID = UUID(),
        name: String = "Test User",
        email: String = "test@example.com",
        passwordHash: String = "hashed_password"
    ) -> User {
        User(id: id, name: name, email: email, passwordHash: passwordHash)
    }
}

extension UserPreferences {
    static func stub(
        id: UUID = UUID(),
        userID: UUID = UUID(),
        data: UserPreferencesPayload = UserPreferencesPayload()
    ) -> UserPreferences {
        UserPreferences(id: id, userID: userID, data: data)
    }
}
