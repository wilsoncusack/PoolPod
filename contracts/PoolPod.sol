pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import '@pooltogether/pooltogether-contracts/contracts/prize-pool/PrizePoolInterface.sol';
import '@pooltogether/pooltogether-contracts/contracts/prize-strategy/PeriodicPrizeStrategy.sol';
import '@pooltogether/pooltogether-contracts/contracts/token-faucet/TokenFaucet.sol';
import '@pooltogether/loot-box/contracts/LootBox.sol';
import './interfaces/IERC20.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";

import "hardhat/console.sol";

contract PoolPod {
	using SafeMath for uint256;
	
	address public pAsset;
	address public asset;
	address public pool;
	address public prizeStrategy;
	address public owner;
	address public poolToken;
	address public poolFaucet;

	
	uint256 public SCALAR = 1e10;
	mapping (address => uint256) _balances;

	uint256 private _totalShares;

	constructor(address _pAsset, address _asset, address _pool, address _prizeStrategy, address _poolToken, address _poolFaucet) public {
		pAsset = _pAsset;
		asset = _asset;
		pool = _pool;
		prizeStrategy = _prizeStrategy;
		IERC20(asset).approve(pool, type(uint256).max);
		owner = msg.sender;
		poolToken = _poolToken;
		poolFaucet = _poolFaucet;

		// delete me! 
		// IERC20(pAsset).approve(pool, type(uint256).max);
	}

	function assetsOwned() public view returns(uint256){
		return IERC20(asset).balanceOf(address(this)) + IERC20(pAsset).balanceOf(address(this));
	}

	function nonCommittedFunds() public view returns(uint256){
		return IERC20(asset).balanceOf(address(this));
	}

	function getCurMultiplier() public view returns(uint256 newMultiplier){
		if(_totalShares == 0){
			return SCALAR;
		}

		return assetsOwned().mul(SCALAR).div(_totalShares);
	}

	function balanceOf(address account) public view returns(uint256) {
		return _balances[account].mul(getCurMultiplier()).div(SCALAR);
	}

	function contribute(uint256 amount) external {
		require(!PeriodicPrizeStrategy(prizeStrategy).isRngRequested(), 
			"PoolPod: Cannot contribute while prize is being awarded");

		uint256 newShares = amount.mul(SCALAR).div(getCurMultiplier());
		IERC20(asset).transferFrom(msg.sender, address(this), amount);		
		_totalShares = _totalShares + newShares;
		_balances[msg.sender] = _balances[msg.sender] + newShares;

	}

	function commit() external {
		uint256 amount = nonCommittedFunds();
		PrizePoolInterface(pool).depositTo(address(this), amount, asset, address(0));
	}

	function withdraw(uint256 amount) external {
		balanceOf(msg.sender).sub(amount, "PoolPod: withdraw amount exceeds balance");
		
		uint256 amountAsShares = amount.mul(SCALAR).div(getCurMultiplier());
		
		uint256 notCommittedFunds = nonCommittedFunds();	
		if(notCommittedFunds >= amount){
			IERC20(asset).transfer(msg.sender, amount);
		} else {
			uint256 fee = PrizePoolInterface(pool).withdrawInstantlyFrom(address(this), amount - notCommittedFunds, asset, type(uint256).max);
			IERC20(asset).transfer(msg.sender, amount - fee);
		}

		_balances[msg.sender] = _balances[msg.sender] - amountAsShares;
		_totalShares = _totalShares - amountAsShares;
	}

	///// Loot Box Logic ////

	function plunder(
	   IERC20Upgradeable[] memory erc20,
	    LootBox.WithdrawERC721[] memory erc721,
	    LootBox.WithdrawERC1155[] memory erc1155,
	    address lootBoxAddress,
	    address payable to
  	) external {
  		require(msg.sender == owner, 'PoolPod: FORBIDDEN');
  		LootBox(lootBoxAddress).plunder(erc20, erc721, erc1155, to);
  	}


    function setOwner(address _owner) external {
        require(msg.sender == owner, 'PoolPod: FORBIDDEN');
        owner = _owner;
    }

    // POOL token logic 
    function claim() external {
    	TokenFaucet(poolFaucet).claim(address(this));
    }

    function transferPool(address to, uint256 amount) external {
    	require(msg.sender == owner, 'PoolPod: FORBIDDEN');
    	IERC20(poolToken).transfer(to, amount);
    }

}
