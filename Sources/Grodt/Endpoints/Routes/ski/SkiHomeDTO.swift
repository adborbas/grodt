struct SkiHomeDTO: ResponseDTO {
    let user: UserInfoDTO
    let performance: PerformanceDTO
    let portfolios: [PortfolioInfoDTO]
}
