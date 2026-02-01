@testable import Grodt
import Testing
import Vapor
import XCTVapor

struct TransactionsRouteTests: RouteTestable {

    let basePath = "ski/v1/transactions"

    // MARK: - GET /transactions/:id

    @Test func detail_existingTransaction_returnsTransaction() async throws {
        let transactionId = UUID()
        let expectedTransaction = TransactionDTO.stub(
            id: transactionId.uuidString,
            portfolioName: "My Portfolio",
            ticker: "AAPL"
        )

        let mockService = MockTransactionService()
        mockService.detailResult = .success(expectedTransaction)

        try await withTestApp(transactionService: mockService) { app, token in
            try await app.test(.GET, path(for: transactionId), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let transaction = try res.content.decode(TransactionDTO.self)
                #expect(transaction.id == transactionId.uuidString)
                #expect(transaction.ticker == "AAPL")
            })
        }
    }

    // MARK: - DELETE /transactions/:id

    @Test func delete_existingTransaction_returnsOk() async throws {
        let transactionId = UUID()
        let mockService = MockTransactionService()
        mockService.deleteResult = .success(.ok)

        try await withTestApp(transactionService: mockService) { app, token in
            try await app.test(.DELETE, path(for: transactionId), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    // MARK: - PATCH /transactions/:id/brokerage-account

    @Test func updateBrokerageAccount_validRequest_returnsUpdatedTransaction() async throws {
        let transactionId = UUID()
        let brokerageAccountId = UUID()
        let expectedTransaction = TransactionDTO.stub(
            id: transactionId.uuidString,
            brokerageAccount: BrokerageAccountInfoDTO.stub(id: brokerageAccountId)
        )

        let mockService = MockTransactionService()
        mockService.updateBrokerageAccountResult = .success(expectedTransaction)

        try await withTestApp(transactionService: mockService) { app, token in
            struct UpdateRequest: Content {
                let brokerageAccountId: String?
            }
            let requestBody = UpdateRequest(brokerageAccountId: brokerageAccountId.uuidString)

            try await app.test(.PATCH, "\(path(for: transactionId))/brokerage-account", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let transaction = try res.content.decode(TransactionDTO.self)
                #expect(transaction.brokerageAccount?.id == brokerageAccountId)
            })
        }
    }

    @Test func updateBrokerageAccount_unlinkAccount_returnsUpdatedTransaction() async throws {
        let transactionId = UUID()
        let expectedTransaction = TransactionDTO.stub(
            id: transactionId.uuidString,
            brokerageAccount: nil
        )

        let mockService = MockTransactionService()
        mockService.updateBrokerageAccountResult = .success(expectedTransaction)

        try await withTestApp(transactionService: mockService) { app, token in
            struct UpdateRequest: Content {
                let brokerageAccountId: String?
            }
            let requestBody = UpdateRequest(brokerageAccountId: nil)

            try await app.test(.PATCH, "\(path(for: transactionId))/brokerage-account", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let transaction = try res.content.decode(TransactionDTO.self)
                #expect(transaction.brokerageAccount == nil)
            })
        }
    }

}
