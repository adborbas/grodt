import Fluent

struct UserScaffoldMiddleware: AsyncModelMiddleware {
    typealias Model = User

    func create(model: User, on db: Database, next: AnyAsyncModelResponder) async throws {
        try await next.create(model, on: db)

        let userID = try model.requireID()

        let hasPrefs = try await UserPreferences.query(on: db)
            .filter(\.$user.$id == userID)
            .first() != nil
        if !hasPrefs {
            try await UserPreferences(userID: userID, data: .init()).save(on: db)
        }

        let hasSecrets = try await UserSecret.query(on: db)
            .filter(\.$user.$id == userID)
            .first() != nil
        if !hasSecrets {
            try await UserSecret(userID: userID, data: .init()).save(on: db)
        }
    }
}
