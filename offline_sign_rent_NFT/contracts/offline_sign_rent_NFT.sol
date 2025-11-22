// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTRental {

    using ECDSA for bytes32;

    // 定义租赁订单的结构体
    struct RentoutOrder {
        address maker; // 出租方的地址
        address nft_ca; // NFT合约地址
        uint256 token_id; // NFT的tokenId
        uint256 daily_rent; // 每日租金
        uint256 max_rental_duration; // 最大租赁时间
        uint256 min_collateral; // 最低抵押金额
        uint256 list_endtime; // 挂单结束时间
    }

    // 定义EIP712域参数
    bytes32 public constant RENTOUT_ORDER_TYPEHASH = keccak256(
        "RentoutOrder(address maker,address nft_ca,uint256 token_id,uint256 daily_rent,uint256 max_rental_duration,uint256 min_collateral,uint256 list_endtime)"
    );

    bytes32 public DOMAIN_SEPARATOR;

    // 初始化EIP712域分隔符
    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("NFTRental")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    // 计算租赁订单的哈希值
    function hashRentoutOrder(RentoutOrder memory order) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                RENTOUT_ORDER_TYPEHASH,
                order.maker,
                order.nft_ca,
                order.token_id,
                order.daily_rent,
                order.max_rental_duration,
                order.min_collateral,
                order.list_endtime
            )
        );
    }

    // 获取离线签名的消息哈希值
    function getMessageHash(bytes32 rentoutOrderHash) public view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                rentoutOrderHash
            )
        );
    }

    // 验证签名是否有效
    function verifySignature(RentoutOrder memory order, bytes memory signature) public view returns (bool) {
        bytes32 orderHash = hashRentoutOrder(order);
        bytes32 messageHash = getMessageHash(orderHash);

        // 从签名中恢复签名者地址
        address signer = messageHash.recover(signature);
        return signer == order.maker;
    }

    // 执行租赁订单
    function rentNFT(
        RentoutOrder memory order, 
        bytes memory signature, 
        uint256 rentDuration
    ) public payable {
        // 验证租赁订单的有效性
        require(verifySignature(order, signature), "Invalid signature");
        require(block.timestamp < order.list_endtime, "Order expired");
        require(rentDuration <= order.max_rental_duration, "Rental duration exceeds maximum allowed");
        require(msg.value >= order.min_collateral, "Insufficient collateral");

        // 转移租金
        uint256 totalRent = rentDuration * order.daily_rent;
        require(msg.value >= totalRent, "Insufficient payment for rent");

        // 执行NFT转移
        IERC721 nftContract = IERC721(order.nft_ca);
        require(nftContract.ownerOf(order.token_id) == order.maker, "Maker is not the owner of the NFT");
        nftContract.safeTransferFrom(order.maker, msg.sender, order.token_id);

        // 这里可以增加转移支付给出租方或其他逻辑
    }
}
