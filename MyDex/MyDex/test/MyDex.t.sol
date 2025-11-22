// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MyDex.sol";
import "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol"; // 使用 OpenZeppelin 提供的 ERC20Mock

contract MyDexTest is Test {
    MyDex public dex;
    ERC20Mock public usdt;
    address public owner;
    address public user;

    uint256 ethToUSDRate = 3000 * 1e18; // 1 ETH = 3000 USDT
    uint256 usdToETHRate = 1e18 / 3000; // 1 USDT = 1/3000 ETH

    function setUp() public {
        owner = address(this);
        user = address(0x123);

        // 使用 vm.deal() 为 owner 提供 1 ETH
        vm.deal(owner, 1 ether); // 确保 owner 有足够的 ETH

        // 部署OpenZeppelin的ERC20Mock模拟USDT合约
        usdt = new ERC20Mock(); // 只调用构造函数，不传参数
        // emit log_named_address("USDT Address", address(usdt));

        // 为USDT合约铸造一些初始代币
        usdt.mint(address(this), 1_000_000 * 1e18); // 给合约铸造1,000,000个USDT
        // emit log_named_uint("Minted USDT Amount", usdt.balanceOf(address(this)));

        // 部署MyDex合约
        dex = new MyDex(address(usdt), ethToUSDRate, usdToETHRate);
        // emit log_named_address("MyDex Address", address(dex));

        // 给合约发送一些USDT流动性
        usdt.transfer(address(dex), 10_000 * 1e18); // 向MyDex合约转移10,000 USDT
        // emit log_named_uint("MyDex USDT Balance", usdt.balanceOf(address(dex)));

        // 给MyDex合约发送一些ETH
        vm.deal(address(dex), 10 ether); // 向MyDex合约转移10 ETH
        // emit log_named_uint("MyDex ETH Balance", address(dex).balance);
    }

    function testSellETH() public {
        uint256 ethAmount = 1 ether; // 1 ETH
        uint256 expectedUsdtAmount = (ethAmount * ethToUSDRate) / 1e18; // 1 ETH = 3000 USDT

        // emit log("Starting testSellETH...");
        // emit log_named_uint("ETH amount being sold", ethAmount);
        // emit log_named_uint("Expected USDT amount", expectedUsdtAmount);

        // 给用户一些ETH
        vm.deal(user, ethAmount); 
        emit log_named_uint("User ETH balance after deal", user.balance);

        vm.prank(user);  // 模拟用户
        dex.sellETH{value: ethAmount}(address(usdt), expectedUsdtAmount); // 最小USDT要求为期望数量

        // emit log_named_uint("User USDT balance after sell", usdt.balanceOf(user));
        // emit log_named_uint("Dex contract ETH balance", address(dex).balance);
        // emit log_named_uint("Dex contract USDT balance", usdt.balanceOf(address(dex)));

        // 检查用户的USDT余额是否等于预期的USDT数量
        assertEq(usdt.balanceOf(user), expectedUsdtAmount, "User USDT balance does not match expected amount");
        // 检查用户USDT余额是否等于预期的USDT数量
        assertEq(usdt.balanceOf(user), expectedUsdtAmount, "User USDT balance does not match expected amount");
        
        // 确保合约中的ETH余额符合预期  
        assertEq(address(dex).balance, 10 ether + ethAmount, "Dex contract ETH balance does not match expected amount");
        // 确保合约中的USDT余额符合预期
        uint256 expectedRemainingUsdtBalance = 10_000 * 1e18 - expectedUsdtAmount;
        assertEq(usdt.balanceOf(address(dex)), expectedRemainingUsdtBalance, "Dex contract USDT balance does not match expected amount");
    }

    function testBuyETH() public {
        uint256 usdtAmount = 3000 * 1e18; // 3000 USDT
        uint256 expectedEthAmount = (usdtAmount * usdToETHRate) / 1e18; // 3000 USDT = 1 ETH

        emit log("Starting testBuyETH...");
        emit log_named_uint("USDT amount being sold", usdtAmount); // 显示在售的USDT数量
        emit log_named_uint("Dex contract ETH balance", address(dex).balance); // 显示已有的ETH数量
        emit log_named_uint("Expected ETH amount", expectedEthAmount);

        // 给用户一些USDT
        usdt.transfer(user, usdtAmount);
        emit log_named_uint("User USDT balance after transfer", usdt.balanceOf(user));

        vm.prank(user);
        usdt.approve(address(dex), usdtAmount); // 授权USDT
        emit log("User approved USDT for dex contract");

        // 用户进行买入ETH操作
        vm.prank(user);
        dex.buyETH(address(usdt), usdtAmount, expectedEthAmount); // 最小ETH要求为期望数量

        emit log_named_uint("User USDT balance after buyETH", usdt.balanceOf(user));
        emit log_named_uint("User ETH balance after buyETH", user.balance);
        emit log_named_uint("Dex contract USDT balance after buyETH", usdt.balanceOf(address(dex)));
        emit log_named_uint("Dex contract ETH balance after buyETH", address(dex).balance);

        // 检查用户的USDT余额应为0
        assertEq(usdt.balanceOf(user), 0, "User USDT balance should be 0");

        // 检查用户的ETH余额应等同于预期数量
        assertEq(user.balance, expectedEthAmount, "User ETH balance does not match expected amount");
        
        // 检查合约的USDT余额是否增加了预期数量
        assertEq(usdt.balanceOf(address(dex)), 10_000 * 1e18 + usdtAmount, "Dex contract USDT balance does not match expected amount");

        // 检查合约的ETH余额是否减少了预期数量
        assertEq(address(dex).balance, 10 ether - expectedEthAmount, "Dex contract ETH balance does not match expected amount");
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
        uint256 initialOwnerBalance = owner.balance;
        emit log_named_uint("Owner initial ETH balance", initialOwnerBalance);
        emit log_named_uint("Dex contract ETH balance before withdrawal", address(dex).balance);

        dex.withdrawETH(ethAmount); // 调用 withdrawETH 函数

        // 第四步：记录提取后的余额
        emit log_named_uint("Dex contract ETH balance after withdrawal", address(dex).balance);
        emit log_named_uint("Owner ETH balance after withdrawal", owner.balance);

        // 第五步：断言检查所有者的余额是否增加
        assertEq(owner.balance, initialOwnerBalance + ethAmount, "Owner's ETH balance did not increase as expected");
    }
    // 接收 ETH
    receive() external payable {}
}
