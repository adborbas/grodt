@testable import Grodt
import Foundation

extension BrokerageAccount {
    static func stub(
        id: UUID = UUID(),
        brokerageID: UUID = UUID(),
        displayName: String = "Test Account",
        baseCurrency: Currency = .stub()
    ) -> BrokerageAccount {
        BrokerageAccount(
            id: id,
            brokerageID: brokerageID,
            displayName: displayName,
            baseCurrency: baseCurrency
        )
    }
}
