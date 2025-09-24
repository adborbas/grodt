import Foundation

struct BrokerageInfoDTO: ResponseDTO {
    let id: UUID
    let name: String
    let value: Decimal
    let currency: CurrencyDTO
    let accountCount: Int
}
