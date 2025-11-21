// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract ValueStore {
    // *** UINT STORE *** 

    uint256 public numberValue;
    
    function getNumberValue() public view returns (uint256) {
        return numberValue;
    }

    function setNumberValue(uint256 _numberValue) public {
        numberValue = _numberValue;
    }

    // *** STRING STORE *** 

    string public stringValue;

    function getStringValue() public view returns (string memory) {
        return stringValue;
    }

    function setStringValue(string memory _stringValue) public {
        stringValue = _stringValue;
    }

    // *** SIMPLE STRUCT STORE *** 

    enum Status { Pending, Active, Inactive }

    struct CustomStruct {
        bool boolVal;
        uint256 uintVal;
        int128 intVal;
        address addressVal;
        string stringVal;
        bytes32 bytes32Val;
        Status statusVal;
    }

    CustomStruct public structValue;

    function getStructValue() public view returns (CustomStruct memory) {
        return structValue;
    }

    function setStructValue(CustomStruct calldata _structValue) public {
        structValue = _structValue;
    }

    // *** COMPLEX STRUCT STORE *** 

    struct ComplexStruct {
        CustomStruct customStruct;
        uint256 uintVal;
        string stringVal;
        string[] dynamicArrayVal;
        uint256[3] fixedArrayVal;
    }

    ComplexStruct public complexStructValue;

    function getComplexStructValue() public view returns (ComplexStruct memory) {
        return complexStructValue;
    }

    function setComplexStructValue(ComplexStruct calldata _complexStructValue) public {
        complexStructValue = _complexStructValue;
    }

    // *** UINT MAPPING STORE *** 

    mapping(uint256 => uint256) public uintMappingValue;

    function getUintMappingValue(uint256 key) public view returns (uint256) {
        return uintMappingValue[key];
    }

    function setUintMappingValue(uint256 key, uint256 value) public {
        uintMappingValue[key] = value;
    }

    // *** STRUCT MAPPING STORE *** 

    mapping(uint256 => CustomStruct) public structMappingValue;

    function getStructMappingValue(uint256 key) public view returns (CustomStruct memory) {
        return structMappingValue[key];
    }

    function setStructMappingValue(uint256 key, CustomStruct memory value) public {
        structMappingValue[key] = value;
    }

    // *** STRING ARRAY STORE *** 

    string[] public stringArray;
 
    function getStringArrayElement(uint256 index) public view returns (string memory) {
        return stringArray[index];
    }
    
    function getAllStringsInArray() public view returns (string[] memory) {
        return stringArray;
    }

    function pushString(string memory _str) public {
        stringArray.push(_str);
    }

    function popString() public {
        stringArray.pop();
    }

    // *** ETH STORE ***

    mapping(address => uint256) public balances;

    function deposit() public payable {
        require(msg.value > 0, "ValueStore: deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(amount > 0, "ValueStore: withdraw amount must be greater than 0");
        require(balances[msg.sender] >= amount, "ValueStore: insufficient balance");
        
        balances[msg.sender] -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "ValueStore: transfer failed");
    }

    receive() external payable {
        require(msg.value > 0, "ValueStore: deposit amount must be greater than 0");
        balances[msg.sender] += msg.value;
    }

    fallback() external payable {
        if (msg.value > 0) {
            balances[msg.sender] += msg.value;
        }
    }
}

