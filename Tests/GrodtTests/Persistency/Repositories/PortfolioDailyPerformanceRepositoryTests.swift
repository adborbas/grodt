@testable import Grodt
import Fluent
import FluentSQLiteDriver
import Testing
import Vapor

struct PortfolioDailyPerformanceRepositoryTests {

    @Test func batchUpsert_persistsPoints() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let portfolio = try await createPortfolio(on: app.db)
        let sut = PostgresPortfolioDailyPerformanceRepository(db: app.db)

        let points = [
            DatedPerformance(invested: 100, realized: 0, currentValue: 110, date: YearMonthDayDate(date(2025, 1, 1))),
            DatedPerformance(invested: 200, realized: 10, currentValue: 220, date: YearMonthDayDate(date(2025, 1, 2))),
        ]

        try await sut.batchUpsert(points: points, for: portfolio.id!)

        let result = try await sut.readSeries(for: portfolio.id!, from: nil, to: nil)
        #expect(result.count == 2)
        #expect(result[0].invested == 100)
        #expect(result[0].currentValue == 110)
        #expect(result[1].invested == 200)
        #expect(result[1].realized == 10)
    }

    @Test func batchUpsert_updatesExistingOnConflict() async throws {
        let app = try await makeApp()
        defer { Task { try? await app.asyncShutdown() } }

        let portfolio = try await createPortfolio(on: app.db)
        let sut = PostgresPortfolioDailyPerformanceRepository(db: app.db)

        let initialPoints = [
            DatedPerformance(invested: 100, realized: 0, currentValue: 110, date: YearMonthDayDate(date(2025, 1, 1))),
        ]
        try await sut.batchUpsert(points: initialPoints, for: portfolio.id!)

        let updatedPoints = [
            DatedPerformance(invested: 500, realized: 50, currentValue: 600, date: YearMonthDayDate(date(2025, 1, 1))),
        ]
        try await sut.batchUpsert(points: updatedPoints, for: portfolio.id!)

        let result = try await sut.readSeries(for: portfolio.id!, from: nil, to: nil)
        #expect(result.count == 1)
        #expect(result[0].invested == 500)
        #expect(result[0].realized == 50)
        #expect(result[0].currentValue == 600)
    }
}

private func makeApp() async throws -> Application {
    let app = try await Application.make(.testing)
    app.logger.logLevel = .critical
    let configuration = SQLiteConfiguration(storage: .memory, enableForeignKeys: true)
    app.databases.use(.sqlite(configuration), as: .sqlite)
    let migrations: [any Migration] = [
        User.Migration(),
        Portfolio.Migration(),
        HistoricalPortfolioPerformanceDaily.Migration(),
    ]
    migrations.forEach { app.migrations.add($0) }
    try await app.autoMigrate()
    return app
}

private func createPortfolio(on db: Database) async throws -> Portfolio {
    let user = User(name: "Test", email: "test@example.com", passwordHash: "hash")
    try await user.save(on: db)
    let portfolio = Portfolio(userID: user.id!, name: "Test", currency: .stub())
    try await portfolio.save(on: db)
    return portfolio
}

private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    return calendar.date(from: DateComponents(year: year, month: month, day: day))!
}
