// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入 Uniswap V2 工厂和路由接口
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
// 导入 ERC20 接口和可拥有的合约
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 创建流动性池管理合约，继承 Ownable
contract LiquidityPoolManager is Ownable {
    IUniswapV2Factory public factory; // Uniswap V2 工厂地址
    IUniswapV2Router02 public router; // Uniswap V2 路由地址

    // 构造函数，初始化工厂和路由地址
    constructor(address _factory, address _router) {
        factory = IUniswapV2Factory(_factory);
        router = IUniswapV2Router02(_router);
    }

    // 创建流动性池，传入代币 A 和代币 B 的地址
    function createLiquidityPool(address tokenA, address tokenB) external onlyOwner {
        factory.createPair(tokenA, tokenB); // 调用工厂合约创建流动性池
    }

    // 向流动性池添加流动性，传入代币 A 和代币 B 的地址及数量
    function addLiquidity(address tokenA, address tokenB, uint amountA, uint amountB) external onlyOwner {
        IERC20(tokenA).approve(address(router), amountA); // 授权路由合约使用代币 A
        IERC20(tokenB).approve(address(router), amountB); // 授权路由合约使用代币 B
        
        // 调用路由合约添加流动性
        router.addLiquidity(
            tokenA,
            tokenB,
            amountA,
            amountB,
            amountA,
            amountB,
            owner(),
            block.timestamp + 60 // 设置流动性过期时间
        );
    }
}
