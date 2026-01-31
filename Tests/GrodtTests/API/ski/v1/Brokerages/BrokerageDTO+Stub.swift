@testable import Grodt
import Foundation

extension BrokerageDTO {
    static func stub(
        id: UUID = UUID(),
        name: String = "Test Brokerage",
        accounts: [BrokerageAccountInfoDTO] = [],
        performance: PerformanceDTO = .zero,
        historicalPerformance: PerformanceTimeSeriesDTO = PerformanceTimeSeriesDTO(values: [])
    ) -> BrokerageDTO {
        BrokerageDTO(
            id: id,
            name: name,
            accounts: accounts,
            performance: performance,
            historicalPerformance: historicalPerformance
        )
    }
}
