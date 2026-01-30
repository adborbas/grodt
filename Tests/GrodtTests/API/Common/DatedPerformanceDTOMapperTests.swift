@testable import Grodt
import Testing
import Foundation

struct DatedPerformanceDTOMapperTests {

    let mapper = DatedPerformanceDTOMapper()

    // MARK: - Profit Calculation

    @Test func performancePoint_withPositiveProfit_calculatesCorrectly() {
        let performance = DatedPerformance(
            moneyIn: 1000,
            value: 1500,
            date: YearMonthDayDate()
        )

        let dto = mapper.performancePoint(from: performance)

        #expect(dto.moneyIn == 1000)
        #expect(dto.moneyOut == 1500)
        #expect(dto.profit == 500)
    }

    @Test func performancePoint_withNegativeProfit_calculatesCorrectly() {
        let performance = DatedPerformance(
            moneyIn: 1000,
            value: 800,
            date: YearMonthDayDate()
        )

        let dto = mapper.performancePoint(from: performance)

        #expect(dto.moneyIn == 1000)
        #expect(dto.moneyOut == 800)
        #expect(dto.profit == -200)
    }

    @Test func performancePoint_withZeroProfit_calculatesCorrectly() {
        let performance = DatedPerformance(
            moneyIn: 1000,
            value: 1000,
            date: YearMonthDayDate()
        )

        let dto = mapper.performancePoint(from: performance)

        #expect(dto.profit == 0)
    }

    // MARK: - Total Return Calculation

    @Test func performancePoint_totalReturn_calculatesPercentageCorrectly() {
        let performance = DatedPerformance(
            moneyIn: 1000,
            value: 1100,
            date: YearMonthDayDate()
        )

        let dto = mapper.performancePoint(from: performance)

        // 100 profit / 1000 invested = 0.10 (10%)
        #expect(dto.totalReturn == Decimal(string: "0.1")!)
    }

    @Test func performancePoint_totalReturn_roundsToTwoDecimalPlaces() {
        let performance = DatedPerformance(
            moneyIn: 1000,
            value: 1333,
            date: YearMonthDayDate()
        )

        let dto = mapper.performancePoint(from: performance)

        // 333 / 1000 = 0.333... should round to 0.33
        #expect(dto.totalReturn == Decimal(string: "0.33")!)
    }

    @Test func performancePoint_totalReturn_withZeroMoneyIn_returnsZero() {
        let performance = DatedPerformance(
            moneyIn: 0,
            value: 100,
            date: YearMonthDayDate()
        )

        let dto = mapper.performancePoint(from: performance)

        // Avoid division by zero
        #expect(dto.totalReturn == 0)
    }

    @Test func performancePoint_totalReturn_withNegativeReturn_calculatesCorrectly() {
        let performance = DatedPerformance(
            moneyIn: 1000,
            value: 750,
            date: YearMonthDayDate()
        )

        let dto = mapper.performancePoint(from: performance)

        // -250 / 1000 = -0.25 (-25%)
        #expect(dto.totalReturn == Decimal(string: "-0.25")!)
    }

    // MARK: - Date Mapping

    @Test func performancePoint_mapsDateCorrectly() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "GMT")!
        let dateComponents = DateComponents(year: 2024, month: 6, day: 15)
        let specificDate = calendar.date(from: dateComponents)!
        let date = YearMonthDayDate(specificDate)
        let performance = DatedPerformance(
            moneyIn: 1000,
            value: 1000,
            date: date
        )

        let dto = mapper.performancePoint(from: performance)

        #expect(dto.date == date.date)
    }

    // MARK: - Edge Cases

    @Test func performancePoint_withLargeNumbers_calculatesCorrectly() {
        let performance = DatedPerformance(
            moneyIn: Decimal(string: "1000000000")!, // 1 billion
            value: Decimal(string: "1500000000")!,   // 1.5 billion
            date: YearMonthDayDate()
        )

        let dto = mapper.performancePoint(from: performance)

        #expect(dto.profit == Decimal(string: "500000000")!)
        #expect(dto.totalReturn == Decimal(string: "0.5")!)
    }

    @Test func performancePoint_withSmallDecimals_calculatesCorrectly() {
        let performance = DatedPerformance(
            moneyIn: Decimal(string: "100.50")!,
            value: Decimal(string: "110.75")!,
            date: YearMonthDayDate()
        )

        let dto = mapper.performancePoint(from: performance)

        #expect(dto.profit == Decimal(string: "10.25")!)
    }
}
