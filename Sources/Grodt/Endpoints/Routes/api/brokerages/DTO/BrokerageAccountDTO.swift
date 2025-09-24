import Foundation

struct BrokerageAccountDTO: Codable {
    let id: UUID
    let brokerageId: UUID
    let brokerageName: String
    let displayName: String
    let baseCurrency: CurrencyDTO
    let performance: PerformanceDTO
    let transactions: [TransactionDTO]
}
