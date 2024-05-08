import Vapor

struct AppConfiguration {
    struct Postgres {
        @RequiredEnvironmentVariable(key: "DATABASE_HOSTNAME")
        var hostName: String
        
        @RequiredEnvironmentVariable(key: "DATABASE_USERNAME")
        var username: String
        
        @RequiredEnvironmentVariable(key: "DATABASE_PASSWORD")
        var password: String
        
        @RequiredEnvironmentVariable(key: "DATABASE_DBNAME")
        var databaseName: String
        
        @RequiredEnvironmentVariable(key: "DATABASE_PORT")
        var port: Int
        
        fileprivate init() { }
    }
    
    struct PreconfiguredUser {
        @OptionalEnvironmentVariable(key: "DEFAULT_USER_NAME")
        var name: String?
        
        @OptionalEnvironmentVariable(key: "DEFAULT_USER_EMAIL")
        var email: String?
        
        @OptionalEnvironmentVariable(key: "DEFAULT_USER_PASSWORD")
        var password: String?
    }
    
    private let app: Application
    let postgres = Postgres()
    
    @OptionalEnvironmentVariable(key: "PORT")
    var port: Int?
    
    var preconfiguredUser: User? {
        let valuesFromConfig = PreconfiguredUser()
        guard let name = valuesFromConfig.name,
              let email = valuesFromConfig.email,
              let password = valuesFromConfig.password else { return nil }
        
        return try? User(name: name, email: email, passwordHash: Bcrypt.hash(password))
    }
    
    fileprivate init(app: Application) {
        self.app = app
    }
    
    func alphavantageAPIKey() async throws -> String {
        guard let alphavantageAPIKey = try await Environment.secret(path: ".alphavantagekey",
                                                                    fileIO: app.fileio,
                                                                    on: app.eventLoopGroup.next()).get() else {
            if app.environment == .testing {
                return ""
            }
            fatalError("Required `.alphavantagekey` secret file is missing.")
        }
        return alphavantageAPIKey
    }
}

extension Application {
    struct AppConfigurationKey: StorageKey {
        typealias Value = AppConfiguration
    }
    
    var config: AppConfiguration {
        get {
            storage[AppConfigurationKey.self] ?? AppConfiguration(app: self)
        }
        set {
            storage[AppConfigurationKey.self] = newValue
        }
    }
}
