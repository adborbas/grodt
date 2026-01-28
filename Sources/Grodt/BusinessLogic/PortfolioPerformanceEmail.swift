import MailjetKit
import Foundation
import FluentKit

class PortfolioPerformanceEmail {
    private let userRepository: PostgresUserRepository
    private let portfolioService: PortfolioService

    init(portfolioService: PortfolioService,
         userRepository: PostgresUserRepository) {
        self.portfolioService = portfolioService
        self.userRepository = userRepository
    }

    func sendMonthlyUpdates() async throws {
        let users = try await userRepository.allUsers(with: [.preferences, .secrets])
        for user in users {
            try await sendUpdateForUser(user)
        }
    }

    private func sendUpdateForUser(_ user: User) async throws {
        let preferences = user.requiredPreferences
        guard preferences.monthlyEmail.isEnabled,
              let apiSecret = try await userRepository.getMailjetApiSecret(for: user),
              let config = preferences.monthlyEmail.configuration
        else { return }

        let userID = try user.requireID()
        let portfolios = try await portfolioService.allPortfolios(userID: userID)

        guard !portfolios.isEmpty else { return }

        let htmlContent = buildHTMLEmail(portfolios: portfolios, userName: user.name)
        let textContent = buildPlainTextEmail(portfolios: portfolios, userName: user.name)

        let mailjet = MailjetKit(apiKey: config.apiKey,
                                 apiSecret: apiSecret)

        let envelope = Envelope(
            from: Recipient(email: config.senderEmail, name: config.senderName),
            to: [Recipient(email: user.email, name: user.name)]
        )
        let content = Content(
            subject: "Your Monthly Portfolio Performance Update",
            textPart: textContent,
            htmlPart: htmlContent
        )
        let message = Message(envelope: envelope, content: content)

        let result = await mailjet.send(message: message)
        switch result {
        case .success:
            print("Monthly email sent to \(user.email)")
        case .failure(let error):
            print("Failed to send email to \(user.email): \(error.localizedDescription)")
        }
    }

    private func buildHTMLEmail(portfolios: [PortfolioInfoDTO], userName: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let monthName = dateFormatter.string(from: Date())

        let totalValue = portfolios.reduce(Decimal(0)) { $0 + $1.performance.moneyOut }
        let totalProfit = portfolios.reduce(Decimal(0)) { $0 + $1.performance.profit }
        let totalMoneyIn = portfolios.reduce(Decimal(0)) { $0 + $1.performance.moneyIn }
        let overallReturn = totalMoneyIn > 0 ? (totalProfit / totalMoneyIn * 100) : 0

        let profitSign = totalProfit >= 0 ? "+" : ""

        var portfolioRows = ""
        if portfolios.count > 1 {
            for portfolio in portfolios {
                let pSign = portfolio.performance.profit >= 0 ? "+" : ""
                portfolioRows += """
                <tr>
                    <td>\(portfolio.name)</td>
                    <td>\(portfolio.currency.symbol)\(formatDecimal(portfolio.performance.moneyOut))</td>
                    <td>\(pSign)\(portfolio.currency.symbol)\(formatDecimal(portfolio.performance.profit))</td>
                    <td>\(formatDecimal(portfolio.performance.totalReturn * 100))%</td>
                </tr>
                """
            }
        }

        let portfolioTable = portfolios.count > 1 ? """
        <h2>Portfolio Breakdown</h2>
        <table border="1">
            <tr>
                <th>Portfolio</th>
                <th>Value</th>
                <th>Profit/Loss</th>
                <th>Return</th>
            </tr>
            \(portfolioRows)
        </table>
        """ : ""

        return """
        <!DOCTYPE html>
        <html>
        <body>
            <h1>Portfolio Performance Update</h1>
            <p>\(monthName)</p>

            <p>Hi \(userName),</p>
            <p>Here's your monthly portfolio performance summary:</p>

            <h2>Total Portfolio</h2>
            <p><strong>Value:</strong> \(formatDecimal(totalValue))</p>
            <p><strong>Profit/Loss:</strong> \(profitSign)\(formatDecimal(totalProfit)) (\(formatDecimal(overallReturn))%)</p>

            \(portfolioTable)

            <hr>
            <p><em>This is an automated monthly report from Grodt.</em></p>
        </body>
        </html>
        """
    }

    private func buildPlainTextEmail(portfolios: [PortfolioInfoDTO], userName: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let monthName = dateFormatter.string(from: Date())

        let totalValue = portfolios.reduce(Decimal(0)) { $0 + $1.performance.moneyOut }
        let totalProfit = portfolios.reduce(Decimal(0)) { $0 + $1.performance.profit }
        let totalMoneyIn = portfolios.reduce(Decimal(0)) { $0 + $1.performance.moneyIn }
        let overallReturn = totalMoneyIn > 0 ? (totalProfit / totalMoneyIn * 100) : 0

        let profitSign = totalProfit >= 0 ? "+" : ""

        var text = """
        Portfolio Performance Update - \(monthName)
        ============================================

        Hi \(userName),

        Here's your monthly portfolio performance summary:

        TOTAL PORTFOLIO
        ---------------
        Total Value: \(formatDecimal(totalValue))
        Profit/Loss: \(profitSign)\(formatDecimal(totalProfit)) (\(formatDecimal(overallReturn))%)

        """

        if portfolios.count > 1 {
            text += "\nPORTFOLIO BREAKDOWN\n-------------------\n"
            for portfolio in portfolios {
                let pSign = portfolio.performance.profit >= 0 ? "+" : ""
                text += "\(portfolio.name): \(portfolio.currency.symbol)\(formatDecimal(portfolio.performance.moneyOut)) (\(pSign)\(formatDecimal(portfolio.performance.totalReturn * 100))%)\n"
            }
        }

        text += "\n--\nThis is an automated monthly report from Grodt."

        return text
    }

    private func formatDecimal(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "\(value)"
    }
}
