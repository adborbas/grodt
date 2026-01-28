struct UserDetailDTO: ResponseDTO {
    let name: String
    let email: String
    let preferences: UserPreferencesDTO
}
