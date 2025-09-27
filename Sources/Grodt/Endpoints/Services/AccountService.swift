import Foundation
import Vapor

class AccountService {
    private let userRepository: UserRepository
    private let userDataMapper: UserDTOMapper
    
    init(userRepository: UserRepository, userDataMapper: UserDTOMapper) {
        self.userRepository = userRepository
        self.userDataMapper = userDataMapper
    }
    
    func userInfo(for userID: UUID) async throws -> UserInfoDTO {
        guard let user = try await userRepository.user(for: userID) else {
            throw Abort(.notFound)
        }
        
        return userDataMapper.userInfo(from: user)
    }
}
