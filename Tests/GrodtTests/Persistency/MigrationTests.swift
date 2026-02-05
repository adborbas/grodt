@testable import Grodt
import Testing
import Vapor
import Fluent
import FluentSQLiteDriver

@Suite(.serialized) struct MigrationTests {

    @Test func userPreferencesMigration_createsTable() async throws {
        // Given
        let app = try await makeApp(migrations: [
            User.Migration(),
            UserPreferences.CreateMigration()
        ])
        defer { Task { try? await app.asyncShutdown() } }

        let user = try await createUser(on: app.db)
        let preferences = UserPreferences(userID: user.id!, data: .init())

        // When
        try await preferences.save(on: app.db)

        let fetched = try await UserPreferences.query(on: app.db)
            .filter(\.$user.$id == user.id!)
            .first()

        // Then
        #expect(fetched != nil)
        #expect(fetched?.data.isMonthlyEmailEnabled == false)
    }

    @Test func userPreferencesMigration_enforcesUniqueUserConstraint() async throws {
        // Given
        let app = try await makeApp(migrations: [
            User.Migration(),
            UserPreferences.CreateMigration()
        ])
        defer { Task { try? await app.asyncShutdown() } }

        let user = try await createUser(on: app.db)
        try await UserPreferences(userID: user.id!, data: .init()).save(on: app.db)

        // When/Then
        await #expect(throws: (any Error).self) {
            try await UserPreferences(userID: user.id!, data: .init()).save(on: app.db)
        }
    }

    @Test func userSecretMigration_createsTable() async throws {
        // Given
        let app = try await makeApp(migrations: [
            User.Migration(),
            UserSecret.CreateMigration()
        ])
        defer { Task { try? await app.asyncShutdown() } }

        let user = try await createUser(on: app.db)

        // When
        try await UserSecret(userID: user.id!, data: .init()).save(on: app.db)

        let fetched = try await UserSecret.query(on: app.db)
            .filter(\.$user.$id == user.id!)
            .first()

        // Then
        #expect(fetched != nil)
    }

    @Test func userSecretMigration_enforcesUniqueUserConstraint() async throws {
        // Given
        let app = try await makeApp(migrations: [
            User.Migration(),
            UserSecret.CreateMigration()
        ])
        defer { Task { try? await app.asyncShutdown() } }

        let user = try await createUser(on: app.db)
        try await UserSecret(userID: user.id!, data: .init()).save(on: app.db)

        // When/Then
        await #expect(throws: (any Error).self) {
            try await UserSecret(userID: user.id!, data: .init()).save(on: app.db)
        }
    }

    @Test func userSecretMigration_cascadesOnUserDelete() async throws {
        // Given
        let app = try await makeApp(migrations: [
            User.Migration(),
            UserSecret.CreateMigration()
        ])
        defer { Task { try? await app.asyncShutdown() } }

        let user = try await createUser(on: app.db)
        try await UserSecret(userID: user.id!, data: .init()).save(on: app.db)

        // When
        try await user.delete(on: app.db)

        // Then
        let secretCount = try await UserSecret.query(on: app.db).count()
        #expect(secretCount == 0)
    }

    @Test func backfillUserSettings_createsSettingsForExistingUsers() async throws {
        // Given
        let app = try await makeAppWithUserSettingsTables()
        defer { Task { try? await app.asyncShutdown() } }

        let user1 = try await createUser(name: "User1", email: "user1@example.com", on: app.db)
        let user2 = try await createUser(name: "User2", email: "user2@example.com", on: app.db)

        #expect(try await UserPreferences.query(on: app.db).count() == 0)
        #expect(try await UserSecret.query(on: app.db).count() == 0)

        // When
        app.migrations.add(BackfillUserSettings())
        try await app.autoMigrate()

        // Then
        #expect(try await UserPreferences.query(on: app.db).count() == 2)
        #expect(try await UserSecret.query(on: app.db).count() == 2)

        let user1Prefs = try await UserPreferences.query(on: app.db)
            .filter(\.$user.$id == user1.id!)
            .first()
        #expect(user1Prefs != nil)
        #expect(user1Prefs?.data.isMonthlyEmailEnabled == false)

        let user2Secrets = try await UserSecret.query(on: app.db)
            .filter(\.$user.$id == user2.id!)
            .first()
        #expect(user2Secrets != nil)
    }

    @Test func backfillUserSettings_doesNotDuplicateExistingSettings() async throws {
        // Given
        let app = try await makeAppWithUserSettingsTables()
        defer { Task { try? await app.asyncShutdown() } }

        let user = try await createUser(on: app.db)

        try await UserPreferences(
            userID: user.id!,
            data: UserPreferencesPayload(isMonthlyEmailEnabled: true)
        ).save(on: app.db)

        try await UserSecret(
            userID: user.id!,
            data: .init()
        ).save(on: app.db)

        // When
        app.migrations.add(BackfillUserSettings())
        try await app.autoMigrate()

        // Then
        #expect(try await UserPreferences.query(on: app.db).count() == 1)
        #expect(try await UserSecret.query(on: app.db).count() == 1)

        let prefs = try await UserPreferences.query(on: app.db)
            .filter(\.$user.$id == user.id!)
            .first()
        #expect(prefs?.data.isMonthlyEmailEnabled == true)
    }

    @Test func backfillUserSettings_handlesEmptyUserTable() async throws {
        // Given
        let app = try await makeAppWithUserSettingsTables()
        defer { Task { try? await app.asyncShutdown() } }

        // When
        app.migrations.add(BackfillUserSettings())
        try await app.autoMigrate()

        // Then
        #expect(try await UserPreferences.query(on: app.db).count() == 0)
        #expect(try await UserSecret.query(on: app.db).count() == 0)
    }

    @Test func fullMigrationChain_createsAllTablesSuccessfully() async throws {
        // Given
        let app = try await makeApp(migrations: [
            User.Migration(),
            UserPreferences.CreateMigration(),
            UserSecret.CreateMigration(),
            BackfillUserSettings()
        ])
        defer { Task { try? await app.asyncShutdown() } }

        let user = try await createUser(name: "Complete User", email: "complete@example.com", on: app.db)

        // When
        try await UserPreferences(userID: user.id!, data: .init()).save(on: app.db)
        try await UserSecret(userID: user.id!, data: .init()).save(on: app.db)

        try await user.$preferences.load(on: app.db)
        try await user.$secrets.load(on: app.db)

        // Then
        #expect(user.preferences != nil)
        #expect(user.secrets != nil)
    }
}

private func makeApp(migrations: [any Migration]) async throws -> Application {
    let app = try await Application.make(.testing)
    app.logger.logLevel = .critical
    let configuration = SQLiteConfiguration(storage: .memory, enableForeignKeys: true)
    app.databases.use(.sqlite(configuration), as: .sqlite)
    migrations.forEach { app.migrations.add($0) }
    try await app.autoMigrate()
    return app
}

private func makeAppWithUserSettingsTables() async throws -> Application {
    try await makeApp(migrations: [
        User.Migration(),
        UserPreferences.CreateMigration(),
        UserSecret.CreateMigration()
    ])
}

private func createUser(
    name: String = "Test",
    email: String = "test@example.com",
    on db: any Database
) async throws -> User {
    let user = User(name: name, email: email, passwordHash: "hash")
    try await user.save(on: db)
    return user
}
