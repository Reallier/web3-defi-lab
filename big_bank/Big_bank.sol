pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Bank.sol";

contract BigBank is Bank, Ownable {
    struct TopUser {
        address user;
        uint256 amount;
    }

    TopUser[3] public topUsers;

    modifier minDeposit() {
        require(msg.value >= 0.001 ether, "Deposit must be at least 0.001 ether");
        _;
    }

    function deposit() public payable override minDeposit {
        super.deposit();
        updateTopUsers(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public override onlyOwner {
        super.withdraw(amount);
    }

    function updateTopUsers(address user, uint256 amount) private {
        for (uint i = 0; i < 3; i++) {
            if (amount > topUsers[i].amount) {
                for (uint j = 2; j > i; j--) {
                    topUsers[j] = topUsers[j - 1];
                }
                topUsers[i] = TopUser(user, amount);
                break;
            }
        }
    }

    // Function to transfer ownership of BigBank to Ownable contract
    function transferOwnershipToOwnable(address ownableAddress) external onlyOwner {
        Ownable ownable = Ownable(ownableAddress);
        ownable.transferOwnership(msg.sender);
        transferOwnership(ownableAddress);
    }
}