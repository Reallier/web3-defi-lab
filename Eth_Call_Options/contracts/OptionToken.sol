// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract OptionToken is ERC20Burnable {
    address public immutable minter;

    constructor(address _minter, string memory name, string memory symbol) ERC20(name, symbol) {
        require(_minter != address(0), "Minter is zero address");
        minter = _minter;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == minter, "Not authorized");
        _mint(to, amount);
    }
}
