import Fluent
import Vapor

final class User: Model, Content, @unchecked Sendable {
    static let schema = Keys.schema
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: Keys.name)
    var name: String
    
    @Field(key: Keys.email)
    var email: String
    
    @Field(key: Keys.passwordHash)
    var passwordHash: String
    
    @Children(for: \.$user)
    var portfolios: [Portfolio]

    @OptionalChild(for: \.$user)
    var preferences: UserPreferences?

    @OptionalChild(for: \.$user)
    var secrets: UserSecret?

    init() { }
    
    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}

fileprivate extension User {
    enum Keys {
        static let schema = "users"
        
        static let name: FieldKey = "name"
        static let email: FieldKey = "email"
        static let passwordHash: FieldKey = "password_hash"
    }
}

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }

        func prepare(on database: Database) async throws {
            try await database.schema(Keys.schema)
                .id()
                .field(Keys.name, .string, .required)
                .field(Keys.email, .string, .required)
                .field(Keys.passwordHash, .string, .required)
                .unique(on: Keys.email)
                .create()
        }

        func revert(on database: Database) async throws {
            try await database.schema(Keys.schema).delete()
        }
    }

    struct CreatePreconfiguredUserMigration: AsyncMigration {
        private let preconfigured: User?
        private let logger: Logger

        init(preconfigured: User? = nil, logger: Logger) {
            self.preconfigured = preconfigured
            self.logger = logger
        }

        var name: String { "CreatePreconfiguredUser" }

        func prepare(on database: Database) async throws {
            guard let preconfigured = preconfigured else {
                logger.info("No preconfigured user created.")
                return
            }

            let existingUser = try await User.query(on: database)
                .filter(\.$email == preconfigured.email)
                .first()

            if existingUser != nil {
                logger.info("Preconfigured user already exists: \(preconfigured.email)")
            } else {
                logger.info("Creating preconfigured user: \(preconfigured.email)")
                try await preconfigured.save(on: database)
            }
        }

        func revert(on database: Database) async throws {
            // No-op: we don't want to delete users on rollback
        }
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User {

    var requiredPreferences: UserPreferencesPayload {
        return preferences!.data
    }

    var requiredSecrets: UserSecretsPayload {
        return secrets!.data
    }
}
