// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // ERC20代币接口
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol"; // 防重入攻击保护
import "@openzeppelin/contracts/access/Ownable.sol"; // 合约所有权管理

interface IERC20MintableBurnable is IERC20 {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// 继承自ReentrancyGuard和Ownable
contract StakingRewards is ReentrancyGuard, Ownable {
    IERC20 public rntToken; // RNT代币接口
    IERC20MintableBurnable public esRntToken;  // 可销毁、可铸造的esRNT代币接口

    uint256 public constant DAILY_REWARD = 1 ether; // 每天1个esRNT
    uint256 public constant LOCK_PERIOD = 30 days; // 锁定期为30天

    // 用户的质押信息
    struct Stake {
        uint256 amount; // 质押数量
        uint256 startTime; // 质押开始时间
    }

    // 用户地址到质押信息的映射
    mapping(address => Stake) private stakes;
    // 奖励累计
    mapping(address => uint256) private rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;

    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    uint256 private _totalSupply;

    event Staked(address indexed user, uint256 amount); // 质押事件
    event Unstaked(address indexed user, uint256 amount); // 取消质押事件
    event RewardClaimed(address indexed user, uint256 amount); // 领取奖励事件

    // 构造函数，初始化RNT代币和esRNT代币
    constructor(address _rntToken, address _esRntToken) Ownable(msg.sender) {
        rntToken = IERC20(_rntToken);
        esRntToken = IERC20MintableBurnable(_esRntToken);
        lastUpdateTime = block.timestamp;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return stakes[account].amount;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        uint256 timePassed = block.timestamp - lastUpdateTime;
        return rewardPerTokenStored + ((timePassed * DAILY_REWARD * 1e18) / _totalSupply);
    }

    function earned(address account) public view returns (uint256) {
        return (stakes[account].amount * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    // 质押函数，用户质押RNT代币
    function stake(uint256 _amount) external nonReentrant updateReward(msg.sender) {
        // 确保质押数量大于0
        require(_amount > 0, "Stake amount must be greater than zero");
        // 确保用户有足够的RNT代币
        require(rntToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // 更新质押信息
        _totalSupply += _amount;
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].startTime = block.timestamp;

        // 触发质押事件
        emit Staked(msg.sender, _amount);
    }

    // 取消质押函数，用户取消质押并领取奖励
    function unstake() external nonReentrant updateReward(msg.sender) {
        // 确保用户有质押记录
        require(stakes[msg.sender].amount > 0, "No staked tokens to withdraw");

        claimReward(); // 领取所有未领取的奖励
        
        // 提取质押金额, 重置质押信息
        uint256 amountToWithdraw = stakes[msg.sender].amount;
        stakes[msg.sender].amount = 0;
        _totalSupply -= amountToWithdraw;

        // 确保将RNT代币转移回用户账户成功
        require(rntToken.transfer(msg.sender, amountToWithdraw), "Transfer failed");

        // 触发取消质押事件
        emit Unstaked(msg.sender, amountToWithdraw);
    }

    // 领取奖励函数，用户领取奖励
    function claimReward() public nonReentrant updateReward(msg.sender) {
        // 确保用户有质押记录
        require(stakes[msg.sender].amount > 0, "No staked tokens");

        uint256 rewardAmount = rewards[msg.sender];
        if (rewardAmount > 0) { // 如果有奖励可领取
            rewards[msg.sender] = 0;
            esRntToken.mint(msg.sender, rewardAmount); // 发行esRNT奖励给用户

            stakes[msg.sender].startTime = block.timestamp; // 更新质押时间
            emit RewardClaimed(msg.sender, rewardAmount); // 触发领取奖励事件
        }
    }

    // 将esRNT转换成RNT的功能
    function convertEsRntToRnt(uint256 _amount) external nonReentrant {
        // 确保用户有足够的esRNT余额
        require(esRntToken.balanceOf(msg.sender) >= _amount, "Insufficient esRNT balance");
        require(stakes[msg.sender].startTime > 0, "No staking record");
        
        // 计算质押时间
        uint256 stakedTime = block.timestamp - stakes[msg.sender].startTime;
        // 计算解锁的数量
        uint256 unlockedAmount = (_amount * stakedTime) / LOCK_PERIOD;

        // 确保不是全部还在锁定期
        require(unlockedAmount > 0, "All tokens are still locked");

        // 如果解锁的数量小于请求的数量，则燃烧锁定部分
        if (unlockedAmount < _amount) {
            uint256 lockedPortion = _amount - unlockedAmount;
            esRntToken.burnFrom(msg.sender, lockedPortion); // 燃烧锁定部分
            _amount = unlockedAmount;
        }

        // 燃烧esRNT，并将相应数量的RNT转移给用户
        esRntToken.burnFrom(msg.sender, _amount);
        rntToken.transfer(msg.sender, _amount);
    }
}
