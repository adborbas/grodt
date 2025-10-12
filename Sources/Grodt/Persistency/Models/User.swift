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
    var preferences: UserPreference?

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
        private let preconfigured: User?
        private let logger: Logger
        
        init(preconfigured: User? = nil, logger: Logger) {
            self.preconfigured = preconfigured
            self.logger = logger
        }
        
        var name: String { "CreateUser" }
        
        func prepare(on database: Database) async throws {
            try await database.schema(Keys.schema)
                .id()
                .field(Keys.name, .string, .required)
                .field(Keys.email, .string, .required)
                .field(Keys.passwordHash, .string, .required)
                .unique(on: Keys.email)
                .create()
            
            if let preconfigured = preconfigured {
                logger.info("Creating preconfigured user: \(preconfigured.email)")
                try await preconfigured.save(on: database)
            } else {
                logger.info("No preconfigured created.")
            }
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Keys.schema).delete()
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

    func requirePreferences(on db: Database) async throws -> UserPreferencesPayload {
        try await self.$preferences.load(on: db)
        return self.preferences!.data
    }

    func requireSecrets(on db: Database) async throws -> UserSecretsPayload {
        try await self.$secrets.load(on: db)
        return self.secrets!.data
    }
}
