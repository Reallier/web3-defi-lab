
# MyDex 合约
MyDex 是一个简单的去中心化交易所 (DEX) 合约，允许用户在 ETH 和 USDT 之间进行兑换操作。合约基于预定义的汇率，并使用 OpenZeppelin 的 SafeERC20 库来安全地处理 USDT 转账。

主要功能：
## 出售 ETH 兑换 USDT
用户可以向合约发送 ETH，并根据当前的汇率获得 USDT。合约会检查合约中是否有足够的 USDT 余额，并通过设定最低可接受的 USDT 数量来防止滑点。

## 购买 ETH 使用 USDT
用户可以向合约发送 USDT，并根据汇率获得 ETH。合约确保有足够的 ETH 来满足请求，并支持通过设定最低可接受的 ETH 数量来避免滑点。

## 自定义汇率
合约的所有者（你）可以随时更新 ETH/USDT 和 USDT/ETH 的汇率，方便根据市场情况调整兑换比例。

## 管理员权限
合约的所有者有权限提取合约中积累的 USDT 或 ETH。这些提取功能受到所有权检查的保护，确保只有合约的所有者才能执行。

## 安全保障
合约使用 SafeERC20 来确保代币的安全转移，避免代币卡在合约中的问题。它还通过检查滑点并确保转账前有足够的余额来保证交易的顺利进行。

## 事件日志记录
每次交易（无论是买卖还是提取）都会通过事件进行记录，方便在链上进行追踪。

# MyDexTest 测试用例
MyDexTest 合约使用 Foundry 测试框架来验证 MyDex 智能合约的核心功能。它通过模拟 ETH 和 USDT 的兑换操作，确保合约逻辑的正确性，并且可以通过修改汇率或提取资金来测试管理员权限。为了测试方便，我们使用了 OpenZeppelin 的 ERC20Mock 作为模拟的 USDT 合约。

主要测试场景：
testSellETH()

## 模拟用户出售 ETH 并兑换成 USDT 的场景。
检查兑换后的用户 USDT 余额是否正确、合约内的 ETH 和 USDT 余额是否与预期匹配。
testBuyETH()

## 测试用户使用 USDT 购买 ETH 的功能。
验证用户的 USDT 和 ETH 余额在兑换后的变化，确保合约中 USDT 和 ETH 的余额与计算结果一致。
testUpdateRates()

## 测试合约所有者更新 ETH/USDT 和 USDT/ETH 汇率的功能。
确保汇率更新后，合约中的汇率变量与新值一致。
testWithdrawUSDT()

## 检查合约所有者提取 USDT 的功能。
验证所有者的 USDT 余额增加是否符合预期。
testWithdrawETH()

## 测试所有者提取合约中的 ETH。
记录提取后合约和所有者的 ETH 余额变化，确保提取操作的正确性。
其他功能：
setUp() 函数
每次测试运行前，合约会部署一个新的 MyDex 合约，并初始化 10,000 USDT 和 10 ETH 的流动性，同时为测试用户和所有者设置初始余额。

## 日志记录
每个测试用例都使用 emit log 和 log_named_uint 来记录测试过程中的关键数据，方便调试和验证。


## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
