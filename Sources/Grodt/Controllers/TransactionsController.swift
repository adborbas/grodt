import Vapor

protocol TransactionsControllerDelegate: AnyObject {
    func transactionCreated(_ transaction: Transaction) async throws
    func transactionDeleted(_ transaction: Transaction) async throws
}

class HistoricalPortfolioPerformanceUpdater: TransactionsControllerDelegate {
    private let portfolioRepository: PortfolioRepository
    private let quoteRepository: QuoteRepository
    private let dataMapper: PortfolioDTOMapper
    private let performanceCalculator: PortfolioPerformanceCalculating
    
    init(portfolioRepository: PortfolioRepository,
         quoteRepository: QuoteRepository,
         performanceCalculator: PortfolioPerformanceCalculating,
         dataMapper: PortfolioDTOMapper) {
        self.portfolioRepository = portfolioRepository
        self.quoteRepository = quoteRepository
        self.performanceCalculator = performanceCalculator
        self.dataMapper = dataMapper
    }
    
    func transactionCreated(_ transaction: Transaction) async throws {
        let portfolio = try await portfolioRepository.expandPortfolio(on: transaction)
        try await recalculateHistoricalPerformance(of: portfolio)
    }
    
    func transactionDeleted(_ transaction: Transaction) async throws {
        let portfolio = try await portfolioRepository.expandPortfolio(on: transaction)
        try await recalculateHistoricalPerformance(of: portfolio)
    }
    
    private func recalculateHistoricalPerformance(of portfolio: Portfolio) async throws {
        var datedPerformance = [DatedPortfolioPerformance]()
        guard let earliestTransaction = portfolio.earliestTransaction else { return }
        let dates = dateRangeUntilToday(from: earliestTransaction.purchaseDate)
        
        for date in dates {
            let performanceForDate = try await performanceCalculator.performance(of: portfolio, on: date)
            datedPerformance.append(performanceForDate)
        }
        
        if let perf = portfolio.historicalPerformance {
            perf.datedPerformance = datedPerformance
            try await portfolioRepository.updateHistoricalPerformance(perf)
        } else {
            let historicalPerformance = HistoricalPortfolioPerformance(portfolioID: portfolio.id!, datedPerformance: datedPerformance)
            try await portfolioRepository.createHistoricalPerformance(historicalPerformance)
        }
    }
    
    private func dateRangeUntilToday(from startDate: Date) -> [YearMonthDayDate] {
        var dates: [YearMonthDayDate] = []
        var currentDate = startDate
        let calendar = Calendar.current
        let today = Date()
        
        while currentDate <= today {
            let ymdDate = YearMonthDayDate(currentDate)
            dates.append(ymdDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
}

class TransactionsController: RouteCollection {
    private let transactionsRepository: TransactionsRepository
    private let currencyRepository: CurrencyRepository
    private let dataMapper: TransactionDTOMapper
    var delegate: TransactionsControllerDelegate? // TODO: Weak
    
    init(transactionsRepository: TransactionsRepository,
         currencyRepository: CurrencyRepository,
         dataMapper: TransactionDTOMapper) {
        self.transactionsRepository = transactionsRepository
        self.currencyRepository = currencyRepository
        self.dataMapper = dataMapper
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let transactions = routes.grouped("transactions")
        transactions.post(use: create)
        
        transactions.group(":id") { transaction in
            transaction.get(use: transactionDetail)
            transaction.delete(use: delete)
        }
    }
    
    func create(req: Request) async throws -> TransactionDTO {
        let transaction = try req.content.decode(CreateTransactionRequestDTO.self)
        guard let currency = try await currencyRepository.currency(for: transaction.currency) else {
            throw Abort(.badRequest)
        }
        
        let newTransaction = Transaction(portfolioID: UUID(uuidString: transaction.portfolio)!,
                                         platform: transaction.platform,
                                         account: transaction.account,
                                         purchaseDate: transaction.purchaseDate,
                                         ticker: transaction.ticker,
                                         currency: currency,
                                         fees: transaction.fees,
                                         numberOfShares: transaction.numberOfShares,
                                         pricePerShareAtPurchase: transaction.pricePerShare)
        
        try await newTransaction.save(on: req.db)
        try await delegate?.transactionCreated(newTransaction)
        return dataMapper.transaction(from: newTransaction)
    }
    
    func transactionDetail(req: Request) async throws -> TransactionDTO {
        let id = try req.requiredID()
        
        guard let transaction = try await transactionsRepository.transaction(for: id) else {
            throw Abort(.notFound)
        }
        return dataMapper.transaction(from: transaction)
    }
    
    
    func delete(req: Request) async throws -> HTTPStatus {
        let id = try req.requiredID()
        
        guard let transaction = try await transactionsRepository.transaction(for: id) else {
            throw Abort(.notFound)
        }
        
        try await transaction.delete(on: req.db)
        try await delegate?.transactionDeleted(transaction)
        return .ok
    }
}

extension TransactionDTO: Content { }
