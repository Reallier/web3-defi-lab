// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入SafeMath库，用于安全的数学运算
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BaseERC20 {

    string public name = "BaseERC20";
    string public symbol = "BERC20";
    uint8 public decimals = 18; // 代币的小数位数

    // 初始化总供应量
    uint256 public totalSupply = 100000000 * 10 ** uint256(decimals);

    // 使用 bytes32 定义角色
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER");

    // 映射表用于存储账户余额
    mapping (address => uint256) private _balances;
    // 映射表用于存储账户之间的允许转账额度
    mapping (address => mapping (address => uint256)) private _allowances;
    // 映射表用于标记账户是否被冻结
    mapping (address => bool) private _frozenAccounts;

    // 存储地址对应角色的映射
    mapping(address => mapping(bytes32 => bool)) private _roles;

    event Transfer(address indexed from, address indexed to, uint256 value); // 转账事件
    event Approval(address indexed owner, address indexed spender, uint256 value); // 批准事件
    event FrozenFunds(address indexed target, bool frozen); // 冻结资金事件
    event Burn(address indexed burner, uint256 value); // 烧毁事件
    event Mint(address indexed to, uint256 amount); // 铸造事件
    event SetRole(address indexed user, bytes32 role, bool active); // 设置角色事件

    constructor() {
        _balances[msg.sender] = totalSupply; // 将总供应量分配给合约部署者的账户
        _roles[msg.sender][OWNER_ROLE] = true; // 合约部署者为所有者
        emit Transfer(address(0), msg.sender, totalSupply); // 触发Transfer事件，记录初始代币分配
    }

    // 只有合约所有者可以执行的方法修饰符
    modifier onlyOwner() {
        require(_roles[msg.sender][OWNER_ROLE], "Caller is not the owner"); // 检查调用者是否是合约所有者
        _; // 继续执行被修饰的方法
    }

    // 限制基于角色的访问
    modifier onlyAuthorized(bytes32 role) {
        require(_roles[msg.sender][role], "Caller does not have the required role");
        _;
    }

    // 设置用户角色的方法
    function setRole(address user, bytes32 role, bool active) public onlyOwner {
        _roles[user][role] = active; // 更新用户的角色状态
        emit SetRole(user, role, active); // 触发SetRole事件
    }

    // 添加所有者的方法
    function addOwner(address owner) public onlyOwner {
        setRole(owner, OWNER_ROLE, true); // 设置用户为所有者角色
    }

    // 查询用户是否是所有者的方法
    function isOwner(address owner) public view returns (bool) {
        return _roles[owner][OWNER_ROLE]; // 返回用户是否是所有者
    }

    // 移除所有者的方法
    function removeOwner(address owner) public onlyOwner {
        setRole(owner, OWNER_ROLE, false); // 移除用户的所有者角色
    }

    // 查询账户余额的方法
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account]; // 返回账户的余额
    }

    // 转账方法
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(!_frozenAccounts[msg.sender], "ERC20: transfer from a frozen account"); // 检查发送者账户是否被冻结
        _transfer(msg.sender, recipient, amount);  // 执行转账操作
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        // 检查发送者地址是否为零地址
        require(sender != address(0), "ERC20: transfer from the zero address");
        // 检查接收者地址是否为零地址
        require(recipient != address(0), "ERC20: transfer to the zero address");
        // 检查发送者的余额是否足够
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        // 检查发送者账户是否被冻结
        require(!_frozenAccounts[sender], "ERC20: transfer from a frozen account");
        // 检查接收者账户是否被冻结
        require(!_frozenAccounts[recipient], "ERC20: transfer to a frozen account");

        _balances[sender] -= amount; // 直接使用减法运算符
        _balances[recipient] += amount; // 直接使用加法运算符
        emit Transfer(sender, recipient, amount); // 触发Transfer事件
    }


    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        // 检查发送者账户是否被冻结
        require(!_frozenAccounts[sender], "ERC20: transfer from a frozen account");

        // 执行转账操作
        _transfer(sender, recipient, amount);

        // 更新批准额度，使用内置减法运算符
        _allowances[sender][msg.sender] -= amount;
        require(_allowances[sender][msg.sender] >= 0, "ERC20: transfer amount exceeds allowance");

        return true;
    }


    // 批准某个账户可以花费指定数量的代币
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount); // 设置批准额度
        return true;
    }

    // 内部批准方法
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address"); // 检查所有者地址是否为零地址
        require(spender != address(0), "ERC20: approve to the zero address"); // 检查接收者地址是否为零地址

        _allowances[owner][spender] = amount; // 更新批准额度
        emit Approval(owner, spender, amount);
    }

    // 查询批准额度的方法
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender]; // 返回spender被owner批准的额度
    }

    // 冻结或解冻账户的方法
    function freezeAccount(address target, bool freeze) public onlyOwner {
        _frozenAccounts[target] = freeze; // 更新目标账户的冻结状态
        emit FrozenFunds(target, freeze);
    }

    // 烧毁代币的方法
    function burn(uint256 amount) public {
        // 检查烧毁的数量是否超过余额
        require(_balances[msg.sender] >= amount, "ERC20: burn amount exceeds balance");

        // 减少发送者的余额
        _balances[msg.sender] -= amount;

        // 减少总供应量
        totalSupply -= amount;

        // 触发Burn事件
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount); // 触发Transfer事件，表示代币被烧毁
    }

    // 铸造新代币的方法
    function mint(address to, uint256 amount) public onlyOwner {
        totalSupply += amount; // 增加总供应量
        _balances[to] += amount; // 增加接收者的余额
        emit Mint(to, amount); // 触发Mint事件
        emit Transfer(address(0), to, amount); // 触发Transfer事件，表示新代币被铸造
    }
}