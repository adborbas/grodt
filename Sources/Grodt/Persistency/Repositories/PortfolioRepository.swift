import Foundation
import Fluent

protocol PortfolioRepository {
    func allPortfolios(for userID: User.IDValue) async throws -> [Portfolio]
    func portfolio(for userID: User.IDValue, with id: Portfolio.IDValue) async throws -> Portfolio?
    func create(_ portfolio: Portfolio) async throws -> Portfolio
    func delete(for userID: User.IDValue, with id: Portfolio.IDValue) async throws
    func historicalPerformance(with id: Portfolio.IDValue) async throws -> HistoricalPortfolioPerformance
    func updateHistoricalPerformance(_ historicalPerformance: HistoricalPortfolioPerformance) async throws
}

class PostgresPortfolioRepository: PortfolioRepository {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func allPortfolios(for userID: User.IDValue) async throws -> [Portfolio] {
        let user = try await User.query(on: database)
            .filter(\User.$id == userID)
            .with(\.$portfolios) { portfolio in
                portfolio.with(\.$transactions)
            }.first()
        
        guard let user else {
                return []
            }
        return user.portfolios
    }
    
    func portfolio(for userID: User.IDValue, with id: Portfolio.IDValue) async throws -> Portfolio? {
        try await allPortfolios(for: userID)
            .first { $0.id == id }!
    }
    
    func create(_ portfolio: Portfolio) async throws -> Portfolio {
        try await portfolio.save(on: database)
        
        guard let portfolioWithTransactions = try await Portfolio.query(on: database)
            .filter(\Portfolio.$id == portfolio.id!)
            .with(\.$transactions)
            .first() else {
            throw FluentError.noResults
        }
        
        return portfolioWithTransactions
    }
    
    func delete(for userID: User.IDValue, with id: Portfolio.IDValue) async throws {
        guard let portfolio = try await self.portfolio(for: userID, with: id) else {
            throw FluentError.noResults
        }
        
        try await portfolio.transactions.concurrentForEach { transaction in
            try await transaction.delete(on: self.database)
        }
        
        try await portfolio.delete(on: database)
    }
    
    func historicalPerformance(with id: Portfolio.IDValue) async throws -> HistoricalPortfolioPerformance {
        guard let portfolioWithPerformance = try await Portfolio.query(on: database)
            .filter(\Portfolio.$id == id)
            .with(\.$historicalPerformance)
            .first() else {
            throw FluentError.noResults
        }
        
        return portfolioWithPerformance.$historicalPerformance.wrappedValue ?? HistoricalPortfolioPerformance(portfolioID: id, datedPerformance: [])
    }
    
    func updateHistoricalPerformance(_ historicalPerformance: HistoricalPortfolioPerformance) async throws {
        try await historicalPerformance.update(on: database)
    }
}
