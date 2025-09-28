class UserDTOMapper {
    func userInfo(from user: User) -> UserInfoDTO {
        return UserInfoDTO(name: user.name, email: user.email)
    }
}
