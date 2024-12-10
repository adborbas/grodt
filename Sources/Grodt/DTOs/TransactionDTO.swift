import Foundation

struct TransactionDTO: Encodable, Equatable {
    let id: String
    let portfolioName: String
    let platform: String
    let account: String?
    let purchaseDate: Date
    let ticker: String
    let currency: CurrencyDTO
    let fees: Decimal
    let numberOfShares: Decimal
    let pricePerShareAtPurchase: Decimal

    enum CodingKeys: String, CodingKey {
        case id, portfolioName, platform, account, ticker, currency, fees, numberOfShares, pricePerShareAtPurchase, purchaseDate
    }
    
    init(id: String, portfolioName: String, platform: String, account: String? = nil, purchaseDate: Date, ticker: String, currency: CurrencyDTO, fees: Decimal, numberOfShares: Decimal, pricePerShareAtPurchase: Decimal) {
        self.id = id
        self.portfolioName = portfolioName
        self.platform = platform
        self.account = account
        self.purchaseDate = purchaseDate
        self.ticker = ticker
        self.currency = currency
        self.fees = fees
        self.numberOfShares = numberOfShares
        self.pricePerShareAtPurchase = pricePerShareAtPurchase
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        portfolioName = try container.decode(String.self, forKey: .portfolioName)
        platform = try container.decode(String.self, forKey: .platform)
        account = try container.decodeIfPresent(String.self, forKey: .account)
        ticker = try container.decode(String.self, forKey: .ticker)
        currency = try container.decode(CurrencyDTO.self, forKey: .currency)
        fees = try container.decode(Decimal.self, forKey: .fees)
        numberOfShares = try container.decode(Decimal.self, forKey: .numberOfShares)
        pricePerShareAtPurchase = try container.decode(Decimal.self, forKey: .pricePerShareAtPurchase)
        
        let dateString = try container.decode(String.self, forKey: .purchaseDate)
        if let date = ISO8601DateFormatter().date(from: dateString) {
            purchaseDate = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .purchaseDate, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
    }

    // Custom function for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(portfolioName, forKey: .portfolioName)
        try container.encode(platform, forKey: .platform)
        if let account = account {
            try container.encode(account, forKey: .account)
        }
        try container.encode(ticker, forKey: .ticker)
        try container.encode(currency, forKey: .currency)
        try container.encode(fees, forKey: .fees)
        try container.encode(numberOfShares, forKey: .numberOfShares)
        try container.encode(pricePerShareAtPurchase, forKey: .pricePerShareAtPurchase)
        
        let dateString = ISO8601DateFormatter().string(from: purchaseDate)
        try container.encode(dateString, forKey: .purchaseDate)
    }
}
