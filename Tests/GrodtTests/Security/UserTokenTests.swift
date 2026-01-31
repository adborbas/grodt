@testable import Grodt
import Testing
import Foundation

struct UserTokenTests {

    // MARK: - isValid

    @Test func isValid_freshToken_returnsTrue() {
        let token = UserToken(
            id: UUID(),
            value: "test-token-value",
            creationDate: Date(),
            userID: UUID()
        )

        #expect(token.isValid == true)
    }

    @Test func isValid_tokenCreated29DaysAgo_returnsTrue() {
        let twentyNineDaysAgo = Date().addingTimeInterval(-60 * 60 * 24 * 29)
        let token = UserToken(
            id: UUID(),
            value: "test-token-value",
            creationDate: twentyNineDaysAgo,
            userID: UUID()
        )

        #expect(token.isValid == true)
    }

    @Test func isValid_tokenCreated31DaysAgo_returnsFalse() {
        let thirtyOneDaysAgo = Date().addingTimeInterval(-60 * 60 * 24 * 31)
        let token = UserToken(
            id: UUID(),
            value: "test-token-value",
            creationDate: thirtyOneDaysAgo,
            userID: UUID()
        )

        #expect(token.isValid == false)
    }

    @Test func isValid_tokenCreatedExactly30DaysAgo_returnsFalse() {
        let thirtyDaysAgo = Date().addingTimeInterval(-UserToken.tokenTTL)
        let token = UserToken(
            id: UUID(),
            value: "test-token-value",
            creationDate: thirtyDaysAgo,
            userID: UUID()
        )

        // At exactly 30 days, the token should be invalid (creationDate + TTL is not > Date())
        #expect(token.isValid == false)
    }

    @Test func isValid_tokenCreatedJustBefore30Days_returnsTrue() {
        let justBefore30Days = Date().addingTimeInterval(-UserToken.tokenTTL + 1)
        let token = UserToken(
            id: UUID(),
            value: "test-token-value",
            creationDate: justBefore30Days,
            userID: UUID()
        )

        #expect(token.isValid == true)
    }

    // MARK: - tokenTTL

    @Test func tokenTTL_is30Days() {
        let expectedTTL: TimeInterval = 60 * 60 * 24 * 30 // 30 days in seconds

        #expect(UserToken.tokenTTL == expectedTTL)
    }
}
