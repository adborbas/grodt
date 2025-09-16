import Foundation

struct BrokerageDTO: Codable {
    let id: UUID
    let name: String
    let accounts: [BrokerageAccountDTO]
    let performance: PerformanceDTO
}
