import Foundation

struct DatedPerformanceDTOMapper {
    func performancePoint(from enity: DatedPerformance) -> DatedPerformanceDTO {
        let moneyIn = enity.moneyIn
        let moneyOut = enity.value
        let profit = moneyOut - moneyIn
        let totalReturn: Decimal = moneyIn > 0 ? (profit / moneyIn).rounded(to: 2) : 0
        
        return DatedPerformanceDTO(date: enity.date.date,
                                   moneyIn: moneyIn,
                                   moneyOut: moneyOut,
                                   profit: profit,
                                   totalReturn: totalReturn)
    }
}
