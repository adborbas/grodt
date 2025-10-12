import Fluent
import Foundation

final class UserPreference: Model, @unchecked Sendable {
    static let schema = "user_preferences"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: Keys.userID)
    var user: User

    @Field(key: Keys.data)
    var data: UserPreferencesPayload

    @Timestamp(key: Keys.createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: Keys.updatedAt, on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, userID: User.IDValue, data: UserPreferencesPayload = .init()) {
        self.id = id
        self.$user.id = userID
        self.data = data
    }
}

fileprivate extension UserPreference {
    enum Keys {
        static let userID: FieldKey = "user_id"
        static let data: FieldKey = "data"
        static let createdAt: FieldKey = "created_at"
        static let updatedAt: FieldKey = "updated_at"
    }
}


extension UserPreference {
    struct CreateMigration: AsyncMigration {
        var name: String { "CreateUserPreference" }

        func prepare(on db: Database) async throws {
            try await db.schema(UserPreference.schema)
                .id()
                .field(UserPreference.Keys.userID, .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
                .field(UserPreference.Keys.data, .json, .required)
                .field(UserPreference.Keys.createdAt, .datetime)
                .field(UserPreference.Keys.updatedAt, .datetime)
                .unique(on: UserPreference.Keys.userID)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(UserPreference.schema).delete()
        }
    }
}

struct UserPreferencesPayload: Codable {
    struct MailjetPreferences: Codable {
        let senderEmail: String
        let senderName: String
    }

    let isTransactionsBackupEnabled: Bool
    let mailjetPreferences: MailjetPreferences?

    init(isTransactionsBackupEnabled: Bool = false,
         mailjetPreferences: MailjetPreferences? = nil) {
        self.isTransactionsBackupEnabled = isTransactionsBackupEnabled
        self.mailjetPreferences = mailjetPreferences
    }
}
