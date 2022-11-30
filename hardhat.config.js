require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomiclabs/hardhat-etherscan");
require("./tasks/block-number");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy");


const GOERLI_RPC_URL =
	process.env.GOERLI_RPC_URL || "https://eth-goerli.alchemyapi.io/v2/your-api-key"
const PRIVATE_KEY = process.env.PRIVATE_KEY
const ETHERSCAN_API_KEY = 
	process.env.ETHERSCAN_API_KEY || "https://etherscan.io/myapikey"
const COINMARKETCAP_API_KEY = 
	process.env.COINMARKETCAP_API_KEY || "https://pro.coinmarketcap.com/account"

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
	solidity: {
		compilers: [
			{version: "0.8.9"},
			{version: "0.6.6"}
		]
	},
	networks: {
		localhost: {
			chainId: 31337,
    	},
    	goerli: {
        	url: GOERLI_RPC_URL,
        	accounts: PRIVATE_KEY !== undefined ? [PRIVATE_KEY] : [],
        	chainId: 5,
			blockConfirmations: 6, // how many block we wanna to wait
		},
	},
	etherscan: {
		// Your API key for Etherscan
		// Obtain one at https://etherscan.io/
		apiKey: ETHERSCAN_API_KEY
	},
	gasReporter: {
		enabled: true,
		currency: "USD",
		outputFile: "gas-report.txt",
		noColors: true,
		coinmarketcap: COINMARKETCAP_API_KEY,
	},
	namedAccounts: {
        deployer: {
            default: 0, // here this will by default take the first account as deployer
            1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
        },
    },
};
