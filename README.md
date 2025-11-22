# Web3 DeFi Lab

这是一个Web3 DeFi（去中心化金融）实验室项目集合，包含多个Solidity智能合约项目和相关工具，用于学习和实践区块链开发。

## 项目结构

### 核心项目

#### 1. ERC20 Token (ERC20_tocken/)
- **描述**: 实现ERC20标准的代币合约
- **技术栈**: Solidity, Hardhat, TypeScript
- **功能**: 代币创建、转账、授权等基本功能
- **测试**: 包含完整的单元测试

#### 2. ERC721 NFT (ERC721_NFT/)
- **描述**: 实现ERC721标准的NFT合约
- **技术栈**: Solidity, Hardhat, TypeScript
- **功能**: NFT铸造、转移、查询等
- **测试**: 包含NFT相关测试用例

#### 3. DEX (去中心化交易所)
- **MyDex (MyDex/)**: 自定义DEX实现
- **Initial DEX Offering (Initial_DEX_Offering/)**: IDO相关合约

#### 4. DeFi协议
- **Flash Arbitrage (Flash_Arbitrage/)**: 闪电贷套利合约
- **Flash Presale NFT (Flash_Presale_NFT/)**: NFT预售合约
- **Staking Rewards (StakingRewards/)**: 质押奖励系统
- **Staking Pool (StakingPool/)**: 质押池合约

#### 5. 期权和衍生品
- **Eth Call Options (Eth_Call_Options/)**: 以太坊看涨期权合约

#### 6. 高级功能
- **Merkle Airdrop NFT Marketplace (Merkle_Airdrop_NFT_Marketplace/)**: 使用Merkle树进行空投的NFT市场
- **Offline Sign Rent NFT (offline_sign_rent_NFT/)**: 离线签名NFT租赁系统
- **Upgradable Proxy Contract (UpgradableProxyContract/)**: 可升级代理合约

#### 7. 基础组件
- **Big Bank (big_bank/)**: 银行合约基础实现
- **Easy Bank (easy_bank/)**: 简化版银行合约
- **Linked List (linked_list/)**: 链表数据结构实现

#### 8. 工具和基础设施
- **The Graph (thegraph/)**: GraphQL子图用于索引区块链数据
- **Viem (viem/)**: TypeScript以太坊库使用示例
- **Viem USDT Transfer Listener (viem_usdt_transfer_listener/)**: USDT转账监听器

#### 9. 学习资料
- **Solidity Interview Questions (solidity_interview_questions/)**: Solidity面试题整理
- **Smart Contract (smart_contract/)**: 智能合约相关文档
- **Blockchain Security (blockchain_security.md)**: 区块链安全指南

## 技术栈

- **智能合约**: Solidity
- **开发框架**: Hardhat, Foundry
- **测试**: Mocha, Chai, Foundry测试框架
- **前端工具**: Viem, The Graph
- **包管理**: npm, pnpm, bun, yarn

## 快速开始

### 环境要求

- Node.js >= 16
- npm 或 pnpm
- Foundry (对于使用Foundry的项目)

### 安装依赖

对于使用npm的项目：
```bash
cd ERC20_tocken
npm install
```

对于使用Foundry的项目：
```bash
cd Flash_Arbitrage
forge install
```

### 运行测试

Hardhat项目：
```bash
npx hardhat test
```

Foundry项目：
```bash
forge test
```

## 项目特点

1. **模块化设计**: 每个项目独立，易于学习和理解
2. **完整测试**: 包含全面的单元测试和集成测试
3. **最佳实践**: 遵循Solidity安全开发最佳实践
4. **多种框架**: 同时使用Hardhat和Foundry两种开发框架
5. **实用功能**: 涵盖DeFi核心功能和高级特性

## 贡献

欢迎提交Issue和Pull Request来改进这些项目。

## 许可证

MIT License