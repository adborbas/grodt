@testable import Grodt
import Vapor

struct TestAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        guard bearer.token == "test-token" else { return }
        let user = User(name: "Test User", email: "test@example.com", passwordHash: "")
        user.id = UUID()
        request.auth.login(user)
    }
}
