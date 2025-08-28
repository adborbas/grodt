import Foundation

struct CreateTransactionRequestDTO: Decodable {
    let portfolio: String
    let brokerageAccountID: String
    let platform: String
    let account: String?
    let purchaseDate: Date
    let ticker: String
    let currency: String
    let fees: Decimal
    let numberOfShares: Decimal
    let pricePerShare: Decimal
    
    enum CodingKeys: String, CodingKey {
        case portfolio, brokerageAccountID, platform, account, purchaseDate, ticker, currency, fees, numberOfShares, pricePerShare
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        portfolio = try container.decode(String.self, forKey: .portfolio)
        brokerageAccountID = try container.decode(String.self, forKey: .brokerageAccountID)
        platform = try container.decode(String.self, forKey: .platform)
        account = try container.decodeIfPresent(String.self, forKey: .account)
        ticker = try container.decode(String.self, forKey: .ticker)
        currency = try container.decode(String.self, forKey: .currency)
        fees = try container.decode(Decimal.self, forKey: .fees)
        numberOfShares = try container.decode(Decimal.self, forKey: .numberOfShares)
        pricePerShare = try container.decode(Decimal.self, forKey: .pricePerShare)
        
        let dateString = try container.decode(String.self, forKey: .purchaseDate)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            purchaseDate = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .purchaseDate, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
    }
}
