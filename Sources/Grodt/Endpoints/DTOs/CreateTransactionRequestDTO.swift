import Foundation

struct CreateTransactionRequestDTO: Decodable {
    let brokerageAccountID: String?
    let purchaseDate: Date
    let ticker: String
    let currency: String
    let fees: Decimal
    let numberOfShares: Decimal
    let pricePerShare: Decimal
    
    enum CodingKeys: String, CodingKey {
        case brokerageAccountID, purchaseDate, ticker, currency, fees, numberOfShares, pricePerShare
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        brokerageAccountID = try container.decodeIfPresent(String.self, forKey: .brokerageAccountID)
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
