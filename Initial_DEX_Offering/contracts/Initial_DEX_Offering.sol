// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract IDO {
    IERC20 public token;             // 参与预售的ERC20代币
    address public owner;            // 合约所有者（项目方）
    uint256 public price;            // 每个Token的预售价格（ETH的wei值）
    uint256 public target;           // 募集ETH目标
    uint256 public cap;              // 超募上限
    uint256 public endTime;          // 预售结束时间
    bool public presaleActive;       // 预售状态
    uint256 public totalEthRaised;   // 已募集的ETH数量
    bool public presaleSuccess;      // 预售是否成功

    mapping(address => uint256) public ethContributions;  // 记录每个用户的ETH贡献
    mapping(address => uint256) public tokensToClaim;     // 记录每个用户应领取的Token数量

    constructor() {
        owner = msg.sender;
    }

    // 开启预售
    function startPresale(
        IERC20 _token,
        uint256 _price,
        uint256 _target,
        uint256 _cap,
        uint256 _duration
    ) external onlyOwner {
        require(!presaleActive, "Presale already active");
        token = _token;
        price = _price;
        target = _target;
        cap = _cap;
        endTime = block.timestamp + _duration;
        presaleActive = true;
        presaleSuccess = false;
    }

    // 参与预售，支付ETH以换取Token
    function participate() external payable {
        require(presaleActive, "Presale not active");
        require(block.timestamp <= endTime, "Presale has ended");
        require(totalEthRaised + msg.value <= cap, "Exceeds cap");

        uint256 tokenAmount = (msg.value * 1e18) / price; // 计算可领取的Token数量
        ethContributions[msg.sender] += msg.value;        // 记录用户贡献的ETH
        tokensToClaim[msg.sender] += tokenAmount;         // 记录用户应领取的Token
        totalEthRaised += msg.value;                      // 更新已募集的ETH数量
    }

    // 预售结束后，用户领取Token
    function claimTokens() external {
        require(!presaleActive, "Presale still active");
        require(presaleSuccess, "Presale did not succeed");
        uint256 amount = tokensToClaim[msg.sender];
        require(amount > 0, "No tokens to claim");
        
        tokensToClaim[msg.sender] = 0;
        token.transfer(msg.sender, amount); // 发送Token给用户
    }

    // 预售结束后，如果募集未成功，用户退款
    function refund() external {
        require(!presaleActive, "Presale still active");
        require(!presaleSuccess, "Presale succeeded, cannot refund");
        uint256 amount = ethContributions[msg.sender];
        require(amount > 0, "No ETH to refund");

        ethContributions[msg.sender] = 0;
        payable(msg.sender).transfer(amount); // 退还ETH
    }

    // 预售结束，判断成功与否，项目方提现募集的ETH
    function finalizePresale() external onlyOwner {
        require(presaleActive, "Presale not active");
        require(block.timestamp > endTime, "Presale not ended");

        presaleActive = false;
        if (totalEthRaised >= target) {
            presaleSuccess = true;
            payable(owner).transfer(address(this).balance); // 提现募集的ETH
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}
