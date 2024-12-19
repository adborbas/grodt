import Vapor
import FluentSQLiteDriver

public func configure(_ app: Application) async throws {
    app.routes.caseInsensitive = true
    
    switch app.environment {
    case .testing:
        let configuration = SQLiteConfiguration(storage: .memory, enableForeignKeys: false)
        app.databases.use(.sqlite(configuration), as: .sqlite)
    default:
        if let port = app.config.port {
            app.http.server.configuration.port = port
        }
        try app.databases.use(DatabaseConfigurationFactory.postgres(from: app.config.postgres), as: .psql)
        try app.queues.use(.redis(from: app.config.redis))
    }
    
    try await routes(app)
    try migrations(app)
    
    //    try await app.autoRevert()
    try await app.autoMigrate()
}
