# BaseERC20 代币

## 概述

`BaseERC20` 合约是 ERC20 代币标准的基本实现，支持代币转账、铸造、烧毁以及基于角色的访问控制，以便于管理代币的所有权和权限。

## 特性

- **标准 ERC20 功能**：包含代币转账、批准额度、查询余额和额度等功能。
- **铸造与烧毁**：支持铸造新代币和烧毁现有代币，以管理总供应量。
- **基于角色的访问控制**：仅允许授权账户铸造新代币或更改角色。
- **账户冻结功能**：允许所有者冻结账户，防止其转账。

## 需求

- **Solidity 版本**：`^0.8.0`
- **OpenZeppelin Contracts**（用于安全和实用功能）

## 合约结构

- **状态变量**：
  - `name`：代币的名称。
  - `symbol`：代币的符号。
  - `decimals`：代币的小数位数。
  - `totalSupply`：代币的总供应量。
  - 映射表用于存储余额、额度、冻结账户和角色。

- **事件**：
  - `Transfer`：代币转账时触发。
  - `Approval`：批准额度时触发。
  - `FrozenFunds`：账户资金被冻结或解冻时触发。
  - `Burn`：代币被烧毁时触发。
  - `Mint`：新代币被铸造时触发。
  - `SetRole`：用户角色被设置或修改时触发。

## 安装

1. **克隆仓库**：
   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **安装依赖**：
   ```bash
   npm install
   ```

## 使用

1. **部署合约**：使用 Hardhat 或 Truffle 的部署脚本来部署 `BaseERC20` 合约。

2. **与合约交互**：
   - **转账代币**：调用 `transfer(address recipient, uint256 amount)`。
   - **铸造代币**：调用 `mint(address to, uint256 amount)`（仅限所有者调用）。
   - **烧毁代币**：调用 `burn(uint256 amount)` 来销毁您账户中的代币。
   - **冻结账户**：使用 `freezeAccount(address target, bool freeze)` 来限制用户的代币转账能力。
   - **角色管理**：使用 `setRole(address user, bytes32 role, bool active)` 来分配或撤销角色。

## 示例代码

```javascript
const BaseERC20 = await ethers.getContractFactory("BaseERC20");
const token = await BaseERC20.deploy();
await token.deployed();

const [owner, addr1] = await ethers.getSigners();

// 转账代币
await token.transfer(addr1.address, 100);

// 铸造新代币
await token.mint(owner.address, 50);

// 烧毁代币
await token.burn(10);
```

## 安全注意事项

- **访问控制**：确保只有授权用户可以铸造新代币和管理角色。
- **账户冻结**：谨慎使用账户冻结功能，以避免锁定用户的资金。

## 许可证

本项目采用 MIT 许可证。

---

## 测试框架

使用 Mocha 测试框架和 Chai 断言库，结合 Hardhat 提供的功能进行智能合约的测试。

1. **测试结构**：
   - 使用 `describe` 和 `it` 函数组织测试案例，便于结构化和理解。

2. **合约部署**：
   - `beforeEach` 钩子在每个测试之前调用 `init` 函数，确保每个测试都有一个新的合约实例，避免状态交叉影响。
   - `init` 函数负责部署合约并初始化测试账户。

3. **测试功能**：
   - **部署测试** (`describe("Deployment")`)：
     - 确保合约的所有者正确设置。
     - 确保代币的名称和符号正确。

   - **交易测试** (`describe("Transactions")`)：
     - 测试代币在账户间的转账是否正常。
     - 验证当发送者余额不足时是否会触发错误。
     - 确保转账后余额更新正确。

   - **铸造与烧毁** (`describe("Minting and Burning")`)：
     - 测试铸造新代币是否正确更新账户余额。
     - 验证烧毁代币功能，确保总供应量和账户余额按预期减少。
     - 检查尝试烧毁超过余额的情况是否会失败。

   - **角色管理** (`describe("Role Management")`)：
     - 测试合约所有者能够添加新所有者和移除现有所有者的权限。
     - 验证非所有者尝试添加所有者时是否会失败。

4. **错误处理**：
   - 使用 `expect` 来断言特定条件的正确性，确保合约的行为符合预期。
   - 使用 `to.be.revertedWith` 来验证错误消息，以确保错误处理机制正常工作。

5. **代码可读性**：
   - 代码中的注释清晰明了，帮助理解每个测试的目的和逻辑。
   - 使用 `BigInt` 进行大整数比较，避免了潜在的精度问题。
---
如果使用 pnpm

```shell
pnpm i
pnpm run test
```

如果使用 bun

```shell
bun i
bun run test
```


实现以下功能：

- 设置 Token 名称（name）："BaseERC20"
- 设置 Token 符号（symbol）："BERC20"
- 设置 Token 小数位 decimals：18
- 设置 Token 总量（totalSupply）:100,000,000
- 允许任何人查看任何地址的 Token 余额（balanceOf）
- 允许 Token 的所有者将他们的 Token 发送给任何人（transfer）；转帐超出余额时抛出异常(require),并显示错误消息 “ERC20: transfer amount exceeds balance”。
- 允许 Token 的所有者批准某个地址消费他们的一部分 Token（approve）
- 允许任何人查看一个地址可以从其它账户中转账的代币数量（allowance）
- 允许被授权的地址消费他们被授权的 Token 数量（transferFrom）；
- 转帐超出余额时抛出异常(require)，异常信息：“ERC20: transfer amount exceeds balance”
- 转帐超出授权数量时抛出异常(require)，异常消息：“ERC20: transfer amount exceeds allowance”。

遵循 ERC20 标准的同时，考虑到安全性，确保转账和授权功能在任何时候都能正常运行无误。

以下是针对您的 ERC20 代币项目的 README 模板，使用中文编写：

---