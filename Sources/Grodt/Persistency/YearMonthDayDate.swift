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
}
