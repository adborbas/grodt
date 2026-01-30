import Foundation

struct CreateTransactionRequestDTO: Decodable {
    let brokerageAccountID: String?
    let type: String
    let transactionDate: Date
    let ticker: String
    let currency: String
    let fees: Decimal
    let numberOfShares: Decimal
    let pricePerShare: Decimal

    var transactionType: TransactionType {
        TransactionType(rawValue: type) ?? .buy
    }

    init(brokerageAccountID: String? = nil,
         type: String = "buy",
         transactionDate: Date,
         ticker: String,
         currency: String,
         fees: Decimal,
         numberOfShares: Decimal,
         pricePerShare: Decimal) {
        self.brokerageAccountID = brokerageAccountID
        self.type = type
        self.transactionDate = transactionDate
        self.ticker = ticker
        self.currency = currency
        self.fees = fees
        self.numberOfShares = numberOfShares
        self.pricePerShare = pricePerShare
    }

    enum CodingKeys: String, CodingKey {
        case brokerageAccountID, type, transactionDate, ticker, currency, fees, numberOfShares, pricePerShare
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        brokerageAccountID = try container.decodeIfPresent(String.self, forKey: .brokerageAccountID)
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "buy"
        ticker = try container.decode(String.self, forKey: .ticker)
        currency = try container.decode(String.self, forKey: .currency)
        fees = try container.decode(Decimal.self, forKey: .fees)
        numberOfShares = try container.decode(Decimal.self, forKey: .numberOfShares)
        pricePerShare = try container.decode(Decimal.self, forKey: .pricePerShare)

        let dateString = try container.decode(String.self, forKey: .transactionDate)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            transactionDate = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .transactionDate, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
    }
}
