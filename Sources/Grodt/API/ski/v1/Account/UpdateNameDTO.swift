import Vapor

struct UpdateNameDTO: Content, Validatable {
    let name: String

    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: .count(5...100))
    }
}
