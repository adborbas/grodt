import Vapor

struct UpdatePasswordDTO: Content, Validatable {
    let currentPassword: String
    let newPassword: String

    static func validations(_ validations: inout Validations) {
        validations.add("newPassword", as: String.self, is: .count(8...128))
    }
}
