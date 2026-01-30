import Foundation

struct TransactionTypeDTO: Codable, Equatable {
    let rawValue: String

    static let buy = TransactionTypeDTO(rawValue: "buy")
    static let sell = TransactionTypeDTO(rawValue: "sell")

    init(from transactionType: TransactionType) {
        self.rawValue = transactionType.rawValue
    }

    private init(rawValue: String) {
        self.rawValue = rawValue
    }
}

struct TransactionDTO: Encodable, Equatable {
    let id: String
    let portfolioName: String
    let type: TransactionTypeDTO
    let transactionDate: Date
    let ticker: String
    let currency: CurrencyDTO
    let fees: Decimal
    let numberOfShares: Decimal
    let pricePerShare: Decimal
    let brokerageAccount: BrokerageAccountInfoDTO?

    enum CodingKeys: String, CodingKey {
        case id, portfolioName, type, transactionDate, ticker, currency, fees, numberOfShares, pricePerShare, brokerageAccount
    }

    init(
        id: String,
        portfolioName: String,
        type: TransactionTypeDTO,
        transactionDate: Date,
        ticker: String,
        currency: CurrencyDTO,
        fees: Decimal,
        numberOfShares: Decimal,
        pricePerShare: Decimal,
        brokerageAccount: BrokerageAccountInfoDTO?
    ) {
        self.id = id
        self.portfolioName = portfolioName
        self.type = type
        self.transactionDate = transactionDate
        self.ticker = ticker
        self.currency = currency
        self.fees = fees
        self.numberOfShares = numberOfShares
        self.pricePerShare = pricePerShare
        self.brokerageAccount = brokerageAccount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        portfolioName = try container.decode(String.self, forKey: .portfolioName)
        type = try container.decode(TransactionTypeDTO.self, forKey: .type)
        ticker = try container.decode(String.self, forKey: .ticker)
        currency = try container.decode(CurrencyDTO.self, forKey: .currency)
        fees = try container.decode(Decimal.self, forKey: .fees)
        numberOfShares = try container.decode(Decimal.self, forKey: .numberOfShares)
        pricePerShare = try container.decode(Decimal.self, forKey: .pricePerShare)
        brokerageAccount = try container.decodeIfPresent(BrokerageAccountInfoDTO.self, forKey: .brokerageAccount)

        let dateString = try container.decode(String.self, forKey: .transactionDate)
        if let date = ISO8601DateFormatter().date(from: dateString) {
            transactionDate = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .transactionDate, in: container, debugDescription: "Date string does not match format expected by formatter.")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(portfolioName, forKey: .portfolioName)
        try container.encode(type, forKey: .type)
        try container.encode(ticker, forKey: .ticker)
        try container.encode(currency, forKey: .currency)
        try container.encode(fees, forKey: .fees)
        try container.encode(numberOfShares, forKey: .numberOfShares)
        try container.encode(pricePerShare, forKey: .pricePerShare)
        try container.encodeIfPresent(brokerageAccount, forKey: .brokerageAccount)

        let dateString = ISO8601DateFormatter().string(from: transactionDate)
        try container.encode(dateString, forKey: .transactionDate)
    }
}
