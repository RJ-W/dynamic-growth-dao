const { developmentChains, DECIMALS, INITIAL_PRICE } = require("../helper-hardhat-config")


module.exports = async ( { getNamedAccounts, deployments, network } ) => {
    // console.log("Hi!")

    const { deploy, log } = deployments
    // 🐷 这里的getNamedAccounts 配置在config namedAccounts
    const { deployer } = await getNamedAccounts()
    // console.log(network.config.chainId)
    const chainId = network.config.chainId

    log(network.name)

    // 🐷 首先判断是否需要做mock
    if (developmentChains.includes(network.name)) {
        log("Hardhat or localhost detected! Deploying mock...")

        await deploy("MockV3Aggregator", {
            // 🐷 contract 好像是可写可不写
            contract: "MockV3Aggregator",
            from: deployer,
            log: true,
            // 🐷 参数配到了helper-hardhat-config.js
            args: [DECIMALS, INITIAL_PRICE],
        })

        log("Mock deployed!")
        log("----------------------------------------------------")
    }

}

module.exports.tags = ["all", "mocks"]