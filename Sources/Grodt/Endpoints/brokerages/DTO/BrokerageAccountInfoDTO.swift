import Foundation

struct BrokerageAccountInfoDTO: Codable, Equatable {
    let id: UUID
    let brokerageId: UUID
    let brokerageName: String
    let displayName: String
    let baseCurrency: CurrencyDTO
    let performance: PerformanceDTO
}
