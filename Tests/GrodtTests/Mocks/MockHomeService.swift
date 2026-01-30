@testable import Grodt
import Vapor

final class MockHomeService: HomeServicing, @unchecked Sendable {
    var homeResult: Result<HomeResponseDTO, Error> = .success(HomeResponseDTO.stub())

    func home(for userID: User.IDValue) async throws -> HomeResponseDTO {
        try homeResult.get()
    }
}
