import Foundation

struct BrokerageDTO: Codable {
    let id: UUID
    let name: String
    let accounts: [BrokerageAccountDTO]
    let performance: PerformanceDTO
}

struct BrokerageAccountDTO: Codable {
    let id: UUID
    let brokerageId: UUID
    let brokerageName: String
    let displayName: String
    let baseCurrency: CurrencyDTO
    let performance: PerformanceDTO
}

struct PerformancePointDTO: Codable {
    let date: Date
    let value: Decimal
    let moneyIn: Decimal
}
