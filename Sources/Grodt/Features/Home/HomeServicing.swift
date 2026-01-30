import Foundation

protocol HomeServicing: Sendable {
    func home(for userID: User.IDValue) async throws -> HomeResponseDTO
}
