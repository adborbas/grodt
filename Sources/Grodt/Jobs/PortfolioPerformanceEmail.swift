import Foundation
import FluentKit
import Logging

class PortfolioPerformanceEmail {
    private let userRepository: PostgresUserRepository
    private let portfolioService: PortfolioService
    private let mailSender: MailSending
    private let logger = Logger(label: "PortfolioPerformanceEmail")

    init(portfolioService: PortfolioService,
         userRepository: PostgresUserRepository,
         mailSender: MailSending) {
        self.portfolioService = portfolioService
        self.userRepository = userRepository
        self.mailSender = mailSender
    }

    func sendMonthlyUpdates() async throws {
        let users = try await userRepository.allUsers(with: [.preferences])
        for user in users {
            await sendUpdateForUser(user)
        }
    }

    private func sendUpdateForUser(_ user: User) async {
        do {
            let preferences = user.requiredPreferences
            guard preferences.monthlyEmail.isEnabled else { return }

            let userID = try user.requireID()
            let portfolios = try await portfolioService.allPortfolios(userID: userID)

            guard !portfolios.isEmpty else { return }

            let htmlContent = buildHTMLEmail(portfolios: portfolios, userName: user.name)

            let message = MailMessage(
                from: MailAddress(email: "system", name: "Grodt"),
                to: MailAddress(email: user.email, name: user.name),
                subject: "Your Monthly Portfolio Performance Update",
                htmlBody: htmlContent
            )

            try await mailSender.send(message)
            logger.info("Monthly email sent to \(user.email)")
        } catch {
            logger.error("Failed to send email to \(user.email): \(error.localizedDescription)")
        }
    }

    private func buildHTMLEmail(portfolios: [PortfolioInfoDTO], userName: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        let monthName = dateFormatter.string(from: Date())

        let totalValue = portfolios.reduce(into: Decimal(0)) { $0 += $1.performance.currentValue }
        let totalProfit = portfolios.reduce(into: Decimal(0)) { $0 += $1.performance.profit }
        let totalInvested = portfolios.reduce(into: Decimal(0)) { $0 += $1.performance.invested }
        let overallReturn = totalInvested > 0 ? (totalProfit / totalInvested * 100) : 0

        let profitSign = totalProfit >= 0 ? "+" : ""

        var portfolioRows = ""
        if portfolios.count > 1 {
            for portfolio in portfolios {
                let pSign = portfolio.performance.profit >= 0 ? "+" : ""
                portfolioRows += """
                <tr>
                    <td>\(htmlEscape(portfolio.name))</td>
                    <td>\(htmlEscape(portfolio.currency.symbol))\(formatDecimal(portfolio.performance.currentValue))</td>
                    <td>\(pSign)\(htmlEscape(portfolio.currency.symbol))\(formatDecimal(portfolio.performance.profit))</td>
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
            <p>\(htmlEscape(monthName))</p>

            <p>Hi \(htmlEscape(userName)),</p>
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

    private func formatDecimal(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "\(value)"
    }

    private func htmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}
