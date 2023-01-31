const { assert, expect } = require("chai")
const { network, getNamedAccounts, deployments, ethers } = require("hardhat")

// 🐷 for the whole contract
describe("growthGame", async function () {

    let growthGame
    let mockV3Aggregator
    let deployer
    const predictValue = 5

    // 🐷 each time, deploy the contract firstly like fixture
    beforeEach(async function () {
        // 🐷 two methods get deployer: ethers or config.js(like in deploy.js)
        // const accounts = await ethers.getSigners()
        // deployer = accounts[0]
        deployer = (await getNamedAccounts()).deployer

        // 🐷 use tags in deploy.js folder to deploy
        await deployments.fixture(["all"])

        // 🐷 getContract: get recent contract been deployed
        growthGame = await ethers.getContract("growthGame", deployer)
        mockV3Aggregator = await ethers.getContract(
            "MockV3Aggregator",
            deployer
        )
    })

    // 🐷 Test for the constructor
    // 🐷 1.get true address
    describe("Constructor", function () {
        it("Should set the aggregator addresses correctly", async () => {
            // 🐷 获取已经用priceFeedAddress初始化的AggregatorV3Interface
            const response = await growthGame.getPriceFeed()
            // 🐷 这里不确定 
            // 因为Aggregator首先被deploy 
            // 之后其地址address被传入growthGame的constructor 初始化接口Interface
            // 现在直接调用getPriceFeed 就是这个接口类型 和地址address直接比较？
            assert.equal(response, mockV3Aggregator.address)

        })
    })

    // 🐷 Test for fund
    // 🐷 1.value >= fundThreshold
    // 🐷 2.cal balance correctlly
    describe("Fund", function () {
        it("Should revert error if not send enough ETH", async () => {

            const fundThreshold = await growthGame.getFundThreshold()

            console.log(fundThreshold) // BigNumber { _hex: '0x1388', _isBigNumber: true }
            console.log(growthGame.i_fundThreshold_usd18digit) // [Function (anonymous)]
            console.log("growthGame.getFundThreshold(): ", growthGame.getFundThreshold())

            // await growthGame.fund({ value: 2 })
            await expect(growthGame.fund({ value: 2 })).to.be.revertedWithCustomError(growthGame, "GrowthGame__LessthanFundThreshold")

        })
        it("Should add funder to array of funders", async () => {

            await growthGame.fund({ value: 3 })
            const response = await growthGame.getFunderExist(deployer)
            assert.equal(response, true)

        })
        it("Should get right proportion", async () => {

            
        })
    })

    // 🐷 Test for withdraw
    // 🐷 1.user get right amount
    // 🐷 2.proportion record clean

    // 🐷 Error: invalid BigNumber value (argument="value", value={"uplift":5}, code=INVALID_ARGUMENT, version=bignumber/5.7.0)
    /*
    describe("predict", async function () {
        it("update one's prediction correctly", async () => {
            await growthGame.predict({uplift: predictValue})
            const response = await growthGame.getPrediction()
            assert.equal(response, predictValue)
        })

        it("add sender to s_wizards array", async () => {
            await growthGame.predict({uplift: predictValue})
            const response = growthGame.s_wizards[0]
            assert.equal(response, deployer)
        })
    })
    */

    /*
    describe("verify", async function (){
        // 🐷 before verify, we need some prediction
        beforeEach(async function () {
            await growthGame.predict({uplift: predictValue})
        })

        it("verify with single prediction correctly", async () => {
            
        })

        it("verify with multiple prediction correctly", async () => {

        })

        it("only owner can do verification", async () => {

        })
    })
    */
})