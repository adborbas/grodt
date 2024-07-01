import Vapor

protocol TransactionsControllerDelegate: AnyObject {
    func transactionCreated(_ transaction: Transaction) async throws
}

class HistoricalPortfolioPerformanceUpdater: TransactionsControllerDelegate {
    private let portfolioRepository: PortfolioRepository
    private let quoteRepository: QuoteRepository
    private let dataMapper: PortfolioDTOMapper
    private let priceService: PriceService
    
    init(portfolioRepository: PortfolioRepository,
         quoteRepository: QuoteRepository,
         priceService: PriceService,
         dataMapper: PortfolioDTOMapper) {
        self.portfolioRepository = portfolioRepository
        self.quoteRepository = quoteRepository
        self.priceService = priceService
        self.dataMapper = dataMapper
    }
    
    func transactionCreated(_ transaction: Transaction) async throws {
        let currentPerformances = try await portfolioRepository.historicalPerformance(with: transaction.portfolio.id!)
        let indexOfExistingPerformance = currentPerformances.datedPerformance.firstIndex { perf in perf.date == YearMonthDayDate(transaction.purchaseDate) }
        
        // compute performance of transaction
            // money_in = transaction.pricePerShareAtPurchase * transaction.numberOfShares + fees
            // money_out; if date today ? money_in MARK AS NEED UPDATE : get quote for ticker and compute performance
        
        
        // !!!need to update all values since transaction and today!!!!
        let moneyIn = transaction.totalCost
        let currentValue = moneyIn
        
        if let indexOfExistingPerformance = indexOfExistingPerformance {
            let oldPerformance = currentPerformances.datedPerformance[indexOfExistingPerformance]
            let newPerformance = DatedPortfolioPerformance(moneyIn: oldPerformance.moneyIn + moneyIn,
                                                           value: oldPerformance.value + currentValue,
                                                           date: oldPerformance.date)
            
            currentPerformances.datedPerformance[indexOfExistingPerformance] = newPerformance
            try await portfolioRepository.updateHistoricalPerformance(currentPerformances)
        } else {
            let newPerformance = DatedPortfolioPerformance(moneyIn: moneyIn,
                                                           value: currentValue,
                                                           date: YearMonthDayDate(transaction.purchaseDate))
            currentPerformances.datedPerformance.append(newPerformance)
            try await portfolioRepository.updateHistoricalPerformance(currentPerformances)
        }
    }
    
    func recalculateHistoricalPerformance(of portfolio: Portfolio) async throws {
        var datedPerformance = [DatedPortfolioPerformance]()
        guard let earliestTransaction = portfolio.earliestTransaction else { return }
        let dates = dateRangeUntilToday(from: earliestTransaction.purchaseDate)
        dates.forEach { datedPerformance.append(portfolioPerformance(for: $0)) }
        
        portfolio.historicalPerformance?.datedPerformance = datedPerformance
        try await portfolioRepository.updateHistoricalPerformance(portfolio.historicalPerformance!)
    }
    
    private func portfolioPerformance(for date: YearMonthDayDate) -> DatedPortfolioPerformance {
        port
        
//        let  = portfolio.transactions.grouped { YearMonthDayDate($0.purchaseDate) }
//        transactionsByDate.forEach { (date: YearMonthDayDate, transactions: [Transaction]) in
//            var moneyIn: Decimal = 0
//            var value: Decimal = 0
//            transactions.forEach { transaction in
//                moneyIn += transaction.totalCost
//                value += priceService.historicalPrice(for: transaction.ticker, on: tr)
//            }
//        }
    }
    
    private func dateRangeUntilToday(from startDate: Date) -> [YearMonthDayDate] {
        var dates: [YearMonthDayDate] = []
        var currentDate = startDate
        let today = Date()
        let calendar = Calendar.current
        
        while currentDate <= today {
            let ymdDate = YearMonthDayDate(currentDate)
            dates.append(ymdDate)
            // Increment by one day
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dates
    }
}

struct TransactionsController: RouteCollection {
    private let transactionsRepository: TransactionsRepository
    private let currencyRepository: CurrencyRepository
    private let dataMapper: TransactionDTOMapper
    weak var delegate: TransactionsControllerDelegate?
    
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
        return .ok
    }
}

extension TransactionDTO: Content { }
