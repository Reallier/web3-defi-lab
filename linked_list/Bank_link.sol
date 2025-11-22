// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Bank {
    // 存储每个地址的余额
    mapping(address => uint256) public balances;
    
    // 存款排行榜的结构体
    struct DepositRecord {
        address depositor; // 存款人的地址
        uint256 amount;    // 存款金额
    }
    
    // 排行榜数组，只存储前10名
    DepositRecord[10] public topDepositors;
    
    // 事件，用于通知前端应用
    event Deposit(address indexed from, uint256 amount);
    
    // 存款函数
    function deposit() public payable {
        require(msg.value > 0, "Deposit value must be greater than 0");
        
        // 更新用户的余额
        balances[msg.sender] += msg.value;
        
        // 更新排行榜
        updateTopDepositors(msg.sender, msg.value);
        
        // 发出存款事件
        emit Deposit(msg.sender, msg.value);
    }
    
    // 更新排行榜的内部函数
    function updateTopDepositors(address depositor, uint256 amount) internal {
        // 如果排行榜未满，直接添加
        for (uint i = 0; i < 10; i++) {
            if (topDepositors[i].depositor == address(0)) {
                topDepositors[i] = DepositRecord(depositor, balances[depositor]);
                return;
            }
        }
        
        // 如果排行榜已满，找到最低排名的用户
        uint256 lowestIndex = 0;
        for (uint i = 1; i < 10; i++) {
            if (topDepositors[i].amount < topDepositors[lowestIndex].amount) {
                lowestIndex = i;
            }
        }
        
        // 如果新用户的存款大于排行榜上最小的存款，则替换
        if (balances[depositor] > topDepositors[lowestIndex].amount) {
            topDepositors[lowestIndex] = DepositRecord(depositor, balances[depositor]);
        }
    }
    
    // 获取当前地址的余额
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}