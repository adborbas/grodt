@testable import Grodt
import Foundation

extension BrokerageAccountDTO {
    static func stub(
        id: UUID = UUID(),
        brokerageId: UUID = UUID(),
        brokerageName: String = "Test Brokerage",
        displayName: String = "Test Account",
        baseCurrency: CurrencyDTO = CurrencyDTO(code: "EUR", symbol: "€"),
        performance: PerformanceDTO = .zero,
        transactions: [TransactionDTO] = [],
        historicalPerformance: PerformanceTimeSeriesDTO = PerformanceTimeSeriesDTO(values: [])
    ) -> BrokerageAccountDTO {
        BrokerageAccountDTO(
            id: id,
            brokerageId: brokerageId,
            brokerageName: brokerageName,
            displayName: displayName,
            baseCurrency: baseCurrency,
            performance: performance,
            transactions: transactions,
            historicalPerformance: historicalPerformance
        )
    }
}

extension BrokerageAccountInfoDTO {
    static func stub(
        id: UUID = UUID(),
        brokerageId: UUID = UUID(),
        brokerageName: String = "Test Brokerage",
        displayName: String = "Test Account",
        baseCurrency: CurrencyDTO = CurrencyDTO(code: "EUR", symbol: "€"),
        performance: PerformanceDTO = .zero
    ) -> BrokerageAccountInfoDTO {
        BrokerageAccountInfoDTO(
            id: id,
            brokerageId: brokerageId,
            brokerageName: brokerageName,
            displayName: displayName,
            baseCurrency: baseCurrency,
            performance: performance
        )
    }
}
