import Vapor

struct UpdateEmailDTO: Content, Validatable {
    let email: String
    let currentPassword: String

    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email && .count(...254))
    }
}
