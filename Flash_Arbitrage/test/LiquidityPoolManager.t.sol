// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MyTokenA.sol";
import "../src/MyTokenB.sol";
import "../src/LiquidityPoolManager.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract LiquidityPoolManagerTest is Test {
    MyTokenA tokenA;
    MyTokenB tokenB;
    LiquidityPoolManager poolManager;

    address owner;

    // 模拟的 Uniswap V2 工厂和路由地址（需要替换为实际地址）
    address private constant factoryAddress = 0x1234567890123456789012345678901234567890;
    address private constant routerAddress = 0x0987654321098765432109876543210987654321;

    function setUp() public {
        // 部署代币 A 和代币 B
        tokenA = new MyTokenA(1000 * 10 ** 18);
        tokenB = new MyTokenB(1000 * 10 ** 18);

        // 部署流动性池管理合约，提供模拟的工厂和路由地址
        poolManager = new LiquidityPoolManager(factoryAddress, routerAddress);
        
        // 获取合约拥有者
        owner = msg.sender;
    }

    function testCreateLiquidityPool() public {
        // 确保流动性池尚未创建
        address pair = poolManager.factory().getPair(address(tokenA), address(tokenB));
        assertEq(pair, address(0), "Liquidity pool should not exist yet");

        // 创建流动性池
        poolManager.createLiquidityPool(address(tokenA), address(tokenB));

        // 确保流动性池已创建
        pair = poolManager.factory().getPair(address(tokenA), address(tokenB));
        assert(pair != address(0), "Liquidity pool should exist now");
    }

    function testAddLiquidity() public {
        // 创建流动性池
        poolManager.createLiquidityPool(address(tokenA), address(tokenB));

        // 确保流动性池已经创建
        address pairAddress = poolManager.factory().getPair(address(tokenA), address(tokenB));
        require(pairAddress != address(0), "Liquidity pool must exist");

        // 授权代币 A 和代币 B 使用
        tokenA.approve(address(poolManager), 100 * 10 ** 18);
        tokenB.approve(address(poolManager), 100 * 10 ** 18);

        // 添加流动性
        poolManager.addLiquidity(address(tokenA), address(tokenB), 100 * 10 ** 18, 100 * 10 ** 18);

        // 验证流动性池的状态
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        
        uint112 reserveA;
        uint112 reserveB;
        (reserveA, reserveB, ) = pair.getReserves();

        // 检查流动性池中的代币余额
        assertEq(reserveA, 100 * 10 ** 18, "Token A reserve should be 100");
        assertEq(reserveB, 100 * 10 ** 18, "Token B reserve should be 100");
    }
}
