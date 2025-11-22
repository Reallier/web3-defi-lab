// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/AirdropMerkleNFTMarket.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

contract MockToken is ERC20Permit {
    constructor() ERC20("MockToken", "MTK") ERC20Permit("MockToken") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract AirdropMerkleNFTMarketTest is Test {
    AirdropMerkleNFTMarket public market;
    MockNFT public nft;
    MockToken public token;
    address public user;
    bytes32 public merkleRoot;
    bytes32[] public proof;
    uint256 public nftTokenId = 1;
    uint256 public discountPrice = 0.25 ether; // 50% 折扣，原价是 0.5 ether

    // 模拟 Merkle 树数据
    function setUpMerkleTree() internal returns (bytes32, bytes32[] memory) {
        address;
        addresses[0] = user;
        addresses[1] = address(this);

        // 生成 Merkle 树的叶子节点
        bytes32;
        for (uint256 i = 0; i < addresses.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(addresses[i]));
        }
        bytes32 root = keccak256(abi.encodePacked(leaves[0], leaves[1]));

        // 为用户生成证明
        bytes32;
        _proof[0] = leaves[1]; // 为用户模拟的证明
        return (root, _proof);
    }

    function setUp() public {
        user = address(0xBEEF);

        // 部署 Mock 合约
        nft = new MockNFT();
        token = new MockToken();
        
        // 设置 Merkle 树和证明
        (merkleRoot, proof) = setUpMerkleTree();

        // 部署市场合约
        market = new AirdropMerkleNFTMarket(token, nft, merkleRoot);

        // 为市场合约铸造 NFT
        nft.mint(address(market), nftTokenId);

        // 为用户铸造并分配代币
        token.mint(user, 1 ether);

        // 用户批准市场合约花费代币
        vm.prank(user);
        token.approve(address(market), 1 ether);
    }

    // 测试用户是否在白名单中
    function testVerifyUserInWhitelist() public {
        // 使用 Merkle 证明验证用户是否在白名单中
        bool isWhitelisted = market.verifyUser(proof, user);
        assertTrue(isWhitelisted, "用户应该在白名单中");
    }

    // 测试 permit 授权和 NFT 领取
    function testPermitAndClaim() public {
        // 模拟用户签名 permit (使用 EIP-2612 的 permit)
        uint256 amount = discountPrice;
        uint256 deadline = block.timestamp + 1 days;
        uint8 v;
        bytes32 r;
        bytes32 s;

        // 用户签名 permit 消息
        (v, r, s) = vm.sign(1, keccak256(abi.encodePacked(amount, deadline)));

        // 用户调用 permit 和 claim，在一次交易中完成（multicall）
        vm.prank(user);
        market.permitAndClaim(
            address(market), // 允许市场合约花费代币
            amount,          // 授权金额
            deadline,        // 允许的截止日期
            v,               // 签名中的 v
            r,               // 签名中的 r
            s,               // 签名中的 s
            nftTokenId,      // 要领取的 NFT 代币 ID
            proof            // Merkle 证明
        );

        // 验证用户是否已经成功领取 NFT
        assertEq(nft.ownerOf(nftTokenId), user, "用户领取后应该持有该 NFT");

        // 验证用户是否支付了正确的折扣价格
        assertEq(token.balanceOf(user), 0.75 ether, "用户购买后应剩余 0.75 ether");
    }
}
