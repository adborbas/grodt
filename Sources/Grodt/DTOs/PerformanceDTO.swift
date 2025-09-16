import Foundation

struct PerformanceDTO: Codable, Equatable {
    let moneyIn: Decimal
    let moneyOut: Decimal
    let profit: Decimal
    let totalReturn: Decimal
}
