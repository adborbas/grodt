import Fluent
import Vapor

final class UserSecret: Model, @unchecked Sendable {
    static let schema = "user_secrets"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: Keys.userID)
    var user: User

    @Field(key: Keys.data)
    var data: UserSecretsPayload

    @Timestamp(key: Keys.createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: Keys.updatedAt, on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, userID: User.IDValue, data: UserSecretsPayload = .init()) {
        self.id = id
        self.$user.id = userID
        self.data = data
    }
}

fileprivate extension UserSecret {
    enum Keys {
        static let userID: FieldKey = "user_id"
        static let data: FieldKey = "data"
        static let createdAt: FieldKey = "created_at"
        static let updatedAt: FieldKey = "updated_at"
    }
}

extension UserSecret {
    struct CreateMigration: AsyncMigration {
        var name: String { "CreateUserSecret" }

        func prepare(on db: Database) async throws {
            try await db.schema(UserSecret.schema)
                .id()
                .field(UserSecret.Keys.userID, .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
                .field(UserSecret.Keys.data, .json, .required)
                .field(UserSecret.Keys.createdAt, .datetime)
                .field(UserSecret.Keys.updatedAt, .datetime)
                .unique(on: UserSecret.Keys.userID)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(UserSecret.schema).delete()
        }
    }
}

struct UserSecretsPayload: Codable {
    var mailjetApiSecret: String?

    init(mailjetApiSecret: String? = nil) {
        self.mailjetApiSecret = mailjetApiSecret
    }
}
