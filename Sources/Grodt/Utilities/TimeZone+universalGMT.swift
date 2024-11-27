import Foundation

extension TimeZone {
    public static var universalGMT: TimeZone {
        return TimeZone(secondsFromGMT: 0)!
    }
}
