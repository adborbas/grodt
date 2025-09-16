import Foundation

struct PerformanceDTO: Codable, Equatable {
    let moneyIn: Decimal
    let moneyOut: Decimal
    let profit: Decimal
    let totalReturn: Decimal
    
    static var zero: PerformanceDTO {
        return .init(
            moneyIn: 0,
            moneyOut: 0,
            profit: 0,
            totalReturn: 0
        )
    }
}
