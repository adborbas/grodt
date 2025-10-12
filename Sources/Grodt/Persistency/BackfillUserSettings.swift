import Fluent

struct BackfillUserSettings: AsyncMigration {
    var name: String { "BackfillUserSettings" }

    func prepare(on db: Database) async throws {
        let users = try await User.query(on: db).all()

        for user in users {
            guard let userID = user.id else { continue }

            let hasPrefs = try await UserPreference.query(on: db)
                .filter(\.$user.$id == userID)
                .first() != nil
            if !hasPrefs {
                try await UserPreference(userID: userID, data: .init()).save(on: db)
            }

            let hasSecrets = try await UserSecret.query(on: db)
                .filter(\.$user.$id == userID)
                .first() != nil
            if !hasSecrets {
                try await UserSecret(userID: userID, data: .init()).save(on: db)
            }
        }
    }

    func revert(on db: Database) async throws {
        // No-op: this migration only adds missing rows.
    }
}
