@testable import Grodt
import Foundation

final class MockBrokerageDTOMapper: BrokerageDTOMapping, @unchecked Sendable {
    var brokerageResult: Result<BrokerageDTO, Error> = .success(BrokerageDTO.stub())

    func brokerage(from brokerage: Brokerage) async throws -> BrokerageDTO {
        try brokerageResult.get()
    }
}
