const networkConfig = {
    31337: {
        name: "localhost",
    },
    // Price Feed Address, values can be obtained at https://docs.chain.link/docs/reference-contracts
    5: {
        name: "goerli",
        ethUsdPriceFeed: "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    },
}

// 🐷 将需要建mock的网络标出来
const developmentChains = ["hardhat", "localhost"]
// 🐷 MockV3Aggregator constractor需要的参数
const DECIMALS = "8"
const INITIAL_PRICE = "200000000000" // 2000

module.exports = {
    networkConfig,
    developmentChains,
    DECIMALS,
    INITIAL_PRICE,
}