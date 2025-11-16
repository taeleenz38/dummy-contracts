// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract ContractDevVault {
    address public owner;
    uint256 public totalDeposits;
    uint256 public totalWithdrawals;
    uint256 public totalAssets;
    uint256 public vaultBalance;
    
    struct Asset {
        address tokenAddress;
        string symbol;
        uint256 balance;
        uint256 price;
        bool isActive;
    }
    
    struct Deposit {
        uint256 id;
        address user;
        address tokenAddress;
        uint256 amount;
        uint256 timestamp;
        string status;
    }
    
    struct Withdrawal {
        uint256 id;
        address user;
        address tokenAddress;
        uint256 amount;
        uint256 timestamp;
        string status;
    }
    
    mapping(uint256 => Asset) public assets;
    mapping(uint256 => Deposit) public deposits;
    mapping(uint256 => Withdrawal) public withdrawals;
    mapping(address => uint256) public userBalances;
    mapping(address => bool) public supportedTokens;
    
    uint256 public assetCount;
    uint256 public depositCount;
    uint256 public withdrawalCount;
    
    event AssetAdded(uint256 indexed assetId, address tokenAddress, string symbol, uint256 price);
    event AssetUpdated(uint256 indexed assetId, uint256 newPrice);
    event DepositMade(uint256 indexed depositId, address indexed user, address tokenAddress, uint256 amount);
    event WithdrawalMade(uint256 indexed withdrawalId, address indexed user, address tokenAddress, uint256 amount);
    event VaultBalanceUpdated(uint256 newBalance);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function addAsset(
        address _tokenAddress,
        string memory _symbol,
        uint256 _price
    ) public onlyOwner returns (uint256) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_price > 0, "Price must be greater than 0");
        
        uint256 assetId = assetCount;
        assets[assetId] = Asset({
            tokenAddress: _tokenAddress,
            symbol: _symbol,
            balance: 0,
            price: _price,
            isActive: true
        });
        
        supportedTokens[_tokenAddress] = true;
        assetCount++;
        totalAssets++;
        
        emit AssetAdded(assetId, _tokenAddress, _symbol, _price);
        return assetId;
    }

    function updateAssetPrice(uint256 _assetId, uint256 _newPrice) public onlyOwner {
        require(_assetId < assetCount, "Asset does not exist");
        require(_newPrice > 0, "Price must be greater than 0");
        
        assets[_assetId].price = _newPrice;
        
        emit AssetUpdated(_assetId, _newPrice);
    }

    function depositAsset(
        address _tokenAddress,
        uint256 _amount
    ) public returns (uint256) {
        require(supportedTokens[_tokenAddress], "Token not supported");
        require(_amount > 0, "Amount must be greater than 0");
        
        // Find the asset
        uint256 assetId = _findAssetByToken(_tokenAddress);
        require(assetId < assetCount, "Asset not found");
        
        // Update balances
        assets[assetId].balance += _amount;
        userBalances[msg.sender] += _amount;
        vaultBalance += _amount;
        totalDeposits += _amount;
        
        // Create deposit record
        uint256 depositId = depositCount;
        deposits[depositId] = Deposit({
            id: depositId,
            user: msg.sender,
            tokenAddress: _tokenAddress,
            amount: _amount,
            timestamp: block.timestamp,
            status: "Completed"
        });
        
        depositCount++;
        
        emit DepositMade(depositId, msg.sender, _tokenAddress, _amount);
        emit VaultBalanceUpdated(vaultBalance);
        
        return depositId;
    }

    function withdrawAsset(
        address _tokenAddress,
        uint256 _amount
    ) public returns (uint256) {
        require(supportedTokens[_tokenAddress], "Token not supported");
        require(_amount > 0, "Amount must be greater than 0");
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        
        // Find the asset
        uint256 assetId = _findAssetByToken(_tokenAddress);
        require(assetId < assetCount, "Asset not found");
        require(assets[assetId].balance >= _amount, "Insufficient vault balance");
        
        // Update balances
        assets[assetId].balance -= _amount;
        userBalances[msg.sender] -= _amount;
        vaultBalance -= _amount;
        totalWithdrawals += _amount;
        
        // Create withdrawal record
        uint256 withdrawalId = withdrawalCount;
        withdrawals[withdrawalId] = Withdrawal({
            id: withdrawalId,
            user: msg.sender,
            tokenAddress: _tokenAddress,
            amount: _amount,
            timestamp: block.timestamp,
            status: "Completed"
        });
        
        withdrawalCount++;
        
        emit WithdrawalMade(withdrawalId, msg.sender, _tokenAddress, _amount);
        emit VaultBalanceUpdated(vaultBalance);
        
        return withdrawalId;
    }

    function _findAssetByToken(address _tokenAddress) internal view returns (uint256) {
        for (uint256 i = 0; i < assetCount; i++) {
            if (assets[i].tokenAddress == _tokenAddress && assets[i].isActive) {
                return i;
            }
        }
        return assetCount; // Return invalid ID if not found
    }

    function getAsset(uint256 _assetId) public view returns (
        address tokenAddress,
        string memory symbol,
        uint256 balance,
        uint256 price,
        bool isActive
    ) {
        require(_assetId < assetCount, "Asset does not exist");
        
        Asset memory asset = assets[_assetId];
        return (
            asset.tokenAddress,
            asset.symbol,
            asset.balance,
            asset.price,
            asset.isActive
        );
    }

    function getDeposit(uint256 _depositId) public view returns (
        uint256 id,
        address user,
        address tokenAddress,
        uint256 amount,
        uint256 timestamp,
        string memory status
    ) {
        require(_depositId < depositCount, "Deposit does not exist");
        
        Deposit memory deposit = deposits[_depositId];
        return (
            deposit.id,
            deposit.user,
            deposit.tokenAddress,
            deposit.amount,
            deposit.timestamp,
            deposit.status
        );
    }

    function getWithdrawal(uint256 _withdrawalId) public view returns (
        uint256 id,
        address user,
        address tokenAddress,
        uint256 amount,
        uint256 timestamp,
        string memory status
    ) {
        require(_withdrawalId < withdrawalCount, "Withdrawal does not exist");
        
        Withdrawal memory withdrawal = withdrawals[_withdrawalId];
        return (
            withdrawal.id,
            withdrawal.user,
            withdrawal.tokenAddress,
            withdrawal.amount,
            withdrawal.timestamp,
            withdrawal.status
        );
    }

    function getVaultStats() public view returns (
        uint256 _totalDeposits,
        uint256 _totalWithdrawals,
        uint256 _totalAssets,
        uint256 _vaultBalance,
        uint256 _assetCount
    ) {
        return (totalDeposits, totalWithdrawals, totalAssets, vaultBalance, assetCount);
    }

    function getUserBalance(address _user) public view returns (uint256) {
        return userBalances[_user];
    }

    function updateOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnerChanged(oldOwner, _newOwner);
    }
}
