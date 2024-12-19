import Vapor
import QueuesRedisDriver

extension Application.Queues.Provider {
    static func redis(from configuration: AppConfiguration.Redis) throws -> Self {
        let redisConfiguration = try RedisConfiguration(
            hostname: configuration.hostName,
            password: configuration.password,
            pool: .init(maximumConnectionCount: .maximumActiveConnections(configuration.maximumActiveConnections))
        )
        return .redis(redisConfiguration)
    }
}
