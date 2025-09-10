import Foundation
import Fluent

protocol PortfolioRepository {
    func allPortfolios(for userID: User.IDValue) async throws -> [Portfolio]
    func portfolio(for userID: User.IDValue, with id: Portfolio.IDValue) async throws -> Portfolio?
    func create(_ portfolio: Portfolio) async throws -> Portfolio
    func update(_ portfolio: Portfolio) async throws -> Portfolio
    func delete(for userID: User.IDValue, with id: Portfolio.IDValue) async throws
    
    func expandPortfolio(on transaction: Transaction) async throws -> Portfolio
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
                portfolio.with(\.$transactions) { transaction in
                    transaction.with(\.$portfolio)
                }
                portfolio.with(\.$historicalDailyPerformance)
            }.first()
        
        guard let user else {
                return []
            }
        return user.portfolios
    }
    
    func portfolio(for userID: User.IDValue, with id: Portfolio.IDValue) async throws -> Portfolio? {
        try await allPortfolios(for: userID)
            .first { $0.id == id }
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
    
    func update(_ portfolio: Portfolio) async throws -> Portfolio {
        try await portfolio.save(on: database)
        
        guard let updatedPortfolio = try await Portfolio.query(on: database)
            .filter(\Portfolio.$id == portfolio.id!)
            .with(\.$transactions)
            .with(\.$historicalDailyPerformance)
            .first() else {
            throw FluentError.noResults
        }
        
        return updatedPortfolio
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
    
    func expandPortfolio(on transaction: Transaction) async throws -> Portfolio {
        let portfolioID = try await transaction.$portfolio.get(on: database).requireID()
        guard let result = try await Portfolio.query(on: database)
            .filter(\.$id == portfolioID)
            .with(\.$transactions)
            .with(\.$historicalDailyPerformance)
            .first()
        else { throw FluentError.noResults }
        return result
    }
}
