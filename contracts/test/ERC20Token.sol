//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


// This is the main building block for smart contracts.
contract ERC20Token is ERC20 {
    using SafeMath for uint256;

    constructor() public ERC20("Fake DAI", "FDAI") {
        _mint(msg.sender, 1e16 * (10 ** uint256(decimals())));
    }
}
