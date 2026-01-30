import Fluent
import Foundation

protocol UserTokenClearing {
    func clearExpiredTokens() async throws
}

class UserTokenClearer: UserTokenClearing {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func clearExpiredTokens() async throws {
        let allTokens = try await UserToken.query(on: database).all()
        let expiredTokens = allTokens.filter { !$0.isValid }
        for token in expiredTokens {
            try await token.delete(on: database)
        }
    }
}
