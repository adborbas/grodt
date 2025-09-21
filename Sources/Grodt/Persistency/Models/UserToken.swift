import Fluent
import Vapor

final class UserToken: Model, Content, @unchecked Sendable {
    static let schema = Keys.schema

    @ID(key: .id)
    var id: UUID?

    @Field(key: Keys.value)
    var value: String
    
    @Field(key: Keys.creationDate)
    var creationDate: Date

    @Parent(key: Keys.userID)
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, creationDate: Date,  userID: User.IDValue) {
        self.id = id
        self.value = value
        self.creationDate = creationDate
        self.$user.id = userID
    }
}

fileprivate extension UserToken {
    enum Keys {
        static let schema = "user_tokens"
        
        static let value: FieldKey = "value"
        static let creationDate: FieldKey = "creation_date"
        static let userID: FieldKey = "user_id"
    }
}

extension UserToken {
    struct Migration: AsyncMigration {
        var name: String { "CreateUserToken" }

        func prepare(on database: Database) async throws {
            try await database.schema(Keys.schema)
                .id()
                .field(Keys.value, .string, .required)
                .field(Keys.creationDate, .datetime, .required)
                .field(Keys.userID, .uuid, .required, .references("users", "id"))
                .unique(on: Keys.value)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Keys.schema).delete()
        }
    }
}

extension UserToken: ModelTokenAuthenticatable {
    static let tokenTTL: TimeInterval = 60 * 60 * 24 * 30 // 30 days
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user

    var isValid: Bool {
        return creationDate.addingTimeInterval(UserToken.tokenTTL) > Date()
    }
}

extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            creationDate: Date(),
            userID: self.requireID()
        )
    }
}
