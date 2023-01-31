const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
require("dotenv").config()

module.exports = async ( { getNamedAccounts, deployments, network } ) => {
    // console.log("Hi!")

    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    // console.log(network.config.chainId)
    const chainId = network.config.chainId

    // when we use chainlink in mainnet or testnet, we get priceFeedAddress from https://docs.chain.link/data-feeds/price-feeds/addresses
    // when we use chainlink in localhost or hardhat network, we build mock
    // 🐷 配置ethUsdPriceFeedAddress 或 生成mock
    let ethUsdPriceFeedAddress
    if (chainId == 31337) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }

    // 🐷 开始deploy
    console.log("----------------------------------------------------")
    console.log("Deploying growthGame and waiting for confirmations...")
    const growthGame = await deploy("growthGame", {
        from: deployer,
        args: [ethUsdPriceFeedAddress, 5000],
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    console.log(`growthGame deployed at ${growthGame.address}`)

    // 🐷 开始verify 此时用的是utils/verify
    console.log("verifying growthGame and waiting...")
    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(growthGame.address, [ethUsdPriceFeedAddress, 5])
    }
    console.log("growthGame verified")

}

module.exports.tags = ["all", "growthGame"]