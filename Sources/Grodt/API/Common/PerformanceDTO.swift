import Foundation

struct PerformanceDTO: Codable, Equatable {
    let invested: Decimal
    let currentValue: Decimal
    let profit: Decimal
    let totalReturn: Decimal

    static var zero: PerformanceDTO {
        return .init(
            invested: 0,
            currentValue: 0,
            profit: 0,
            totalReturn: 0
        )
    }
}
