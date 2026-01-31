import Foundation
import Fluent
import SQLKit

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

protocol DailyPerformanceRepository: Sendable {
    associatedtype OwnerID: Sendable

    func replaceSeries(for ownerID: OwnerID, with points: [DatedPerformance]) async throws
    func upsert(points: [DatedPerformance], for ownerID: OwnerID) async throws
    func readSeries(for ownerID: OwnerID, from: YearMonthDayDate?, to: YearMonthDayDate?) async throws -> [DatedPerformance]
    func deleteAll(for ownerID: OwnerID) async throws

    /// Batch upsert using SQL ON CONFLICT for efficiency
    func batchUpsert(points: [DatedPerformance], for ownerID: OwnerID) async throws

    /// Delete all records from a specific date onwards
    func deleteFrom(date: YearMonthDayDate, for ownerID: OwnerID) async throws
}
