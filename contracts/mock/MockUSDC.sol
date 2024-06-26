// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    uint8 private _decimals = 6;
    constructor() ERC20("Mock USDC", "MUSDC"){
        _mint(msg.sender,1000000000 * 10 ** 6);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
    function mint() external {
        _mint(msg.sender,10000 * 10 ** 6);
    }
}