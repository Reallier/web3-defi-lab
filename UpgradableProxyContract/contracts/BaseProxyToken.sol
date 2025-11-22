// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入OpenZeppelin合约库中的ERC20标准实现
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 继承自ERC20的合约 `InscriptionToken`
contract InscriptionToken is ERC20 {
    // 构造函数，初始化ERC20合约的名称和符号
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    
    // 公开的铸币函数，允许任何人给指定地址铸造代币
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

// 工厂合约，用于创建和管理 `InscriptionToken` 实例
contract Factory {
    // 定义一个事件，当新代币被创建时触发
    event TokenCreated(address token, string symbol, uint totalSupply, uint perMint);

    // 部署新的 `InscriptionToken` 实例，并为部署者铸造一定数量的代币
    function deployInscription(string memory symbol, uint totalSupply, uint perMint) public {
        // 创建一个新的 `InscriptionToken` 实例
        InscriptionToken token = new InscriptionToken("Inscription Token", symbol);
        // 为消息发送者铸造 `totalSupply` 数量的代币
        token.mint(msg.sender, totalSupply);
        // 触发事件通知外部系统
        emit TokenCreated(address(token), symbol, totalSupply, perMint);
    }

    // 为已存在的 `InscriptionToken` 实例铸造代币
    function mintInscription(address tokenAddr) public {
        // 将传入的地址转换为 `InscriptionToken` 类型
        InscriptionToken token = InscriptionToken(tokenAddr);
        token.mint(msg.sender, 1); // 为消息发送者铸造一枚代币
    }
}