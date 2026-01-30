@testable import Grodt
import Foundation

final class MockDatedPerformanceDTOMapper: DatedPerformanceDTOMapping, @unchecked Sendable {
    var performancePointResult: DatedPerformanceDTO = DatedPerformanceDTO(date: Date(), moneyIn: 0, moneyOut: 0, profit: 0, totalReturn: 0)

    func performancePoint(from datedPerformance: DatedPerformance) -> DatedPerformanceDTO {
        performancePointResult
    }
}
