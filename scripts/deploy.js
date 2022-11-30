// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const { ethers, run, network } = require("hardhat");

async function main() {
	const currentTimestampInSeconds = Math.round(Date.now() / 1000);
	const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
	const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

	const lockedAmount = ethers.utils.parseEther("0.0001");

	const Lock = await ethers.getContractFactory("Lock");
	const lock = await Lock.deploy(unlockTime, { value: lockedAmount });

	await lock.deployed();

	console.log(
		`Lock with 1 ETH and unlock timestamp ${unlockTime} deployed to ${lock.address}`
	);

	// what happens when we deploy to our hardhat network?
	// verify is needed when we deploy to main or test network
	if (network.config.chainId === 5 && process.env.ETHERSCAN_API_KEY) {
		console.log("Waiting for block confirmations...");
		// wait for 6 block after the contract was deployed
		await lock.deployTransaction.wait(6);
		await verify(lock.address, [60, ]);
	}

	// 🐷 这个没搞定 目标是打印数字 但打印的是[object Object]
	const ret = await lock.test();
	// use function
	console.log(
		`test return: ${ret}`
	);
}

// async function verify(contractAddress, args) {
const verify = async (contractAddress, args) => {
	console.log("Verifying contract...")
	try {
		await run("verify:verify", {
			address: contractAddress,
			constructorArguments: args,
		})
	} catch (e) {
		if (e.message.toLowerCase().includes("already verified")) {
			console.log("Already Verified!")
	  	} else {
			console.log(e)
	  	}
	}
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
	console.error(error);
	process.exitCode = 1;
});
