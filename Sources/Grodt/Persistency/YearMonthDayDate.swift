import Foundation

struct YearMonthDayDate: Codable, Equatable, Hashable {
    private var date: Date
    
    init(_ date: Date) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.date = calendar.date(from: components)!
    }
    
//    func toDate() -> Date {
//        return date
//    }
}
