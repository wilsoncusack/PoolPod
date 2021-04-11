import '@pooltogether/pooltogether-contracts/contracts/prize-pool/PrizePoolInterface.sol';
import '../interfaces/IERC20.sol';

contract PrizePoolDummy is PrizePoolInterface {

	address private _controlledToken;
  address private _asset;
	address[] private _tokens;

	constructor(address controlledToken, address asset) public {
		_controlledToken = controlledToken;
    _asset = asset;
	}

	function withdrawInstantlyFrom(
    address from,
    uint256 amount,
    address controlledToken,
    uint256 maximumExitFee
  ) external override returns (uint256) {
		IERC20(_asset).transferFrom(from, address(this), amount);
    IERC20(controlledToken).transfer(from, amount);
    return 0;
	}

	function depositTo(
    address to,
    uint256 amount,
    address controlledToken,
    address referrer
  )
    external override {
    	IERC20(_asset).transferFrom(to, address(this), amount);
    	IERC20(_controlledToken).transfer(to, amount);
    }

	// dummy
	

    function withdrawWithTimelockFrom(
    address from,
    uint256 amount,
    address controlledToken
  ) external override returns (uint256) {
    	return 0;
    }

    function withdrawReserve(address to) external override returns (uint256) {
    	return 0;
    }

  function awardBalance() external override view returns (uint256) {
  	return 0;
  }

  function captureAwardBalance() external override returns (uint256) {
  	return 0;
  }

  function award(
    address to,
    uint256 amount,
    address controlledToken
  ) override external {

  }

 
  function transferExternalERC20(
    address to,
    address externalToken,
    uint256 amount
  ) override external {

  }


  function awardExternalERC20(
    address to,
    address externalToken,
    uint256 amount
  )
    external override {

    }

 
  function awardExternalERC721(
    address to,
    address externalToken,
    uint256[] calldata tokenIds
  )
    external override {

    }

  function sweepTimelockBalances(
    address[] calldata users
  )
    external override
    returns (uint256) {
    	return 0;
    }

  function calculateTimelockDuration(
    address from,
    address controlledToken,
    uint256 amount
  )
    external override
    returns (
      uint256 durationSeconds,
      uint256 burnedCredit
    ) {
    	return (0,0);
    }

  /// @notice Calculates the early exit fee for the given amount
  /// @param from The user who is withdrawing
  /// @param controlledToken The type of collateral being withdrawn
  /// @param amount The amount of collateral to be withdrawn
  /// @return exitFee The exit fee
  /// @return burnedCredit The user's credit that was burned
  function calculateEarlyExitFee(
    address from,
    address controlledToken,
    uint256 amount
  )
    external override
    returns (
      uint256 exitFee,
      uint256 burnedCredit
    ) {
    	return (0,0);
    }

  /// @notice Estimates the amount of time it will take for a given amount of funds to accrue the given amount of credit.
  /// @param _principal The principal amount on which interest is accruing
  /// @param _interest The amount of interest that must accrue
  /// @return durationSeconds The duration of time it will take to accrue the given amount of interest, in seconds.
  function estimateCreditAccrualTime(
    address _controlledToken,
    uint256 _principal,
    uint256 _interest
  )
    external override
    view
    returns (uint256 durationSeconds) {
    	return 0;
    }

  /// @notice Returns the credit balance for a given user.  Not that this includes both minted credit and pending credit.
  /// @param user The user whose credit balance should be returned
  /// @return The balance of the users credit
  function balanceOfCredit(address user, address controlledToken) external virtual override returns (uint256) {

  }

  /// @notice Sets the rate at which credit accrues per second.  The credit rate is a fixed point 18 number (like Ether).
  /// @param _controlledToken The controlled token for whom to set the credit plan
  /// @param _creditRateMantissa The credit rate to set.  Is a fixed point 18 decimal (like Ether).
  /// @param _creditLimitMantissa The credit limit to set.  Is a fixed point 18 decimal (like Ether).
  function setCreditPlanOf(
    address _controlledToken,
    uint128 _creditRateMantissa,
    uint128 _creditLimitMantissa
  )
    external override {

    }

  /// @notice Returns the credit rate of a controlled token
  /// @param controlledToken The controlled token to retrieve the credit rates for
  /// @return creditLimitMantissa The credit limit fraction.  This number is used to calculate both the credit limit and early exit fee.
  /// @return creditRateMantissa The credit rate. This is the amount of tokens that accrue per second.
  function creditPlanOf(
    address controlledToken
  )
    external override
    view
    returns (
      uint128 creditLimitMantissa,
      uint128 creditRateMantissa
    ) {
    	return (0,0);
    }
  /// @notice Allows the Governor to set a cap on the amount of liquidity that he pool can hold
  /// @param _liquidityCap The new liquidity cap for the prize pool
  function setLiquidityCap(uint256 _liquidityCap) external override {

  }

  /// @notice Sets the prize strategy of the prize pool.  Only callable by the owner.
  /// @param _prizeStrategy The new prize strategy.  Must implement TokenListenerInterface
  function setPrizeStrategy(TokenListenerInterface _prizeStrategy) external override {

  }

  /// @dev Returns the address of the underlying ERC20 asset
  /// @return The address of the asset
  function token() external override view returns (address) {
  	return _asset;
  }

  /// @notice An array of the Tokens controlled by the Prize Pool (ie. Tickets, Sponsorship)
  /// @return An array of controlled token addresses
  function tokens() external override view returns (address[] memory) {
  	return _tokens;
  }

  /// @notice The timestamp at which an account's timelocked balance will be made available to sweep
  /// @param user The address of an account with timelocked assets
  /// @return The timestamp at which the locked assets will be made available
  function timelockBalanceAvailableAt(address user) external override view returns (uint256) {
  	return 0;
  }

  /// @notice The balance of timelocked assets for an account
  /// @param user The address of an account with timelocked assets
  /// @return The amount of assets that have been timelocked
  function timelockBalanceOf(address user) external override view returns (uint256) {
  	return 0;
  	
  }

  /// @notice The total of all controlled tokens and timelock.
  /// @return The current total of all tokens and timelock.
  function accountedBalance() external override view returns (uint256) {
  	return 0;
  }

}