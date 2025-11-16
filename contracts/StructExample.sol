// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract StructExample {
    // User profile struct
    struct User {
        uint256 id;
        string name;
        string email;
        uint256 registrationDate;
        bool isActive;
        address wallet;
    }

    // Product struct
    struct Product {
        uint256 id;
        string name;
        string description;
        uint256 price; // in wei
        uint256 stock;
        bool isAvailable;
        address owner;
    }

    // Order struct
    struct Order {
        uint256 id;
        uint256 userId;
        uint256 productId;
        uint256 quantity;
        uint256 totalPrice;
        OrderStatus status;
        uint256 orderDate;
        uint256 deliveryDate;
    }

    // Order status enum
    enum OrderStatus {
        Pending,
        Confirmed,
        Shipped,
        Delivered,
        Cancelled
    }

    // Address struct for shipping
    struct Address {
        string street;
        string city;
        string state;
        string zipCode;
        string country;
    }

    // Complex struct with nested structs
    struct UserProfile {
        User user;
        Address shippingAddress;
        uint256 totalOrders;
        uint256 loyaltyPoints;
    }

    // Main data struct with 4 members (including owner)
    struct StoredStorage {
        uint256 amount;
        address account;
        string note;
        address owner;
    }

    // Single state variable containing all data
    StoredStorage public stored;
    
    // Separate mappings (not in struct so they don't show in DApp interface)
    mapping(uint256 => User) public users;
    mapping(uint256 => Product) public products;
    mapping(uint256 => Order) public orders;
    
    // Counters
    uint256 public userCount;
    uint256 public productCount;
    uint256 public orderCount;

    // Constructor to set the owner
    constructor() {
        stored.owner = msg.sender;
    }

    // Events
    event UserCreated(uint256 indexed userId, string name, address wallet);
    event ProductAdded(uint256 indexed productId, string name, uint256 price);
    event OrderPlaced(uint256 indexed orderId, uint256 userId, uint256 productId);
    event OrderStatusUpdated(uint256 indexed orderId, OrderStatus newStatus);

    // User management functions
    function createUser(
        string memory _name,
        string memory _email,
        address _wallet
    ) public returns (uint256) {
        userCount++;
        users[userCount] = User({
            id: userCount,
            name: _name,
            email: _email,
            registrationDate: block.timestamp,
            isActive: true,
            wallet: _wallet
        });

        emit UserCreated(userCount, _name, _wallet);
        return userCount;
    }

    function createUserProfile(
        uint256 _userId,
        string memory /* _street */,
        string memory /* _city */,
        string memory /* _state */,
        string memory /* _zipCode */,
        string memory /* _country */
    ) public view {
        require(users[_userId].id != 0, "User does not exist");
        
        // Note: userProfiles mapping was removed from struct, so this function is simplified
        // You may want to add userProfiles back as a separate mapping if needed
    }

    // Product management functions
    function addProduct(
        string memory _name,
        string memory _description,
        uint256 _price,
        uint256 _stock,
        address _owner
    ) public returns (uint256) {
        productCount++;
        products[productCount] = Product({
            id: productCount,
            name: _name,
            description: _description,
            price: _price,
            stock: _stock,
            isAvailable: _stock > 0,
            owner: _owner
        });

        emit ProductAdded(productCount, _name, _price);
        return productCount;
    }

    function updateProductStock(uint256 _productId, uint256 _newStock) public {
        require(products[_productId].id != 0, "Product does not exist");
        products[_productId].stock = _newStock;
        products[_productId].isAvailable = _newStock > 0;
    }

    // Order management functions
    function placeOrder(
        uint256 _userId,
        uint256 _productId,
        uint256 _quantity
    ) public returns (uint256) {
        require(users[_userId].id != 0, "User does not exist");
        require(products[_productId].id != 0, "Product does not exist");
        require(products[_productId].stock >= _quantity, "Insufficient stock");
        require(products[_productId].isAvailable, "Product not available");

        orderCount++;
        uint256 totalPrice = products[_productId].price * _quantity;

        orders[orderCount] = Order({
            id: orderCount,
            userId: _userId,
            productId: _productId,
            quantity: _quantity,
            totalPrice: totalPrice,
            status: OrderStatus.Pending,
            orderDate: block.timestamp,
            deliveryDate: 0
        });

        // Update stock
        products[_productId].stock -= _quantity;
        if (products[_productId].stock == 0) {
            products[_productId].isAvailable = false;
        }

        // Note: userProfiles functionality removed since it's not in the struct anymore

        emit OrderPlaced(orderCount, _userId, _productId);
        return orderCount;
    }

    function updateOrderStatus(uint256 _orderId, OrderStatus _newStatus) public {
        require(orders[_orderId].id != 0, "Order does not exist");
        orders[_orderId].status = _newStatus;
        
        if (_newStatus == OrderStatus.Delivered) {
            orders[_orderId].deliveryDate = block.timestamp;
        }

        emit OrderStatusUpdated(_orderId, _newStatus);
    }

    // View functions
    function getUser(uint256 _userId) public view returns (User memory) {
        return users[_userId];
    }

    function getProduct(uint256 _productId) public view returns (Product memory) {
        return products[_productId];
    }

    function getOrder(uint256 _orderId) public view returns (Order memory) {
        return orders[_orderId];
    }

    // getUserProfile function removed since userProfiles is not in the struct anymore

    function getOrderStatus(uint256 _orderId) public view returns (OrderStatus) {
        return orders[_orderId].status;
    }

    // Utility functions
    function isUserActive(uint256 _userId) public view returns (bool) {
        return users[_userId].isActive;
    }

    function getProductAvailability(uint256 _productId) public view returns (bool) {
        return products[_productId].isAvailable && products[_productId].stock > 0;
    }

    // getTotalOrdersByUser and getLoyaltyPoints functions removed since userProfiles is not in the struct anymore

    // Owner management functions
    function getOwner() public view returns (address) {
        return stored.owner;
    }

    function updateOwner(address _newOwner) public {
        require(msg.sender == stored.owner, "Only the current owner can update the owner");
        require(_newOwner != address(0), "New owner cannot be the zero address");
        stored.owner = _newOwner;
    }
}
