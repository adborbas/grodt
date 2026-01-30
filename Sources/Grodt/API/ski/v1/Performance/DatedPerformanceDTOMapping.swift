import Foundation

protocol DatedPerformanceDTOMapping: Sendable {
    func performancePoint(from datedPerformance: DatedPerformance) -> DatedPerformanceDTO
}

extension DatedPerformanceDTOMapper: DatedPerformanceDTOMapping { }
