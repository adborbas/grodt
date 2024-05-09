@testable import Grodt
import Foundation
import XCTVapor
import FluentKit

class GrodtTestCase: XCTestCase {
    fileprivate var app: Application!
    
    var database: any Database {
        return app.db
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let expectation = XCTestExpectation(description: "Setup complete")
        
        Task {
            app = Application(.testing)
            try await configure(app)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    override func tearDown() {
        app.shutdown()
    }
}

class GrodtControllerTestCase: GrodtTestCase {
    var basePath: String { return "" }
    var user: User!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let email = "test@test.com"
        let password = "password"
        let user = User(name: "test", email: email, passwordHash: try! Bcrypt.hash(password))
        
        let expectation = XCTestExpectation(description: "Setup complete")
        
        Task {
            try await user.save(on: app.db)
            self.user = user
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func sendRequest(_ method: HTTPMethod, _ path: String = "") async throws -> XCTHTTPResponse {
        return try await app.sendRequest(method, "\(basePath)/\(path)", headers: HTTPHeaders([authHeader()]))
    }
    
    func sendPostRequest(_ path: String = "", body: Encodable) async throws -> XCTHTTPResponse {
        let requestData = try JSONEncoder().encode(body)
        let requestBody = ByteBuffer(data: requestData)
        let headers = try await HTTPHeaders([("Content-Type", "application/json"), authHeader()])
        return try await app.sendRequest(.POST, "\(basePath)/\(path)", headers: headers, body: requestBody)
    }
    
    private func authHeader() async throws -> (String, String) {
        let login = try await app.sendRequest(.POST, "login", headers: HTTPHeaders([AuthorizationHeader.basic(email: user.email, password: "password").value]))
        let response = try login.content.decode(LoginResponseDTO.self)
        return AuthorizationHeader.bearer(token: response.value).value
    }
}

fileprivate enum AuthorizationHeader {
    case basic(email: String, password: String)
    case bearer(token: String)
    
    var value: (String, String) {
        switch self {
        case .basic(let email, let password):
            let basicAuthToken = "\(email):\(password)"
            return ("Authorization", "Basic \(basicAuthToken.data(using: .utf8)!.base64EncodedString())")
        case .bearer(let token):
            return ("Authorization", "Bearer \(token)")
        }
    }
}
