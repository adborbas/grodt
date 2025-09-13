import Foundation

struct BrokerageDTO: Codable {
    let id: UUID
    let name: String
    let accounts: [BrokerageAccountDTO]
    let totals: PerformanceTotalsDTO?
}

struct BrokerageAccountDTO: Codable {
    let id: UUID
    let brokerageId: UUID
    let brokerageName: String
    let displayName: String
    let baseCurrency: CurrencyDTO
    let totals: PerformanceTotalsDTO?
}

struct PerformanceTotalsDTO: Codable {
    private let value: Decimal
    private let moneyIn: Decimal
    
    init(value: Decimal, moneyIn: Decimal) {
        self.value = value
        self.moneyIn = moneyIn
    }
    
    init() {
        self.init(value: 0, moneyIn: 0)
    }
}

struct PerformancePointDTO: Codable {
    let date: Date
    let value: Decimal
    let moneyIn: Decimal
}
