// SPDX-License-Identifier: MIT

// 1.Pragma
pragma solidity ^0.8.9;

// 2.Imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "hardhat/console.sol";

// 🐷 初版不复杂 
// 🐷 1.首先有一个存钱+取钱功能 fund+withdraw
// 🐷 2.其次有一个预测+加权+交易+验证
	// 🐷 预测: 最简单的涨跌量 +3 -5 
		// 🐷 预测周期: 1小时 提前15min截止
		// 🐷 10:00~11:00 预测12:00价格
		// 🐷 11:00~12:00 预测13:00价格
	// 🐷 加权: 根据参与预测wizards的历史评价 加权得最终结果
		// 🐷 以历史得分为概率选prophet
		// 🐷 可以考虑计算选X个prophet 计算其预测结果的均值/方差
		// 🐷 可以考虑在方差过大时 放弃交易
	// 🐷 交易: 哪个价高换成哪个 USD/ETH/... 
		// 🐷 全量Fund 转换为价高的Token
		// 🐷 交易阈值: 预测人数>=N 加权结果>=+M 或<=-M
		// 🐷 交易周期: 每1小时
		// 🐷 11:00 根据对12:00的预测 实现交易
		// 🐷 12:00 根据对13:00的预测 实现交易
	// 🐷 验证: 在T+1真实价格出现后 验证T~T+1时段预测的准确性
		// 🐷 预测值越接近真实值 得分 反之扣分 并记录
		// 🐷 评价周期: 每1小时
		// 🐷 12:00 已获取真实价格 评价10:00~11:00预测结果
		// 🐷 13:00 已获取真实价格 评价11:00~12:00预测结果
		// 🐷 给参与的wizards打分 
		// 🐷 同符号时 score += 1/(1+|diff|) 最多+1 完全预测准
		// 🐷 异符号时 score -=  最多-1 diff->∞
	// 🐷 举例: 最初Fund $1000USD
		// 🐷 11:00时 因预测12:00时ETH/USD会+$5 将USD全部换为ETH
		// 🐷 12:00时 经验证 真实+$6 给wizards打分 总资产变为$1006
		// 🐷 12:00时 因预测13:00时ETH/USD会-$10 将ETH全部换为USD
		// 🐷 13:00时 经验证 真实-$2 给wizards打分 总资产保持$1006
	// 🐷 分红: 考虑以占比形式计算 每次交易同比例涨跌
		// 🐷 仅用户存钱+取钱时计算
		// 🐷 存钱时 个人new proportion = 存入fund/(存入fund+现有fund)
			// 🐷 先更新当前全量funder资产占比
			// 🐷 再将“新资产占比”加到对应账户中
			// 🐷 资产的两种变化: 交易变化 资金池变化
				// 🐷 交易变化: 根据每次交易盈亏比例 更新各个funder资产
				// 🐷 资金池变化: 仅记录各funder资金占比 加入/撤出时 按占比计算
			// 🐷 考虑到后期交易会逐渐复杂 选择用“资金池变化”计算
		// 🐷 以占总fund比例存在
		// 🐷 取钱时 按该比例提款 

// 🐷 可以做一个模拟器
// 🐷 获取真实交易数据 模拟
// 🐷 1.模拟全员胡猜的变化过程
// 🐷 2.模拟一个先知参与的变化过程
// 🐷 3.模拟当前巨鲸平均收益率的变化过程
	// 🐷 系统中某几个用户拥有smart money“平均预测准确率”

// Add something from case Raffle
// 1.Build up a fund and allow people to invest
// 2.Pick up a weighted ramdom prophets --> Chainlink Randomess
// 3.Trade and verify every X minutes --> Chainlink Keeper
// 4.Allow people withdraw their money


// 3.Interfaces
// 4.Libraries
import "./PriceConverter.sol";

// Errors contractName__errorName
error GrowthGame__NotOwner();
error GrowthGame__LessthanFundThreshold();
error GrowthGame__NotEnoughBalance();

// 5.Contracts
/** 
 * @title growthGame Contract
 * @author RJ-W
 * @notice This contract is for finding out prophets from wizards through continuous predict game
 * @dev This price feeds from Chainlink
 */
contract growthGame {

	// 5.1 Type Declarations
	using PriceConverter for uint256;

	// 5.2 State variables
	// i_ immutable
	// s_ storage
	uint256 public immutable i_fundThreshold_usd18digit;
	address private immutable i_owner;

	struct FunderStruct {
		// 🐷 退出时 proportion置0 score长期保留 O(1)删除List中记录 维持List大小 控制遍历成本
		uint256 proportion; 	// 🐷 资产占比
		uint256 score; 			// 🐷 预测积分
		uint256 listPointer;	// 🐷 列表指针
		// 🐷 新用户 无对应listPointer
		// 🐷 下线用户 Structs与List中的address不相等
		// 🐷 在线用户 Structs与List中的address相等
	}

	address payable[] private s_fundersList;
	mapping(address => FunderStruct) private s_funderStructs;

	// address[] private s_wizards;
	// address[] private s_prophets;

	// uint256 private s_currentPrice;
	// mapping(address => int256) private s_addressToPrediction;
	// mapping(address => uint256) private s_addressToIntegration;
	AggregatorV3Interface private s_priceFeed;

	// 5.3 Events
	event fundSuccessfully(
		address indexed funder,
		uint256 indexed value
	);

	// 5.4 Errors
	// 5.5 Modifiers
	modifier onlyOwner() {
		// 🐷 require(msg.sender == i_owner);
		if (msg.sender != i_owner) revert GrowthGame__NotOwner();
		_;
	}

	// 5.6 Functions: constructor, receive, fallback, external, public, internal, private, view/pure
	constructor(address priceFeedAddress, uint256 fundThreshold) {
		s_priceFeed = AggregatorV3Interface(priceFeedAddress);
		i_owner = msg.sender;
		i_fundThreshold_usd18digit = fundThreshold * 10**18;

		// 🐷 init currentPrice
		// s_currentPrice = getCurrentPrice(s_priceFeed);
	}


	function isFunder(address funderAddress) private returns(bool isIndeed) {
		if(s_fundersList.length == 0) return false;
		return(s_fundersList[s_funderStructs[funderAddress].listPointer] == funderAddress);
	}

	/** 
	 * @notice visitor fund, then able to predict or get profit
	 * @dev spend more than fundThreshold(in USD)
	 */
	function fund() public payable {

		// 🐷 verify qualification
		if(msg.value.getConversionRate(s_priceFeed) < i_fundThreshold_usd18digit) {
			revert GrowthGame__LessthanFundThreshold();
		}

		console.log("address(this).balance: ", address(this).balance);
		// s_funders.push(payable(msg.sender));
		// s_fundersExist[msg.sender] = true;

		// 🐷 add to List and Structs
		// 1.已经在线 追加资产 仅更新Structs
		// 2.下线状态 添加资产 加入List + 更新Structs
		// 3.新用户 加入List + 加入Structs
		if(!isFunder(msg.sender)) {
			
		}
		

		// 🐷 update proportion
		// update all former account
		uint formerBalance = address(this).balance;
		
		// 🐷 add new proportion
		// s_addressToProportion[msg.sender] += msg.value / (formerBalance + msg.value);

		emit fundSuccessfully(
			msg.sender,
			msg.value
		);
	}

	/** 
	 * @notice allow funders with 
	 * @dev connect and trade with both Aave and CEX/DEX in the future
	 */
	function withdraw() public {

	}

	/** 
	 * @notice wizards predict the uplift of successor exchange rate between ETH and USD
	 * @dev init or update one's prediction
	 */
	/*
	function predict(int256 uplift) public {

		if(!(s_addressToBalance[msg.sender] > 0)) {
			revert GrowthGame__NotEnoughBalance();
		}

		s_addressToPrediction[msg.sender] = uplift;
		s_wizards.push(msg.sender);
	}
	*/

	/** 
	 * @notice owner operate the game
	 * @dev get the latest price, verify all prediction, and record
	 */
	/*
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
	*/

	/** 
	 * @notice cheaper verify with variable in memory
	 * @dev mappings can't be in memory
	 */
	/*
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
	*/

	/** 
	 * @notice prophets will stand out based on the integration records
	 * @dev elect prophets from wizards based on integration records with randomness
	 */
	function electProphets() public onlyOwner {

	}

	/** 
	 * @notice long or short ETH depends on prophets' prediction
	 * @dev connect and trade with both Aave and CEX/DEX in the future
	 */
	function trade() public onlyOwner {

	}

	/** 
	 * @notice distribute the profits or loss by a corporation to its shareholders
	 * @dev loop and traverse each account in s_addressToBalance in cheaper way
	 */
	function distribute() public onlyOwner {

	}


	function getOwner() public view returns (address) {
		return i_owner;
	}

	function getFundThreshold() public view returns (uint256) {
		return i_fundThreshold_usd18digit / 10**18;
	}

	function getFunderExist(address _address) public view returns (bool) {
		return s_fundersExist[_address];
	}

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