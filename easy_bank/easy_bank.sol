// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // 管理员地址
    address public admin;
    
    // 存款记录
    mapping(address => uint256) public balances;
    
    // 存款金额前 3 名用户
    struct TopUser {
        address user;
        uint256 amount;
    }
    
    TopUser[3] public topUsers;
    
    // 事件
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed admin, uint256 amount);
    
    // 构造函数，初始化管理员地址
    constructor() {
        admin = msg.sender;
    }
    
    // 接收 Ether 的 fallback 函数
    receive() external payable {
        deposit();
    }
    
    // 存款函数
    function deposit() public payable {
        require(msg.value > 0, "Deposit value must be greater than 0");
        
        // 更新余额
        balances[msg.sender] += msg.value;
        
        // 更新前 3 名用户
        updateTopUsers(msg.sender, msg.value);
        
        emit Deposit(msg.sender, msg.value);
    }
    
    // 更新前 3 名用户的函数
    function updateTopUsers(address user, uint256 amount) internal {
        for (uint i = 0; i < 3; i++) {
            if (amount > topUsers[i].amount) {
                // 插入新用户
                for (uint j = 2; j > i; j--) {
                    topUsers[j] = topUsers[j - 1];
                }
                topUsers[i] = TopUser(user, balances[user]);
                break;
            }
        }
    }
    
    // 提取资金的函数，仅管理员可调用
    function withdraw(uint256 amount) public {
        require(msg.sender == admin, "Only admin can withdraw funds");
        require(amount <= address(this).balance, "Insufficient balance");
        
        payable(admin).transfer(amount);
        
        emit Withdrawal(admin, amount);
    }
    
    // 获取合约余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}