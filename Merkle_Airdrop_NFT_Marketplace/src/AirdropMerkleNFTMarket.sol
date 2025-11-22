// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

contract AirdropMerkleNFTMarket is Multicall {
    using SafeERC20 for IERC20;

    IERC20 public token;  // ERC20 代币合约
    IERC721 public nft;   // ERC721 NFT 合约
    bytes32 public merkleRoot;  // Merkle 树根节点，用于验证白名单

    // 用于跟踪某地址是否已经领取过 NFT
    mapping(address => bool) public hasClaimed;

    // 声明 NFT 领取事件
    event NFTClaimed(address indexed user, uint256 tokenId);

    // 构造函数，初始化代币合约、NFT 合约以及 Merkle 树根
    constructor(IERC20 _token, IERC721 _nft, bytes32 _merkleRoot) {
        token = _token;
        nft = _nft;
        merkleRoot = _merkleRoot;
    }

    // 验证用户是否在 Merkle 树白名单中
    function verifyUser(bytes32[] calldata proof, address user) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));  // 生成用户的 Merkle 叶节点
        return MerkleProof.verify(proof, merkleRoot, leaf);  // 验证是否在 Merkle 树中
    }

    // 允许用户授权代币并进行预付款（Permit 模式）
    function permitPrePay(
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        token.permit(msg.sender, spender, amount, deadline, v, r, s);  // 使用 EIP-2612 的 permit 方法
    }

    // 用户领取 NFT 并享受 50% 折扣
    function claimNFT(uint256 tokenId, bytes32[] calldata proof) external {
        require(verifyUser(proof, msg.sender), "Not whitelisted");  // 确认用户在白名单中
        require(!hasClaimed[msg.sender], "NFT already claimed");  // 确保用户没有领取过

        uint256 originalPrice = 0.5 ether;  // NFT 原价
        uint256 discountPrice = originalPrice / 2;  // 50% 折扣后价格

        // 使用 permit 授权转账打折后的 token 价格
        token.safeTransferFrom(msg.sender, address(this), discountPrice);  // 转移代币支付

        nft.safeTransferFrom(address(this), msg.sender, tokenId);  // 转移 NFT 到用户
        hasClaimed[msg.sender] = true;  // 更新领取状态

        emit NFTClaimed(msg.sender, tokenId);  // 触发领取事件
    }

    // 允许用户在一次交易中同时进行预付款和领取 NFT（Multicall）
    function permitAndClaim(
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 tokenId,
        bytes32[] calldata proof
    ) external {
        permitPrePay(spender, amount, deadline, v, r, s);  // 执行授权并付款
        claimNFT(tokenId, proof);  // 执行领取 NFT
    }
}
