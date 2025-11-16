// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract ContractDevTreasury {
    address public owner;
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    uint256 public balance;
    
    struct Transaction {
        address user;
        uint256 amount;
        bool isDeposit;
        uint256 timestamp;
        string description;
    }
    
    mapping(uint256 => Transaction) public transactions;
    uint256 public transactionCount;
    
    event Deposit(address indexed user, uint256 amount, string description);
    event Withdrawal(address indexed user, uint256 amount, string description);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function deposit(string memory _description) public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        balance += msg.value;
        totalDeposits += msg.value;
        
        transactions[transactionCount] = Transaction({
            user: msg.sender,
            amount: msg.value,
            isDeposit: true,
            timestamp: block.timestamp,
            description: _description
        });
        
        transactionCount++;
        
        emit Deposit(msg.sender, msg.value, _description);
    }

    function withdraw(uint256 _amount, string memory _description) public onlyOwner {
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        require(balance >= _amount, "Insufficient treasury balance");
        
        balance -= _amount;
        totalWithdrawals += _amount;
        
        transactions[transactionCount] = Transaction({
            user: msg.sender,
            amount: _amount,
            isDeposit: false,
            timestamp: block.timestamp,
            description: _description
        });
        
        transactionCount++;
        
        payable(owner).transfer(_amount);
        
        emit Withdrawal(msg.sender, _amount, _description);
    }

    function getTransaction(uint256 _transactionId) public view returns (
        address user,
        uint256 amount,
        bool isDeposit,
        uint256 timestamp,
        string memory description
    ) {
        require(_transactionId < transactionCount, "Transaction does not exist");
        
        Transaction memory transaction = transactions[_transactionId];
        return (
            transaction.user,
            transaction.amount,
            transaction.isDeposit,
            transaction.timestamp,
            transaction.description
        );
    }

    function getTreasuryStats() public view returns (
        uint256 _balance,
        uint256 _totalDeposits,
        uint256 _totalWithdrawals,
        uint256 _transactionCount
    ) {
        return (balance, totalDeposits, totalWithdrawals, transactionCount);
    }

    function updateOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnerChanged(oldOwner, _newOwner);
    }

    // Fallback function to receive ETH
    receive() external payable {
        deposit("Fallback deposit");
    }
}
