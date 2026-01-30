import Foundation

struct DatedPerformanceDTOMapper {
    func performancePoint(from entity: DatedPerformance) -> DatedPerformanceDTO {
        return DatedPerformanceDTO(
            date: entity.date.date,
            invested: entity.invested,
            currentValue: entity.currentValue,
            profit: entity.profit,
            totalReturn: entity.totalReturn
        )
    }
}
