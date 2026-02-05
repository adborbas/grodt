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

    var isMonthlyEmailEnabled: Bool

    init(isMonthlyEmailEnabled: Bool = false) {
        self.isMonthlyEmailEnabled = isMonthlyEmailEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Support both old nested format and new flat format for backwards compatibility
        if let nested = try? container.nestedContainer(keyedBy: MonthlyEmailKeys.self, forKey: .monthlyEmail) {
            self.isMonthlyEmailEnabled = try nested.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        } else {
            self.isMonthlyEmailEnabled = try container.decodeIfPresent(Bool.self, forKey: .isMonthlyEmailEnabled) ?? false
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isMonthlyEmailEnabled, forKey: .isMonthlyEmailEnabled)
    }

    private enum CodingKeys: String, CodingKey {
        case monthlyEmail
        case isMonthlyEmailEnabled
    }

    private enum MonthlyEmailKeys: String, CodingKey {
        case isEnabled
    }
}
