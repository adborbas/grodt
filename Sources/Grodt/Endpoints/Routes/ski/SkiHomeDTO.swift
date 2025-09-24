struct SkiHomeResponseDTO: ResponseDTO {
    let user: UserInfoDTO
    let performance: PerformanceDTO
    let portfolios: [PortfolioInfoDTO]
    let brokerages: [BrokerageInfoDTO]
}
