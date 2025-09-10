import Foundation

struct YearMonthDayDate: Codable, Equatable, Hashable, Comparable {
    private(set) var date: Date
    
    init() {
        self.init(Date())
    }
    
    init(_ date: Date) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.universalGMT
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.date = calendar.date(from: components)!
    }
    
    static func == (lhs: YearMonthDayDate, rhs: YearMonthDayDate) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.universalGMT
        let lhsComponents = calendar.dateComponents([.year, .month, .day], from: lhs.date)
        let rhsComponents = calendar.dateComponents([.year, .month, .day], from: rhs.date)
        return lhsComponents.year == rhsComponents.year &&
        lhsComponents.month == rhsComponents.month &&
        lhsComponents.day == rhsComponents.day
    }
    
    static func < (lhs: YearMonthDayDate, rhs: YearMonthDayDate) -> Bool {
        return lhs.date < rhs.date
    }
    
    static func days(from start: YearMonthDayDate, to end: YearMonthDayDate) -> [YearMonthDayDate] {
        guard end >= start else { return [] }

        var result: [YearMonthDayDate] = []
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.universalGMT

        var cursor = start.date
        let endDate = end.date

        while cursor <= endDate {
            result.append(YearMonthDayDate(cursor))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }

        return result
    }
}
