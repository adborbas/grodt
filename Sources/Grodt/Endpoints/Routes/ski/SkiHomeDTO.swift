struct SkiHomeResponseDTO: ResponseDTO {
    let user: UserInfoDTO
    let networth: PerformanceDTO
    let portfolios: [PortfolioInfoDTO]
    let brokerages: [BrokerageInfoDTO]
}
