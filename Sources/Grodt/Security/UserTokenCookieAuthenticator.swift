import Vapor
import Fluent

struct UserTokenCookieAuthenticator: AsyncRequestAuthenticator {
    static let tokenName = "auth_token"
    
    typealias User = Grodt.User

    func authenticate(request: Request) async throws {
        guard let raw = request.cookies[Self.tokenName]?.string, !raw.isEmpty else {
            return
        }
        if let userToken = try await UserToken.query(on: request.db)
            .filter(\.$value == raw)
            .with(\.$user)
            .first(),
           userToken.isValid {
            request.auth.login(userToken.user)
        }
    }
}
