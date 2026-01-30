@testable import Grodt
import Testing
import Vapor
import Fluent
import Foundation

struct UserAuthenticationTests {

    // MARK: - Password Verification

    @Test func verifyPassword_correctPassword_returnsTrue() throws {
        let password = "securePassword123"
        let hash = try Bcrypt.hash(password)
        let user = User(id: UUID(), name: "Test", email: "test@example.com", passwordHash: hash)

        let result = try user.verify(password: password)

        #expect(result == true)
    }

    @Test func verifyPassword_wrongPassword_returnsFalse() throws {
        let password = "securePassword123"
        let hash = try Bcrypt.hash(password)
        let user = User(id: UUID(), name: "Test", email: "test@example.com", passwordHash: hash)

        let result = try user.verify(password: "wrongPassword")

        #expect(result == false)
    }

    @Test func verifyPassword_emptyPassword_returnsFalse() throws {
        let password = "securePassword123"
        let hash = try Bcrypt.hash(password)
        let user = User(id: UUID(), name: "Test", email: "test@example.com", passwordHash: hash)

        let result = try user.verify(password: "")

        #expect(result == false)
    }

    @Test func verifyPassword_caseSensitive_returnsFalse() throws {
        let password = "SecurePassword123"
        let hash = try Bcrypt.hash(password)
        let user = User(id: UUID(), name: "Test", email: "test@example.com", passwordHash: hash)

        let result = try user.verify(password: "securepassword123")

        #expect(result == false)
    }

    // MARK: - Token Generation

    @Test func generateToken_createsTokenWithCorrectUserID() throws {
        let userID = UUID()
        let user = User(id: userID, name: "Test", email: "test@example.com", passwordHash: "hash")

        let token = try user.generateToken()

        #expect(token.$user.id == userID)
    }

    @Test func generateToken_createsTokenWithCurrentDate() throws {
        let user = User(id: UUID(), name: "Test", email: "test@example.com", passwordHash: "hash")
        let beforeGeneration = Date()

        let token = try user.generateToken()

        let afterGeneration = Date()
        #expect(token.creationDate >= beforeGeneration)
        #expect(token.creationDate <= afterGeneration)
    }

    @Test func generateToken_createsUniqueTokenValues() throws {
        let user = User(id: UUID(), name: "Test", email: "test@example.com", passwordHash: "hash")

        let token1 = try user.generateToken()
        let token2 = try user.generateToken()

        #expect(token1.value != token2.value)
    }

    @Test func generateToken_tokenValueIsBase64Encoded() throws {
        let user = User(id: UUID(), name: "Test", email: "test@example.com", passwordHash: "hash")

        let token = try user.generateToken()

        // Base64 string should be decodable
        let decoded = Data(base64Encoded: token.value)
        #expect(decoded != nil)
        #expect(decoded?.count == 16) // 16 random bytes
    }

    @Test func generateToken_createsValidToken() throws {
        let user = User(id: UUID(), name: "Test", email: "test@example.com", passwordHash: "hash")

        let token = try user.generateToken()

        #expect(token.isValid == true)
    }

    @Test func generateToken_withoutUserID_throws() throws {
        let user = User(name: "Test", email: "test@example.com", passwordHash: "hash")
        // User without ID should throw when generating token

        #expect(throws: FluentError.self) {
            _ = try user.generateToken()
        }
    }
}
