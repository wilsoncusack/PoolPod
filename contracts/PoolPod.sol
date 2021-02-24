pragma solidity ^0.6.12;
import '@pooltogether/pooltogether-contracts/contracts/prize-pool/PrizePoolInterface.sol';
import './interfaces/IERC20.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";

import "hardhat/console.sol";

contract PoolPod {
	using SafeMath for uint256;
	
	address public pAsset;
	address public asset;
	address public poolAddress;

	
	uint256 public SCALAR = 1e18;
	uint256 private _multiplier = 1e18;
	mapping (address => uint256) _balances;

	uint256 private _knownPAssetHoldings;

	constructor(address _pAsset, address _asset, address _poolAddress) public {
		pAsset = _pAsset;
		asset = _asset;
		poolAddress = _poolAddress;
		IERC20(asset).approve(poolAddress, type(uint256).max);
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
		uint256 temp = pAssetsOwned();
		_multiplier = getCurMultiplier(temp);
		_knownPAssetHoldings = temp;
	}

	function getCurMultiplier(uint256 assets) public view returns(uint256){
		if(assets == 0){
			return _multiplier;
		}
	
		uint256 winnings = assets.sub(_knownPAssetHoldings);
		return _multiplier.add(
			winnings.mul(SCALAR).div(_knownPAssetHoldings)
			);
	}

	function balanceOf(address account) public view returns(uint256) {
		return _balances[account].mul(
			getCurMultiplier(
				pAssetsOwned()
				)
			).div(SCALAR);
	}


	function contribute(uint256 amount) external {
		updateMultiplier();
		_balances[msg.sender] = _balances[msg.sender].add(
			amount.mul(SCALAR).div(_multiplier)
			);
		IERC20(asset).transferFrom(msg.sender, address(this), amount);
	}


	function commit() external {
		uint256 amount = nonCommittedFunds();
		PrizePoolInterface(poolAddress).depositTo(address(this), amount, asset, address(0));
		_knownPAssetHoldings = _knownPAssetHoldings + amount;
	}

	function withdraw(uint256 amount) external {
		balanceOf(msg.sender).sub(amount, "PoolPod: withdraw amount exceeds balance");

		uint256 notCommittedFunds = nonCommittedFunds();		
		if(notCommittedFunds >= amount){
			IERC20(asset).transfer(msg.sender, amount);
			notCommittedFunds = notCommittedFunds - amount;
		} else {
			PrizePoolInterface(poolAddress).withdrawInstantlyFrom(address(this), amount - notCommittedFunds, asset, type(uint256).max);
			IERC20(asset).transfer(msg.sender, amount);
			_knownPAssetHoldings = _knownPAssetHoldings - amount - notCommittedFunds;
		}
		_balances[msg.sender] = _balances[msg.sender].sub(
			amount.mul(SCALAR).div(_multiplier)
			);
	}
}
