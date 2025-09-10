import Foundation
import Fluent
import SQLKit

protocol DailyPerformanceRepository: Sendable {
    associatedtype OwnerID: Sendable
    
    func replaceSeries(for ownerID: OwnerID, with points: [DatedPortfolioPerformance]) async throws
    func upsert(points: [DatedPortfolioPerformance], for ownerID: OwnerID) async throws
    func readSeries(for ownerID: OwnerID, from: YearMonthDayDate?, to: YearMonthDayDate?) async throws -> [DatedPortfolioPerformance]
    func deleteAll(for ownerID: OwnerID) async throws
}
