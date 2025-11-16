// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract ContractDevExchange {
    address public owner;
    address public tokenAddress;
    uint256 public exchangeRate; // ETH to Token rate (e.g., 1000 tokens per ETH)
    uint256 public totalVolume;
    uint256 public totalTrades;
    
    struct Trade {
        address trader;
        uint256 ethAmount;
        uint256 tokenAmount;
        bool isBuy; // true for buying tokens, false for selling tokens
        uint256 timestamp;
    }
    
    mapping(uint256 => Trade) public trades;
    uint256 public tradeCount;
    
    event TokenPurchase(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event TokenSale(address indexed seller, uint256 tokenAmount, uint256 ethAmount);
    event ExchangeRateUpdated(uint256 oldRate, uint256 newRate);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor(address _tokenAddress, uint256 _exchangeRate) {
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        exchangeRate = _exchangeRate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function buyTokens() public payable {
        require(msg.value > 0, "Must send ETH to buy tokens");
        require(tokenAddress != address(0), "Token address not set");
        
        uint256 tokenAmount = msg.value * exchangeRate;
        IERC20 token = IERC20(tokenAddress);
        
        require(token.balanceOf(address(this)) >= tokenAmount, "Insufficient token balance in exchange");
        
        // Transfer tokens to buyer
        require(token.transfer(msg.sender, tokenAmount), "Token transfer failed");
        
        totalVolume += msg.value;
        totalTrades++;
        
        trades[tradeCount] = Trade({
            trader: msg.sender,
            ethAmount: msg.value,
            tokenAmount: tokenAmount,
            isBuy: true,
            timestamp: block.timestamp
        });
        
        tradeCount++;
        
        emit TokenPurchase(msg.sender, msg.value, tokenAmount);
    }

    function sellTokens(uint256 _tokenAmount) public {
        require(_tokenAmount > 0, "Token amount must be greater than 0");
        require(tokenAddress != address(0), "Token address not set");
        
        uint256 ethAmount = _tokenAmount / exchangeRate;
        require(address(this).balance >= ethAmount, "Insufficient ETH balance in exchange");
        
        IERC20 token = IERC20(tokenAddress);
        
        // Transfer tokens from seller to exchange
        require(token.transferFrom(msg.sender, address(this), _tokenAmount), "Token transfer failed");
        
        // Transfer ETH to seller
        payable(msg.sender).transfer(ethAmount);
        
        totalVolume += ethAmount;
        totalTrades++;
        
        trades[tradeCount] = Trade({
            trader: msg.sender,
            ethAmount: ethAmount,
            tokenAmount: _tokenAmount,
            isBuy: false,
            timestamp: block.timestamp
        });
        
        tradeCount++;
        
        emit TokenSale(msg.sender, _tokenAmount, ethAmount);
    }

    function setExchangeRate(uint256 _newRate) public onlyOwner {
        require(_newRate > 0, "Exchange rate must be greater than 0");
        uint256 oldRate = exchangeRate;
        exchangeRate = _newRate;
        emit ExchangeRateUpdated(oldRate, _newRate);
    }

    function addLiquidity() public payable onlyOwner {
        require(msg.value > 0, "Must send ETH to add liquidity");
        // ETH is automatically added to the exchange balance
    }

    function withdrawETH(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(_amount);
    }

    function withdrawTokens(uint256 _amount) public onlyOwner {
        require(tokenAddress != address(0), "Token address not set");
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner, _amount), "Token transfer failed");
    }

    function getTrade(uint256 _tradeId) public view returns (
        address trader,
        uint256 ethAmount,
        uint256 tokenAmount,
        bool isBuy,
        uint256 timestamp
    ) {
        require(_tradeId < tradeCount, "Trade does not exist");
        
        Trade memory trade = trades[_tradeId];
        return (
            trade.trader,
            trade.ethAmount,
            trade.tokenAmount,
            trade.isBuy,
            trade.timestamp
        );
    }

    function getExchangeStats() public view returns (
        uint256 _exchangeRate,
        uint256 _totalVolume,
        uint256 _totalTrades,
        uint256 _ethBalance,
        uint256 _tokenBalance
    ) {
        uint256 tokenBalance = 0;
        if (tokenAddress != address(0)) {
            IERC20 token = IERC20(tokenAddress);
            tokenBalance = token.balanceOf(address(this));
        }
        
        return (
            exchangeRate,
            totalVolume,
            totalTrades,
            address(this).balance,
            tokenBalance
        );
    }

    function updateOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnerChanged(oldOwner, _newOwner);
    }

    // Fallback function to receive ETH
    receive() external payable {
        // ETH is automatically added to the exchange balance
    }
}
