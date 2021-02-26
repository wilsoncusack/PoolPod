pragma solidity ^0.6.12;
import '@pooltogether/pooltogether-contracts/contracts/prize-pool/PrizePoolInterface.sol';
import '@pooltogether/pooltogether-contracts/contracts/prize-strategy/PeriodicPrizeStrategy.sol';
import './interfaces/IERC20.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";

import "hardhat/console.sol";

contract PoolPod {
	using SafeMath for uint256;
	
	address public pAsset;
	address public asset;
	address public pool;
	address public prizeStrategy;

	
	uint256 public SCALAR = 1e10;
	uint256 private _multiplier = 1e10;
	mapping (address => uint256) _balances;

	uint256 private _totalShares;

	constructor(address _pAsset, address _asset, address _pool, address _prizeStrategy) public {
		pAsset = _pAsset;
		asset = _asset;
		pool = _pool;
		prizeStrategy = _prizeStrategy;
		IERC20(asset).approve(pool, type(uint256).max);

		// delete me! 
		IERC20(pAsset).approve(pool, type(uint256).max);
	}

	function assetsOwned() public view returns(uint256){
		return IERC20(asset).balanceOf(address(this)) + IERC20(pAsset).balanceOf(address(this));
	}

	function nonCommittedFunds() public view returns(uint256){
		return IERC20(asset).balanceOf(address(this));
	}

	function updateMultiplier() public {
		_multiplier = getCurMultiplier();
	}

	function getCurMultiplier() public view returns(uint256 newMultiplier){
		if(_totalShares == 0){
			return _multiplier;
		}

		return assetsOwned().mul(SCALAR).div(_totalShares);
	}

	function balanceOf(address account) public view returns(uint256) {
		return _balances[account].mul(getCurMultiplier()).div(SCALAR);
	}

	function contribute(uint256 amount) external {
		require(!PeriodicPrizeStrategy(prizeStrategy).isRngRequested(), 
			"PoolPod: Cannot contribute while prize is being awarded");
		updateMultiplier();
		IERC20(asset).transferFrom(msg.sender, address(this), amount);
		uint256 newShares = amount.mul(SCALAR).div(_multiplier);
		_totalShares = _totalShares + newShares;
		_balances[msg.sender] = _balances[msg.sender] + newShares;

	}


	function commit() external {
		uint256 amount = nonCommittedFunds();
		PrizePoolInterface(pool).depositTo(address(this), amount, asset, address(0));
	}

	function withdraw(uint256 amount) external {
		// recomputeShares(msg.sender);
		updateMultiplier();
		uint256 balance = balanceOf(msg.sender);
		balance.sub(amount, "PoolPod: withdraw amount exceeds balance");
		uint256 amountAsShares = amount.mul(SCALAR).div(_multiplier);

		uint256 notCommittedFunds = nonCommittedFunds();	
		if(notCommittedFunds >= amount){
			IERC20(asset).transfer(msg.sender, amount);
		} else {
			uint256 fee = PrizePoolInterface(pool).withdrawInstantlyFrom(address(this), amount - notCommittedFunds, asset, type(uint256).max);
			IERC20(asset).transfer(msg.sender, amount - fee);
		}
		// _knownPAssetHoldings = pAssetsOwned();
		_balances[msg.sender] = _balances[msg.sender] - amountAsShares;
		_totalShares = _totalShares - amountAsShares;
	}
}
