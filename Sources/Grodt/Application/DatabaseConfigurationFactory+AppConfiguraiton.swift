import FluentPostgresDriver

extension DatabaseConfigurationFactory {
    static func postgres(from configuration: AppConfiguration.Postgres) throws -> DatabaseConfigurationFactory {
        return DatabaseConfigurationFactory.postgres(configuration: .init(
            hostname: configuration.hostName,
            port: configuration.port,
            username: configuration.username,
            password: configuration.password,
            database: configuration.databaseName,
            tls: .prefer(try .init(configuration: .clientDefault)))
        )
    }
}
