import Fluent
import Vapor

struct SeedDevelopmentData: AsyncMigration {
    var name: String { "SeedDevelopmentData" }

    func prepare(on db: Database) async throws {
        // Get the preconfigured user
        guard let user = try await User.query(on: db)
            .filter(\.$email == "test@grodt.com")
            .first() else {
            return
        }

        guard let userID = user.id else { return }

        // Check if data already exists (for idempotency)
        let existingBrokerageCount = try await Brokerage.query(on: db)
            .filter(\.$user.$id == userID)
            .count()

        if existingBrokerageCount > 0 {
            // Data already seeded
            return
        }

        // Get existing currencies (created by Currency.Migration)
        guard let usd = try await Currency.query(on: db)
            .filter(\.$code == "USD")
            .first() else {
            return
        }

        // Create sample brokerages
        let interactiveBrokers = Brokerage(userID: userID, name: "Interactive Brokers")
        try await interactiveBrokers.save(on: db)

        let fidelity = Brokerage(userID: userID, name: "Fidelity")
        try await fidelity.save(on: db)

        // Create sample brokerage accounts
        let ibAccount1 = BrokerageAccount(
            brokerageID: try interactiveBrokers.requireID(),
            displayName: "Main Trading Account",
            baseCurrency: usd
        )
        try await ibAccount1.save(on: db)

        let ibAccount2 = BrokerageAccount(
            brokerageID: try interactiveBrokers.requireID(),
            displayName: "Retirement Account",
            baseCurrency: usd
        )
        try await ibAccount2.save(on: db)

        let fidelityAccount = BrokerageAccount(
            brokerageID: try fidelity.requireID(),
            displayName: "Investment Account",
            baseCurrency: usd
        )
        try await fidelityAccount.save(on: db)

        // Create sample portfolio
        let portfolio = Portfolio(userID: userID, name: "My Portfolio", currency: usd)
        try await portfolio.save(on: db)

        // Create sample transactions
        let transactions = [
            Transaction(
                portfolioID: try portfolio.requireID(),
                brokerageAccountID: try ibAccount1.requireID(),
                type: .buy,
                transactionDate: Date().addingTimeInterval(-86400 * 365), // 1 year ago
                ticker: "AAPL",
                currency: usd,
                fees: Decimal(9.99),
                numberOfShares: Decimal(10),
                pricePerShare: Decimal(150.00)
            ),
            Transaction(
                portfolioID: try portfolio.requireID(),
                brokerageAccountID: try ibAccount1.requireID(),
                type: .buy,
                transactionDate: Date().addingTimeInterval(-86400 * 180), // 6 months ago
                ticker: "MSFT",
                currency: usd,
                fees: Decimal(9.99),
                numberOfShares: Decimal(5),
                pricePerShare: Decimal(300.00)
            ),
            Transaction(
                portfolioID: try portfolio.requireID(),
                brokerageAccountID: try ibAccount2.requireID(),
                type: .buy,
                transactionDate: Date().addingTimeInterval(-86400 * 90), // 3 months ago
                ticker: "GOOGL",
                currency: usd,
                fees: Decimal(9.99),
                numberOfShares: Decimal(3),
                pricePerShare: Decimal(2800.00)
            ),
            Transaction(
                portfolioID: try portfolio.requireID(),
                brokerageAccountID: try fidelityAccount.requireID(),
                type: .buy,
                transactionDate: Date().addingTimeInterval(-86400 * 30), // 1 month ago
                ticker: "TSLA",
                currency: usd,
                fees: Decimal(9.99),
                numberOfShares: Decimal(8),
                pricePerShare: Decimal(220.00)
            ),
            Transaction(
                portfolioID: try portfolio.requireID(),
                brokerageAccountID: try fidelityAccount.requireID(),
                type: .buy,
                transactionDate: Date().addingTimeInterval(-86400 * 7), // 1 week ago
                ticker: "NVDA",
                currency: usd,
                fees: Decimal(9.99),
                numberOfShares: Decimal(2),
                pricePerShare: Decimal(500.00)
            )
        ]

        for transaction in transactions {
            try await transaction.save(on: db)
        }
    }

    func revert(on db: Database) async throws {
        // No-op: we don't want to delete seed data on rollback
        // The data will be cleared when the entire database is reset
    }
}
