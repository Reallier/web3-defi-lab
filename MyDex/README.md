# MyDex

一个简单的去中心化交易所 (DEX) 智能合约项目，允许用户在 ETH 和 USDT 之间进行兑换操作。基于 Solidity 开发，使用 Foundry 作为开发工具链。

## 项目描述

MyDex 是一个简化的 DEX 合约，实现了基本的代币兑换功能。用户可以出售 ETH 购买 USDT，或使用 USDT 购买 ETH。合约支持滑点保护、管理员权限管理和事件日志记录。

## 功能特性

### 核心功能
- **出售 ETH 兑换 USDT**: 用户发送 ETH，根据当前汇率获得 USDT，支持最小兑换数量设置以防止滑点。
- **购买 ETH 使用 USDT**: 用户发送 USDT，根据汇率获得 ETH，支持最小兑换数量设置。
- **汇率管理**: 合约所有者可以更新 ETH/USDT 和 USDT/ETH 的汇率。
- **管理员提取**: 所有者可以提取合约中的 USDT 或 ETH。

### 安全特性
- 使用 OpenZeppelin 的 SafeERC20 库确保代币安全转移。
- 滑点保护机制。
- 所有权检查，确保只有合约所有者能执行敏感操作。
- 事件日志记录所有交易和提取操作。

## 架构

### 合约结构
- `MyDex.sol`: 主合约，包含所有兑换逻辑。
- `MyDexTest.sol`: 测试合约，使用 Foundry 测试框架验证功能。

### 依赖
- **Solidity**: ^0.8.0
- **OpenZeppelin Contracts**: 用于 ERC20 接口和 SafeERC20 库。
- **Forge Std**: Foundry 的测试库。

## 安装和设置

### 前置要求
- [Foundry](https://book.getfoundry.sh/getting-started/installation.html)
- Git

### 克隆项目
```bash
git clone <repository-url>
cd MyDex
```

### 安装依赖
```bash
forge install
```

这将安装 OpenZeppelin 合约和其他依赖。

## 使用

### 编译合约
```bash
forge build
```

### 运行测试
```bash
forge test
```

### 格式化代码
```bash
forge fmt
```

### 生成 Gas 快照
```bash
forge snapshot
```

### 本地节点
启动本地 Ethereum 节点：
```bash
anvil
```

### 部署合约
使用脚本部署到网络：
```bash
forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

注意：部署脚本可能需要根据实际需求修改。

## 测试

项目包含全面的测试套件，覆盖所有主要功能：

- `testSellETH()`: 测试出售 ETH 兑换 USDT。
- `testBuyETH()`: 测试使用 USDT 购买 ETH。
- `testUpdateRates()`: 测试汇率更新。
- `testWithdrawUSDT()`: 测试提取 USDT。
- `testWithdrawETH()`: 测试提取 ETH。

运行测试：
```bash
forge test -v
```

## 贡献

欢迎贡献！请遵循以下步骤：

1. Fork 项目。
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)。
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)。
4. 推送到分支 (`git push origin feature/AmazingFeature`)。
5. 打开 Pull Request。

## 许可证

本项目基于 MIT 许可证开源。详情请见 [LICENSE](LICENSE) 文件。

## 联系

如有问题或建议，请通过以下方式联系：
- 邮箱: [your-email@example.com]
- GitHub Issues: [项目 Issues 页面]

---

## Foundry 工具链

**Foundry** 是一个快速、可移植和模块化的 Ethereum 应用开发工具包，用 Rust 编写。

组成：
- **Forge**: Ethereum 测试框架（类似 Truffle、Hardhat 和 DappTools）。
- **Cast**: 与 EVM 智能合约交互的瑞士军刀，用于发送交易和获取链上数据。
- **Anvil**: 本地 Ethereum 节点，类似于 Ganache、Hardhat Network。
- **Chisel**: 快速、实用且详细的 Solidity REPL。

文档: https://book.getfoundry.sh/

### 其他命令
- 帮助: `forge --help`, `anvil --help`, `cast --help`
