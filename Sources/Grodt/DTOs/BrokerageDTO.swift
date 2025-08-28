import Foundation

struct BrokerageDTO: Codable {
    let id: UUID
    let name: String
    let accountsCount: Int
    let totals: PerformanceTotalsDTO?
}

struct BrokerageAccountDTO: Codable {
    let id: UUID
    let brokerageId: UUID
    let brokerageName: String
    let displayName: String
    let baseCurrency: Currency
    let totals: PerformanceTotalsDTO?
}

struct PerformanceTotalsDTO: Codable {
    let value: Decimal
    let moneyIn: Decimal
}

struct PerformancePointDTO: Codable {
    let date: Date
    let value: Decimal
    let moneyIn: Decimal
}
