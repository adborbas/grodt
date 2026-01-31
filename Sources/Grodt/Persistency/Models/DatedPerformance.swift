import Foundation

struct DatedPerformance: Codable, Equatable {
    let invested: Decimal
    let realized: Decimal
    let currentValue: Decimal
    let date: YearMonthDayDate

    init(invested: Decimal, realized: Decimal = 0, currentValue: Decimal, date: YearMonthDayDate) {
        self.invested = invested
        self.realized = realized
        self.currentValue = currentValue
        self.date = date
    }

    /// Total value including realized gains
    var totalValue: Decimal {
        currentValue + realized
    }

    /// Profit = currentValue + realized - invested
    var profit: Decimal {
        currentValue + realized - invested
    }

    /// Return as decimal (e.g., 0.15 for 15%)
    var totalReturn: Decimal {
        guard invested > 0 else { return 0 }
        return (profit / invested).rounded(to: 2)
    }
}
