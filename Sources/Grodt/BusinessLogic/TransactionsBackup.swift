import MailjetKit
import Foundation
import FluentKit

struct MailjetConfiguration {
    let apiKey: String
    let apiSecret: String
    let senderEmail: String
    let senderName: String
}

class TransactionsBackup {
    private let userRepository: PostgresUserRepository
    private let transactionService: TransactionService

    init(transactionsService: TransactionService,
         userRepository: PostgresUserRepository) {
        self.transactionService = transactionsService
        self.userRepository = userRepository
    }

    func backup() async throws {
        let users = try await userRepository.allUsers(with: [.preferences, .secrets])
        for user in users {
            let preferences = user.requiredPreferences
            guard preferences.transactionBackup.isEnabled,
                  let apiSecret = user.requiredSecrets.mailjetApiSecret,
                  let config = preferences.transactionBackup.configuration
            else { continue }


            let transactions = try await transactionService.all(for: user.requireID())

            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(transactions)
            let base64Content = jsonData.base64EncodedString()

            let mailjet = MailjetKit(apiKey: config.apiKey,
                                     apiSecret: apiSecret)

            let message = Message(from: Recipient(email: config.senderEmail,
                                                  name: config.senderName),
                                  to: Recipient(email: user.email,
                                                name: user.name),
                                  subject: "Backup of Podt transacitons",
                                  textPart: "See the JSON attached.")
                .addAttachment(Attachment(fileName: "transactions.json", contentType: "application/json", base64Content: base64Content))

            let result = await mailjet.send(message: message)
            switch result {
            case .success:
                print("Success")
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
