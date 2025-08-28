import Foundation
import Fluent

final class Brokerage: Model, @unchecked Sendable {
    static let schema = "brokerages"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: Keys.userID)
    var user: User

    @Field(key: Keys.name)
    var name: String

    @Timestamp(key: Keys.createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: Keys.updatedAt, on: .update)
    var updatedAt: Date?

    @Children(for: \.$brokerage)
    var accounts: [BrokerageAccount]

    init() {}

    init(id: UUID? = nil,
         userID: User.IDValue,
         name: String)
    {
        self.id = id
        self.$user.id = userID
        self.name = name
    }
}

extension Brokerage {
    enum Keys {
        static let userID: FieldKey = "user_id"
        static let name: FieldKey = "name"
        static let createdAt: FieldKey = "created_at"
        static let updatedAt: FieldKey = "updated_at"
    }

    struct Migration: AsyncMigration {
        let name = "CreateBrokerage"

        func prepare(on db: Database) async throws {
            try await db.schema(Brokerage.schema)
                .id()
                .field(Keys.userID, .uuid, .required, .references(User.schema, "id", onDelete: .cascade))
                .field(Keys.name, .string, .required)
                .field(Keys.createdAt, .datetime)
                .field(Keys.updatedAt, .datetime)
                .unique(on: Keys.userID, Keys.name)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(Brokerage.schema).delete()
        }
    }
}
