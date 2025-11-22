// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FlashSwapArbitrage is Ownable {
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Pair public poolA; // Pool for TokenA
    IUniswapV2Pair public poolB; // Pool for TokenB

    event FlashSwapExecuted(address indexed tokenA, address indexed tokenB, uint amountIn, uint amountOut);

    constructor(address _router, address _poolA, address _poolB) {
        uniswapRouter = IUniswapV2Router02(_router);
        poolA = IUniswapV2Pair(_poolA);
        poolB = IUniswapV2Pair(_poolB);
    }

    function executeFlashSwap(uint amount) external onlyOwner {
        // 从 PoolA 借入 TokenA
        (address token0,) = (address(poolA).token0() < address(poolA).token1()) ? (address(poolA).token0(), address(poolA).token1()) : (address(poolA).token1(), address(poolA).token0());
        poolA.swap(amount, 0, address(this), new bytes(0));
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external {
        require(msg.sender == address(poolA), "Unauthorized");

        // 使用借入的 TokenA 在 PoolB 兑换为 TokenB
        uint amountToRepay = amount0 + (amount0 * 3) / 997 + 1; // 计算还款金额

        // 在 PoolB 进行兑换
        uint amountOutMin = calculateMinOutput(amount0); // 计算最小输出
        uint amountReceived = swapInPoolB(amount0, amountOutMin); // 在 PoolB 中兑换

        // 确保兑换收益足够偿还
        require(amountReceived >= amountToRepay, "Insufficient amount to repay");

        // 将 TokenB 还回 PoolA
        IERC20(address(poolB)).transfer(address(poolA), amountToRepay);

        emit FlashSwapExecuted(address(poolA), address(poolB), amount0, amountReceived);
    }

    function calculateMinOutput(uint amount) internal pure returns (uint) {
        uint slippage = 5; // 5% 滑点
        return (amount * (100 - slippage)) / 100;
    }

    function swapInPoolB(uint amountIn, uint amountOutMin) internal returns (uint) {
        // 交换的具体实现
        (address token0, address token1) = (address(poolB).token0() < address(poolB).token1()) ? (address(poolB).token0(), address(poolB).token1()) : (address(poolB).token1(), address(poolB).token0());
        
        // 计算 token1 的数量
        (uint reserve0, uint reserve1,) = poolB.getReserves();
        uint amountOut = getAmountOut(amountIn, reserve0, reserve1);
        
        require(amountOut >= amountOutMin, "Insufficient output amount");

        // 进行交换
        IERC20(token0).transfer(address(poolB), amountIn);
        poolB.swap(0, amountOut, address(this), new bytes(0));

        return amountOut; // 返回实际兑换获得的金额
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint) {
        require(amountIn > 0, "Invalid amount");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");
        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}
