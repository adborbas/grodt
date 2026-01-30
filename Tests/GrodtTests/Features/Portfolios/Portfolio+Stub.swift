@testable import Grodt
import Foundation

extension Portfolio {
    static func stub(
        id: UUID = UUID(),
        userID: UUID = UUID(),
        name: String = "Test Portfolio",
        currency: Currency = .stub()
    ) -> Portfolio {
        Portfolio(id: id, userID: userID, name: name, currency: currency)
    }
}

extension CreatePortfolioRequestDTO {
    static func stub(
        name: String = "Test Portfolio",
        currency: String = "USD"
    ) -> CreatePortfolioRequestDTO {
        CreatePortfolioRequestDTO(name: name, currency: currency)
    }
}
