// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MyDex.sol";
import "../src/ERC20Mock.sol"; // 模拟的USDT合约

contract MyDexTest is Test {
    MyDex public dex;
    ERC20Mock public usdt;
    address public owner;
    address public user;

    uint256 ethToUSDRate = 3000 * 1e18; // 1 ETH = 3000 USDT
    uint256 usdToETHRate = 333 * 1e18;  // 1 USDT = 0.333 ETH

    function setUp() public {
        owner = address(this);
        user = address(0x123);

        // 部署模拟USDT合约
        usdt = new ERC20Mock("USDT", "USDT", 1_000_000 * 1e18);

        // 部署MyDex合约
        dex = new MyDex(address(usdt), ethToUSDRate, usdToETHRate);

        // 给合约发送一些USDT流动性
        usdt.transfer(address(dex), 10_000 * 1e18);
    }

    function testSellETH() public {
        uint256 ethAmount = 1 ether; // 1 ETH
        uint256 expectedUsdtAmount = (ethAmount * ethToUSDRate) / 1e18; // 1 ETH = 3000 USDT

        // 用户发送ETH，期望得到USDT
        vm.deal(user, ethAmount); // 给用户一些ETH
        vm.prank(user);
        dex.sellETH{value: ethAmount}(address(usdt), expectedUsdtAmount / 2); // 最小USDT要求为实际的一半

        assertEq(usdt.balanceOf(user), expectedUsdtAmount); // 检查用户USDT余额
        assertEq(address(dex).balance, ethAmount); // 检查合约中的ETH余额
    }

    function testBuyETH() public {
        uint256 usdtAmount = 3000 * 1e18; // 3000 USDT
        uint256 expectedEthAmount = (usdtAmount * usdToETHRate) / 1e18; // 3000 USDT = 1 ETH

        // 给用户一些USDT
        usdt.transfer(user, usdtAmount);
        vm.prank(user);
        usdt.approve(address(dex), usdtAmount);

        vm.prank(user);
        dex.buyETH(address(usdt), usdtAmount, expectedEthAmount / 2); // 最小ETH要求为实际的一半

        assertEq(usdt.balanceOf(user), 0); // 用户USDT余额应为0
        assertGt(user.balance, expectedEthAmount); // 检查用户ETH余额
    }

    function testUpdateRates() public {
        uint256 newEthToUSDRate = 3500 * 1e18;
        uint256 newUsdToETHRate = 285 * 1e18;

        // 合约所有者更新汇率
        dex.updateRates(newEthToUSDRate, newUsdToETHRate);

        assertEq(dex.ethToUSDRate(), newEthToUSDRate);
        assertEq(dex.usdToETHRate(), newUsdToETHRate);
    }

    function testWithdrawUSDT() public {
        uint256 withdrawAmount = 1000 * 1e18;
        uint256 initialOwnerBalance = usdt.balanceOf(owner);

        // 合约所有者提取USDT
        dex.withdrawUSDT(withdrawAmount);

        assertEq(usdt.balanceOf(owner), initialOwnerBalance + withdrawAmount); // 检查所有者USDT余额
    }

    function testWithdrawETH() public {
        uint256 ethAmount = 1 ether;

        // 先给合约发送一些ETH
        vm.deal(user, ethAmount);
        vm.prank(user);
        (bool sent, ) = address(dex).call{value: ethAmount}("");
        require(sent, "Failed to send ETH");

        uint256 initialOwnerBalance = owner.balance;

        // 合约所有者提取ETH
        dex.withdrawETH(ethAmount);

        assertGt(owner.balance, initialOwnerBalance); // 检查所有者ETH余额
    }
}
