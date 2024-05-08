# Grodt

Grodt is a [Vapor](https://github.com/vapor/vapor) based personal finance REST API. It uses the [Alphavantage API](https://www.alphavantage.co/) to get quotes and currency exchange rates.

## Run locally

*Prerequsite*:

- [Install Docker Desktop on Mac](https://docs.docker.com/desktop/install/mac-install/)
- Get an [API key for Alphavantage](https://www.alphavantage.co/support/#api-key)

**Steps**:

1. Clone the repository.
1. Add your Alphavantage API key to a file named `.alphavantagekey` in the root of the repository. This path is added to `.gitignore`.
1. Start the database locally by running `docker compose up -d`.
1. Open the cloned repository in Xcode.
1. Build and run.
1. Please check the [REST API](#the-rest-api) section for details for interacting with Grodt.

## The REST API

### Authentication

You need to authenticate to the REST API to access the endpoints using a bearer token.

#### Getting a bearer token

##### Request

`POST` `/login`

Header: `Authorization: Basic <credentials>`, where `<credentials>` is the Base64 encoding of ID and password joined by a single colon :.

Please check the [.env.development](/.env.development) file for the default credentials.

##### Response

```json
{
    "value": "<TOKEN>"
}
```

#### Authenticating with the token

You need to add the `Authorization: Bearer <token>`, where `<token>` is the string value you need to obtain with the `/login` endpoint above.

### Endpoints

All endpoints are accessiable via the `/api` base path.

#### Portfolios

##### List portfolios

To get a list of the portfolios.

- Request: `GET` `/portfolios`
- Response: Array of [PortfolioInfo](#portfolioinfo).

##### Get a portfolio

Returns the contents of a portfolio.

- Request: `GET` `/portfolios/<PORTFOLIO-ID>`
- Response: A [Portfolio](#portfolio) object.

##### Create a portfolio

- Request: `POST` `/portfolios`
- Body:

```json
{
    "name": "String",
    "currency": "String" // The currency code
}
```

- Response: A [Portfolio](#portfolio) object.

##### Delete a portfolio

- Request: `DELETE` `/portfolios/<PORTFOLIO-ID>`

#### Transactions

##### Get a transaction

To get the details of a transaciton.

- Request: `GET` `/transactions/<TRANSACTION-ID>`
- Response: A [Transaction](#transaction) object.

##### Create a transaction

- Request: `POST` `/transactions`
- Body:

```json
{
    "portfolio": "String", // The portfolio ID
    "platform": "String",
    "account": "String", // OPTIONAL
    "purchaseDate": "Date",
    "ticker": "String",
    "currency": "String",
    "fees": "Decimal",
    "numberOfShares": "Decimal",
    "pricePerShare": "Decimal"
}
```

- Response: The newly created [Transaction](#transaction) object.

##### Delete a transaction

- Request: `DELETE` `/transactions/<TRANSACTION-ID>`

### Models

#### Portfolio

```json
{
    "name": "String",
    "id": "String",
    "currency": "Currency",
    "performance": "Performance",
    "transactions": ["Transaction"]
}
```

#### Transaction

```json
{
    "id": "String",
    "platform": "String", 
    "account": "String?", // OPTIONAL
    "purchaseDate": "Date",
    "ticker": "String",
    "currency": "Currency",
    "fees": "Decimal",
    "numberOfShares": "Decimal",
    "pricePerShareAtPurchase": "Decimal"
}
```

#### PortfolioInfo

```json
{
    "name": "String",
    "id": "String",
    "performance": "Performance",
    "currency": "Currency",
    "transactions": "[String]", // Array of transaction IDs
}
```

#### Performance

Currency agnostic values. Response always contains a corresponding [Currency](#currency).

```json
{
    "profit": "Decimal",
    "moneyOut": "Decimal",
    "moneyIn": "Decimal",
    "totalReturn": "Decimal"
}
```

#### Currency

```json
{
   "code": "String",
   "symbol": "String"
}
```
