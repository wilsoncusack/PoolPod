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

	uint256 private _knownPAssetHoldings;
	uint256 private _totalShares;

	mapping (address => ContributorInfo) public getContributor;

	struct ContributorInfo {
		uint256 multOffset;
		uint256 shares;
	}
	

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

	function pAssetsOwned() public view returns(uint256){
		return IERC20(pAsset).balanceOf(address(this));
	}

	function nonCommittedFunds() public view returns(uint256){
		return IERC20(asset).balanceOf(address(this));
	}

	function updateMultiplier() public {
		uint256 assets = pAssetsOwned();
		_multiplier = getCurMultiplier(assets);
		_knownPAssetHoldings = assets;
	}

	function getCurMultiplier(uint256 assets) public view returns(uint256 newMultiplier){
		uint256 winnings = assets.sub(_knownPAssetHoldings);
		if(winnings == 0){
			return _multiplier;
		}

		return _multiplier.add(
			// winnings.mul(SCALAR).div((_pAssetsOwned + nonCommittedFunds()).sub(_knownWinningsStillHeld + winnings))
			winnings.mul(SCALAR).div(_totalShares)
			);
	}

	function balanceOf(address account) public view returns(uint256) {
		return getContributor[account]
			.shares
			.mul(getCurMultiplier(pAssetsOwned()) - getContributor[account].multOffset)
			.div(SCALAR);
	}

	function _balanceOfWithoutMultiplierUpdate(address account) private returns(uint256) {
		return getContributor[account]
			.shares
			.mul(_multiplier - getContributor[account].multOffset)
			.div(SCALAR);
	}

	function recomputeShares(address account) public {
		updateMultiplier();
		_recomputeSharesWithoutMultiplierUpdate(0, msg.sender);
		
	}

	function _recomputeSharesWithoutMultiplierUpdate(uint256 newAmount, address account) private {
		uint256 shares = _balanceOfWithoutMultiplierUpdate(msg.sender) + newAmount;
		_totalShares = _totalShares + shares - getContributor[msg.sender].shares;
		getContributor[msg.sender].shares = shares;
		getContributor[msg.sender].multOffset = _multiplier - 1e10;
	}


	function contribute(uint256 amount) external {
		// require(!PeriodicPrizeStrategy(prizeStrategy).isRngRequested(), "PoolPod: Cannot contribute while prize is being awarded")

		updateMultiplier();
		IERC20(asset).transferFrom(msg.sender, address(this), amount);
		_recomputeSharesWithoutMultiplierUpdate(amount, msg.sender);
	}


	function commit() external {
		uint256 amount = nonCommittedFunds();
		PrizePoolInterface(pool).depositTo(address(this), amount, asset, address(0));
		_knownPAssetHoldings = pAssetsOwned();
	}

	function withdraw(uint256 amount) external {
		recomputeShares(msg.sender);
		uint256 balance = getContributor[msg.sender].shares;
		balance.sub(amount, "PoolPod: withdraw amount exceeds balance");

		uint256 notCommittedFunds = nonCommittedFunds();	
		if(notCommittedFunds >= amount){
			IERC20(asset).transfer(msg.sender, amount);
		} else {
			uint256 fee = PrizePoolInterface(pool).withdrawInstantlyFrom(address(this), amount - notCommittedFunds, asset, type(uint256).max);
			IERC20(asset).transfer(msg.sender, amount - fee);
		}
		_knownPAssetHoldings = pAssetsOwned();
		getContributor[msg.sender].shares = balance.sub(amount); 
		_totalShares = _totalShares - amount;
	}
}
