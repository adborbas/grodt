import Vapor
import AlphaSwiftage

func routes(_ app: Application) async throws {
    let container = try await buildAppContainer(app)
    installGlobalMiddleware(app)
    try registerLoginRoutes(app, container)
    try registerSkiRoutes(app, container)
    try scheduleNightlyJobs(app, container)
}
