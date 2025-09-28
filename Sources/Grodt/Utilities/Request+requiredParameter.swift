import Vapor

extension Request {
    func requiredParameter<T>(named parameter: String) throws -> T where T: LosslessStringConvertible {
        guard let rawParameter = parameters.get(parameter),
              let id = T(rawParameter) else {
            throw Abort(.badRequest, reason: "Required parameter '\(parameter)' is missing.")
        }
        
        return id
    }
    
    func requiredID() throws -> UUID {
        try requiredParameter(named: "id")
    }
    
    func requireUserID() throws -> UUID {
        guard let userID = auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        return userID
    }
}
