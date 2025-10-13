import Fluent
import Foundation

final class UserPreferences: Model, @unchecked Sendable {
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

fileprivate extension UserPreferences {
    enum Keys {
        static let userID: FieldKey = "user_id"
        static let data: FieldKey = "data"
        static let createdAt: FieldKey = "created_at"
        static let updatedAt: FieldKey = "updated_at"
    }
}


extension UserPreferences {
    struct CreateMigration: AsyncMigration {
        var name: String { "CreateUserPreferences" }

        func prepare(on db: Database) async throws {
            try await db.schema(UserPreferences.schema)
                .id()
                .field(UserPreferences.Keys.userID, .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
                .field(UserPreferences.Keys.data, .json, .required)
                .field(UserPreferences.Keys.createdAt, .datetime)
                .field(UserPreferences.Keys.updatedAt, .datetime)
                .unique(on: UserPreferences.Keys.userID)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(UserPreferences.schema).delete()
        }
    }
}

struct UserPreferencesPayload: Codable {

    struct TransactionsBackup: Codable {
        struct MailjetConfiguration: Codable {
            let senderEmail: String
            let senderName: String
            let apiKey: String
        }

        let isEnabled: Bool
        let configuration: MailjetConfiguration?

        init(isEnabled: Bool,
             configuration: MailjetConfiguration?) {
            self.isEnabled = isEnabled
            self.configuration = configuration
        }
    }

    var transactionBackup: TransactionsBackup

    init() {
        self.transactionBackup = TransactionsBackup(isEnabled: false, configuration: nil)
    }

    init(transactionBackup: TransactionsBackup) {
        self.transactionBackup = transactionBackup
    }
}
