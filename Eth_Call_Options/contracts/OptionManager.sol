// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OptionToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OptionManager is Ownable {
    OptionToken public optionToken;
    uint256 public strikePrice;
    uint256 public expiryDate;
    
    constructor(uint256 _strikePrice, uint256 _expiryDate) {
        strikePrice = _strikePrice;
        expiryDate = _expiryDate;
        optionToken = new OptionToken(address(this), "CallOption", "CLOP");
    }
    
    function mintOption(uint256 ethAmount) external payable onlyOwner {
        require(msg.value == ethAmount, "ETH amount mismatch");
        // 假设每个ETH对应1个期权Token
        optionToken.mint(msg.sender, ethAmount);
    }
    
    function exerciseOption(uint256 tokenAmount) external {
        require(block.timestamp <= expiryDate, "Option expired");
        require(tokenAmount * strikePrice <= address(this).balance, "Insufficient funds to exercise");
        
        optionToken.burnFrom(msg.sender, tokenAmount);
        payable(msg.sender).transfer(tokenAmount * strikePrice);
    }
    
    function expireOptions() external onlyOwner {
        require(block.timestamp > expiryDate, "Option not expired yet");
        optionToken.burn(optionToken.totalSupply());
        payable(owner()).transfer(address(this).balance);
    }
}
