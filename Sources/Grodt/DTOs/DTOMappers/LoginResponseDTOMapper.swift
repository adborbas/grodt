import Foundation

class LoginResponseDTOMapper {
    func response(from userToken: UserToken) -> LoginResponseDTO {
        return LoginResponseDTO(value: userToken.value)
    }
}
