// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IToken.sol";

contract StakingPool {
    using SafeERC20 for IToken;

    IToken public kkToken;
    uint256 public constant REWARD_RATE = 10; // 每个区块产出 10 个 KK Token
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address tokenAddress) {
        kkToken = IToken(tokenAddress);
        lastUpdateTime = block.number;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.number - lastUpdateTime) * REWARD_RATE * 1e18) / _totalSupply);
    }

    function earned(address account) public view override returns (uint256) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.number;
        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function stake() external payable updateReward(msg.sender) {
        require(msg.value > 0, "Cannot stake 0");
        _totalSupply += msg.value;
        _balances[msg.sender] += msg.value;
    }

    function unstake(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0 && amount <= _balances[msg.sender], "Invalid unstake amount");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function claim() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            kkToken.mint(msg.sender, reward);
        }
    }
}