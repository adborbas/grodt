@testable import Grodt
import Foundation

extension Brokerage {
    static func stub(
        id: UUID = UUID(),
        userID: UUID = UUID(),
        name: String = "Test Brokerage"
    ) -> Brokerage {
        Brokerage(id: id, userID: userID, name: name)
    }
}
