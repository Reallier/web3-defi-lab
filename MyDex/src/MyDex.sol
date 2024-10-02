// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MyDex {
    using SafeERC20 for IERC20; // 使用SafeERC20库

    address public owner;
    uint256 public ethToUSDRate; // ETH 兑换 USDT 的汇率
    uint256 public usdToETHRate; // USDT 兑换 ETH 的汇率
    IERC20 public usdt; // USDT 合约实例

    event SoldETH(address indexed user, uint256 ethAmount, uint256 usdtAmount);
    event BoughtETH(address indexed user, uint256 usdtAmount, uint256 ethAmount);

    constructor(address usdtAddress, uint256 _ethToUSDRate, uint256 _usdToETHRate) {
        owner = msg.sender;
        usdt = IERC20(usdtAddress);
        ethToUSDRate = _ethToUSDRate;
        usdToETHRate = _usdToETHRate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    /**
     * @dev 卖出ETH，兑换成 buyToken
     *      msg.value 为出售的ETH数量
     * @param buyToken 兑换的目标代币地址，要求是USDT地址
     * @param minBuyAmount 要求最低兑换到的 buyToken 数量
     */
    function sellETH(address buyToken, uint256 minBuyAmount) external payable {
        require(buyToken == address(usdt), "Can only buy USDT");
        
        // 使用汇率计算USDT数量，增加精度
        uint256 usdtAmount = (msg.value * ethToUSDRate) / 1e18;
        require(usdtAmount >= minBuyAmount, "Slippage: minimum USDT amount not met");

        // 从合约余额转移USDT到用户
        require(usdt.balanceOf(address(this)) >= usdtAmount, "Insufficient USDT in contract");
        usdt.safeTransfer(msg.sender, usdtAmount);

        emit SoldETH(msg.sender, msg.value, usdtAmount);
    }

    /**
     * @dev 买入ETH，用 sellToken 兑换
     * @param sellToken 出售的代币地址，要求是USDT地址
     * @param sellAmount 出售的代币数量
     * @param minBuyAmount 要求最低兑换到的ETH数量
     */
    function buyETH(address sellToken, uint256 sellAmount, uint256 minBuyAmount) external {
        require(sellToken == address(usdt), "Can only sell USDT");
        
        // 使用汇率计算ETH数量，增加精度
        uint256 ethAmount = (sellAmount * usdToETHRate) / 1e18;
        require(ethAmount >= minBuyAmount, "Slippage: minimum ETH amount not met");

        // 从用户转移USDT到合约
        usdt.safeTransferFrom(msg.sender, address(this), sellAmount);
        
        // 向用户发送ETH
        require(address(this).balance >= ethAmount, "Insufficient ETH in contract");
        payable(msg.sender).transfer(ethAmount);

        emit BoughtETH(msg.sender, sellAmount, ethAmount);
    }

    // 允许合约所有者更新汇率
    function updateRates(uint256 _ethToUSDRate, uint256 _usdToETHRate) external onlyOwner {
        ethToUSDRate = _ethToUSDRate;
        usdToETHRate = _usdToETHRate;
    }

    // 允许所有者提取合约中的USDT
    function withdrawUSDT(uint256 amount) external onlyOwner {
        require(usdt.balanceOf(address(this)) >= amount, "Insufficient USDT in contract");
        usdt.safeTransfer(owner, amount);
    }

    // 允许所有者提取合约中的ETH
    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH in contract");
        payable(owner).transfer(amount);
    }

    // 接收 ETH
    receive() external payable {}
}
