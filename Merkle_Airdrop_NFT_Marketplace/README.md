# AirdopMerkleNFTMarket

以太坊的智能合约，旨在通过 Merkle 树验证的白名单系统，为用户提供 NFT 空投功能，同时支持 ERC20 代币的预授权支付。此合约允许合格用户以 50% 的折扣领取特定的 NFT，并集成了 EIP-2612 的 permit 功能，简化了代币支付过程。

主要功能
Merkle 树验证：

合约使用 Merkle 树根节点（merkleRoot）来验证用户是否在白名单中。用户可以通过提交其地址的 Merkle 证明来确认其资格。
NFT 领取：

合约允许用户在确认其资格后领取 NFT。用户需要支付 NFT 原价的 50%（以 ERC20 代币形式支付）。
代币预授权：

用户可以使用 permitPrePay 函数，授权合约从其账户中安全转移指定数量的 ERC20 代币，以支付 NFT 的费用。这通过 EIP-2612 的 permit 方法实现，避免了用户必须先将代币转移到合约中的步骤。
多调用支持：

合约提供了 permitAndClaim 函数，允许用户在单个交易中同时执行代币授权和 NFT 领取操作，提升了用户体验和交易效率。
事件
NFTClaimed：每当用户成功领取 NFT 时，合约将触发此事件，记录领取用户的地址和对应的 NFT 代币 ID。
状态变量
token：用于支付的 ERC20 代币合约地址。
nft：存储 NFT 的 ERC721 合约地址。
merkleRoot：Merkle 树的根节点，用于用户验证。
hasClaimed：映射，跟踪每个用户是否已经领取过 NFT。
安全性
合约使用 OpenZeppelin 提供的库，包括 SafeERC20 来确保 ERC20 代币的安全转移，以及 MerkleProof 来验证 Merkle 树的有效性。这些库为合约的安全性提供了强有力的保障。

# AirdropMerkleNFTMarketTest 测试
测试 AirdropMerkleNFTMarket 合约的智能合约，利用 Forge 测试框架验证合约的功能和逻辑。该测试合约包括模拟的 ERC721 NFT 和 ERC20 代币合约，以便进行全面的功能测试，确保 Airdrop 合约按预期工作。

主要功能
模拟 NFT 和代币合约：

MockNFT 合约模拟 ERC721 NFT，允许铸造和转移 NFT。
MockToken 合约模拟 ERC20 代币，支持代币的铸造和使用 EIP-2612 的 permit 功能。
Merkle 树设置：

setUpMerkleTree 函数用于创建 Merkle 树和生成用户的 Merkle 证明，确保测试过程中能够验证用户是否在白名单中。
合约部署与初始化：

在 setUp 函数中，测试合约部署了 MockNFT 和 MockToken，设置了 Merkle 树，部署 AirdropMerkleNFTMarket 合约，并为市场合约铸造 NFT 和分配 ERC20 代币。
白名单验证测试：

testVerifyUserInWhitelist 函数验证用户是否在白名单中，确保 verifyUser 函数正常工作。
permit 授权和 NFT 领取测试：

testPermitAndClaim 函数模拟用户签名 permit 消息，使用 permitAndClaim 函数进行代币授权和 NFT 领取的测试，确保用户能够在一次交易中完成两项操作。
安全性与可靠性
测试合约确保了对 AirdropMerkleNFTMarket 合约的全面测试，包括正确性、权限控制和状态变化。通过对不同功能的单元测试，确保了合约在不同情况下的稳健性和安全性。

重要状态变量
market：指向正在测试的 AirdropMerkleNFTMarket 合约实例。
nft：模拟的 NFT 合约实例。
token：模拟的 ERC20 代币合约实例。
user：用于测试的用户地址。
merkleRoot 和 proof：用于验证用户白名单资格的 Merkle 树根和证明。
nftTokenId：待领取的 NFT 代币 ID。
discountPrice：用户在领取 NFT 时需要支付的折扣价格。