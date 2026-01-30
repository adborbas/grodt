@testable import Grodt
import Foundation

final class MockDatedPerformanceDTOMapper: DatedPerformanceDTOMapping, @unchecked Sendable {
    var performancePointResult: DatedPerformanceDTO = DatedPerformanceDTO(date: Date(), invested: 0, currentValue: 0, profit: 0, totalReturn: 0)

    func performancePoint(from datedPerformance: DatedPerformance) -> DatedPerformanceDTO {
        performancePointResult
    }
}
