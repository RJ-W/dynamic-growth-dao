// SPDX-License-Identifier: MIT

// 1.Pragma
pragma solidity ^0.8.9;

// 2.Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// 3.Interfaces
// 4.Libraries

// Errors contractName__errorName
error GrowthGame__NotOwner();

// 5.Contracts
/** 
 * @title growthGame Contract
 * @author RJ-W
 * @notice This contract is for finding out prophets from wizards through continuous predict game
 * @dev This price feeds from Chainlink
 */
contract growthGame {

	// 5.1 Type Declarations
	// 5.2 State variables
	address private immutable i_owner;
	address[] private s_wizards;
	address[] private s_prophets;

	uint256 private s_currentPrice;
	mapping(address => int256) private s_addressToPrediction;
	mapping(address => uint256) private s_addressToIntegration;
	AggregatorV3Interface private s_priceFeed;

	// 5.3 Events
	// 5.4 Errors
	// 5.5 Modifiers
	modifier onlyOwner() {
		// 🐷 require(msg.sender == i_owner);
		if (msg.sender != i_owner) revert GrowthGame__NotOwner();
		_;
	}

	// 5.6 Functions: constructor, receive, fallback, external, public, internal, private, view/pure
	constructor(address priceFeedAddress) {
		s_priceFeed = AggregatorV3Interface(priceFeedAddress);
		i_owner = msg.sender;

		// 🐷 init currentPrice
		s_currentPrice = getCurrentPrice(s_priceFeed);
	}

	receive() external payable {
		predict(0);
	}

	fallback() external payable {
		predict(0);
	}

	/** 
	 * @notice wizards predict the uplift of successor exchange rate between ETH and USD
	 * @dev init or update one's prediction
	 */
	function predict(int256 uplift) public {
		s_addressToPrediction[msg.sender] = uplift;
		s_wizards.push(msg.sender);
	}

	/** 
	 * @notice owner operate the game
	 * @dev get the latest price, verify all prediction, and record
	 */
	function verify() public onlyOwner {
		uint256 latestPrice = getCurrentPrice(s_priceFeed);
		int256 realUplift = int256(latestPrice - s_currentPrice);

		for (uint256 index = 0; index < s_wizards.length; index++) {
			address wizard = s_wizards[index];

			uint256 diff = uint256(s_addressToPrediction[wizard] - realUplift);
			s_addressToIntegration[wizard] += (1 / diff);

			s_addressToPrediction[wizard] = 0;
		}

		s_wizards = new address[](0);
	}

	/** 
	 * @notice cheaper verify with variable in memory
	 * @dev mappings can't be in memory
	 */
	function cheaperVerify() public onlyOwner {
		uint256 latestPrice = getCurrentPrice(s_priceFeed);
		int256 realUplift = int256(latestPrice - s_currentPrice);

		address[] memory wizards = s_wizards;

		for (uint256 index = 0; index < wizards.length; index++) {
			address wizard = wizards[index];

			uint256 diff = uint256(s_addressToPrediction[wizard] - realUplift);
			s_addressToIntegration[wizard] += (1 / diff);

			s_addressToPrediction[wizard] = 0;
		}

		s_wizards = new address[](0);

	}


	/** 
	 * @notice prophets will stand out based on the integration records
	 * @dev elect prophets from wizards based on integration records
	 */


	function getCurrentPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
		(, int256 answer, , , ) = priceFeed.latestRoundData();
		return uint256(answer);
	}

	function getPrediction() public view returns (int256) {
		int256 prediction = s_addressToPrediction[msg.sender];
		return prediction;
	}

	function getIntegration() public view returns (uint256) {
		uint256 integration = s_addressToIntegration[msg.sender];
		return integration;
	}

	function getPriceFeed() public view returns (AggregatorV3Interface) {
		return s_priceFeed;
	}
}