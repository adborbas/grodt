import Foundation
import Fluent
import SQLKit

protocol DailyPerformanceRepository: Sendable {
    associatedtype OwnerID: Sendable
    
    func replaceSeries(for ownerID: OwnerID, with points: [DatedPerformance]) async throws
    func upsert(points: [DatedPerformance], for ownerID: OwnerID) async throws
    func readSeries(for ownerID: OwnerID, from: YearMonthDayDate?, to: YearMonthDayDate?) async throws -> [DatedPerformance]
    func deleteAll(for ownerID: OwnerID) async throws
}
