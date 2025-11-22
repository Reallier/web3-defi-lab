// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

// ERC20 合约，和之前一致
contract InscriptionToken is ERC20 {
    address public factory;
    uint public perMint;
    uint public price;

    constructor(address _factory, string memory name, string memory symbol, uint _perMint, uint _price) ERC20(name, symbol) {
        factory = _factory;
        perMint = _perMint;
        price = _price;
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == factory, "Only factory can mint");
        _mint(to, amount);
    }
}

// 工厂合约 V2，使用 Clone 创建合约实例
contract FactoryV2 {
    address public implementation;

    event TokenCreated(address token, string symbol, uint totalSupply, uint perMint, uint price);

    constructor() {
        implementation = address(new InscriptionToken(address(this), "", "", 0, 0)); // 初始化实现合约
    }

    // 使用最小代理方式部署新的 ERC20 实例
    function deployInscription(string memory symbol, uint totalSupply, uint perMint, uint price) public {
        address clone = Clones.clone(implementation);
        InscriptionToken(clone).initialize(address(this), "Inscription Token", symbol, perMint, price); // 初始化新的代币
        InscriptionToken(clone).mint(msg.sender, totalSupply);
        emit TokenCreated(clone, symbol, totalSupply, perMint, price);
    }

    // Mint 代币，每次铸造 `perMint` 指定的数量，并收取 `price`
    function mintInscription(address tokenAddr) public payable {
        InscriptionToken token = InscriptionToken(tokenAddr);
        require(msg.value >= token.price(), "Not enough ether sent");
        token.mint(msg.sender, token.perMint());
    }
}
