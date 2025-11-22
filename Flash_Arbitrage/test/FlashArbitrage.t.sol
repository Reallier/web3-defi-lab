// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MyTokenA.sol";
import "../src/MyTokenB.sol";
import "../src/LiquidityPoolManager.sol";
import "../src/FlashArbitrage.sol";

contract FlashArbitrageTest is Test {
    MyTokenA tokenA;
    MyTokenB tokenB;
    LiquidityPoolManager poolManager;
    FlashArbitrage arbitrage;

    function setUp() public {
        tokenA = new MyTokenA(1000000 * 10 ** 18);
        tokenB = new MyTokenB(1000000 * 10 ** 18);
        poolManager = new LiquidityPoolManager(0xYourUniswapFactoryAddress, 0xYourUniswapRouterAddress);
        poolManager.createLiquidityPool(address(tokenA), address(tokenB));
        arbitrage = new FlashArbitrage(0xYourUniswapRouterAddress, address(poolManager), address(poolManager));
    }

    function testArbitrage() public {
        uint amountA = 1000 * 10 ** 18;
        uint amountB = 800 * 10 ** 18;
        tokenA.approve(address(poolManager), amountA);
        tokenB.approve(address(poolManager), amountB);
        poolManager.addLiquidity(address(tokenA), address(tokenB), amountA, amountB);
        arbitrage.startArbitrage(amountA);
        uint tokenABalance = tokenA.balanceOf(address(arbitrage));
        uint tokenBBalance = tokenB.balanceOf(address(arbitrage));
        require(tokenABalance > amountA, "Arbitrage failed: Not enough TokenA");
        require(tokenBBalance > 0, "Arbitrage failed: No TokenB acquired");
    }
}
