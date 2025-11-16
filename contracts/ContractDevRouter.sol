// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract ContractDevRouter {
    address public owner;
    uint256 public totalRoutes;
    uint256 public totalTransactions;
    uint256 public totalVolume;
    
    struct Route {
        uint256 id;
        address fromToken;
        address toToken;
        uint256 exchangeRate;
        bool isActive;
        uint256 createdAt;
    }
    
    struct Transaction {
        uint256 id;
        address user;
        address fromToken;
        address toToken;
        uint256 inputAmount;
        uint256 outputAmount;
        uint256 timestamp;
        string status;
    }
    
    mapping(uint256 => Route) public routes;
    mapping(uint256 => Transaction) public transactions;
    mapping(address => bool) public supportedTokens;
    mapping(address => uint256) public tokenBalances;
    
    event RouteCreated(uint256 indexed routeId, address fromToken, address toToken, uint256 exchangeRate);
    event RouteUpdated(uint256 indexed routeId, uint256 newExchangeRate);
    event RouteDeactivated(uint256 indexed routeId);
    event TransactionExecuted(uint256 indexed transactionId, address indexed user, uint256 inputAmount, uint256 outputAmount);
    event TokenSupported(address indexed token, bool supported);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function createRoute(
        address _fromToken,
        address _toToken,
        uint256 _exchangeRate
    ) public onlyOwner returns (uint256) {
        require(_fromToken != address(0) && _toToken != address(0), "Invalid token addresses");
        require(_exchangeRate > 0, "Exchange rate must be greater than 0");
        
        uint256 routeId = totalRoutes;
        routes[routeId] = Route({
            id: routeId,
            fromToken: _fromToken,
            toToken: _toToken,
            exchangeRate: _exchangeRate,
            isActive: true,
            createdAt: block.timestamp
        });
        
        totalRoutes++;
        
        emit RouteCreated(routeId, _fromToken, _toToken, _exchangeRate);
        return routeId;
    }

    function updateRoute(uint256 _routeId, uint256 _newExchangeRate) public onlyOwner {
        require(_routeId < totalRoutes, "Route does not exist");
        require(_newExchangeRate > 0, "Exchange rate must be greater than 0");
        
        routes[_routeId].exchangeRate = _newExchangeRate;
        
        emit RouteUpdated(_routeId, _newExchangeRate);
    }

    function deactivateRoute(uint256 _routeId) public onlyOwner {
        require(_routeId < totalRoutes, "Route does not exist");
        
        routes[_routeId].isActive = false;
        
        emit RouteDeactivated(_routeId);
    }

    function executeSwap(
        uint256 _routeId,
        uint256 _inputAmount
    ) public returns (uint256) {
        require(_routeId < totalRoutes, "Route does not exist");
        require(routes[_routeId].isActive, "Route is not active");
        require(_inputAmount > 0, "Input amount must be greater than 0");
        
        Route memory route = routes[_routeId];
        uint256 outputAmount = _inputAmount * route.exchangeRate / 1000; // Assuming 1000 as base rate
        
        // Create transaction record
        uint256 transactionId = totalTransactions;
        transactions[transactionId] = Transaction({
            id: transactionId,
            user: msg.sender,
            fromToken: route.fromToken,
            toToken: route.toToken,
            inputAmount: _inputAmount,
            outputAmount: outputAmount,
            timestamp: block.timestamp,
            status: "Completed"
        });
        
        totalTransactions++;
        totalVolume += _inputAmount;
        
        emit TransactionExecuted(transactionId, msg.sender, _inputAmount, outputAmount);
        
        return outputAmount;
    }

    function addSupportedToken(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token address");
        
        supportedTokens[_token] = true;
        
        emit TokenSupported(_token, true);
    }

    function removeSupportedToken(address _token) public onlyOwner {
        require(_token != address(0), "Invalid token address");
        
        supportedTokens[_token] = false;
        
        emit TokenSupported(_token, false);
    }

    function getRoute(uint256 _routeId) public view returns (
        uint256 id,
        address fromToken,
        address toToken,
        uint256 exchangeRate,
        bool isActive,
        uint256 createdAt
    ) {
        require(_routeId < totalRoutes, "Route does not exist");
        
        Route memory route = routes[_routeId];
        return (
            route.id,
            route.fromToken,
            route.toToken,
            route.exchangeRate,
            route.isActive,
            route.createdAt
        );
    }

    function getTransaction(uint256 _transactionId) public view returns (
        uint256 id,
        address user,
        address fromToken,
        address toToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 timestamp,
        string memory status
    ) {
        require(_transactionId < totalTransactions, "Transaction does not exist");
        
        Transaction memory transaction = transactions[_transactionId];
        return (
            transaction.id,
            transaction.user,
            transaction.fromToken,
            transaction.toToken,
            transaction.inputAmount,
            transaction.outputAmount,
            transaction.timestamp,
            transaction.status
        );
    }

    function getRouterStats() public view returns (
        uint256 _totalRoutes,
        uint256 _totalTransactions,
        uint256 _totalVolume
    ) {
        return (totalRoutes, totalTransactions, totalVolume);
    }

    function calculateOutputAmount(uint256 _routeId, uint256 _inputAmount) public view returns (uint256) {
        require(_routeId < totalRoutes, "Route does not exist");
        require(routes[_routeId].isActive, "Route is not active");
        
        return _inputAmount * routes[_routeId].exchangeRate / 1000;
    }

    function updateOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnerChanged(oldOwner, _newOwner);
    }
}
