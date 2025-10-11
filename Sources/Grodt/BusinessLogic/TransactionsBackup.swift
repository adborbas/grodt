import MailjetKit
import Foundation

class TransactionsBackup {
    private let mailjetConfiguration: AppConfiguration.Mailjet
    private let userRepository: PostgresUserRepository
    private let transactionService: TransactionService

    init(mailjetConfiguration: AppConfiguration.Mailjet,
         transactionsService: TransactionService,
         userRepository: PostgresUserRepository) {
        self.transactionService = transactionsService
        self.userRepository = userRepository
        self.mailjetConfiguration = mailjetConfiguration
    }

    func backup() async throws {
        let apiKey = try mailjetConfiguration.$apiKey.requiredValue()
        let apiSecret = try mailjetConfiguration.$apiSecret.requiredValue()
        let senderEmail = try mailjetConfiguration.$senderEmail.requiredValue()
        let senderName = try mailjetConfiguration.$senderName.requiredValue()

        let users = try await userRepository.allUsers()
        for user in users {
            let transactions = try await transactionService.all(for: user.requireID())

            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(transactions)
            let base64Content = jsonData.base64EncodedString()

            let mailjet = MailjetKit(apiKey: apiKey,
                                     apiSecret: apiSecret)

            let message = Message(from: Recipient(email: senderEmail,
                                                  name: senderName),
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
