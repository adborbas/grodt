import Foundation

struct BrokerageDTO: Codable {
    let id: UUID
    let name: String
    let accounts: [BrokerageAccountInfoDTO]
    let performance: PerformanceDTO
}
