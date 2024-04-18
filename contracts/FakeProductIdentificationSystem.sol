// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FakeProductIdentificationSystem {
    address public owner;

    struct Product {
        address owner;
        string name;
        string description;
        string manufacturer;
        uint256 productionDate;
        uint256 expiryDate;
        uint256 batchNumber;
        bool verified;
        address[] verifiers;
        address newOwner; // For ownership transfer
        bool ownershipTransferPending;
        uint256[] actionTimestamps; // For product history
        string[] actionDescriptions; // For product history
    }

    // Define a new struct to hold the product details
    struct ProductDetails {
        address owner;
        string name;
        string description;
        string manufacturer;
        uint256 productionDate;
        uint256 expiryDate;
        uint256 batchNumber;
        bool verified;
        address[] verifiers;
        address newOwner;
        bool ownershipTransferPending;
        uint256[] actionTimestamps;
        string[] actionDescriptions;
    }

    mapping(uint256 => Product) public products;
    mapping(uint256 => bool) public passcodeExists;
    uint256 public productCount;

    event ProductRegistered(uint256 indexed passcode, address indexed owner, string name, string description, string manufacturer, uint256 productionDate, uint256 expiryDate, uint256 batchNumber);
    event ProductVerified(uint256 indexed passcode, address indexed verifier);
    event ProductOwnershipTransferRequested(uint256 indexed passcode, address indexed currentOwner, address indexed newOwner);
    event ProductOwnershipTransferred(uint256 indexed passcode, address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Invalid new owner address");
        address previousOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function registerProduct(string memory _name, string memory _description, string memory _manufacturer, uint256 _productionDate, uint256 _expiryDate, uint256 _batchNumber, uint256 _passcode) public {
        require(!passcodeExists[_passcode], "Product with this passcode already exists");
        products[_passcode] = Product({
            owner: msg.sender,
            name: _name,
            description: _description,
            manufacturer: _manufacturer,
            productionDate: _productionDate,
            expiryDate: _expiryDate,
            batchNumber: _batchNumber,
            verified: false,
            verifiers: new address[](0),
            newOwner: address(0),
            ownershipTransferPending: false,
            actionTimestamps: new uint256[](0),
            actionDescriptions: new string[](0)
        });
        passcodeExists[_passcode] = true;
        productCount++;
        emit ProductRegistered(_passcode, msg.sender, _name, _description, _manufacturer, _productionDate, _expiryDate, _batchNumber);
    }

    function verifyProduct(uint256 _passcode) public {
        require(passcodeExists[_passcode], "Product does not exist");
        require(!products[_passcode].verified, "Product already verified");

        products[_passcode].verified = true;
        products[_passcode].verifiers.push(msg.sender);
        emit ProductVerified(_passcode, msg.sender);
    }

    function requestOwnershipTransfer(uint256 _passcode, address _newOwner) public {
        require(passcodeExists[_passcode], "Product does not exist");
        require(msg.sender == products[_passcode].owner, "Only the current owner can request ownership transfer");
        require(_newOwner != address(0), "Invalid new owner address");
        require(_newOwner != msg.sender, "New owner cannot be the same as the current owner");

        products[_passcode].newOwner = _newOwner;
        products[_passcode].ownershipTransferPending = true;
        emit ProductOwnershipTransferRequested(_passcode, msg.sender, _newOwner);
    }

    function acceptOwnershipTransfer(uint256 _passcode) public {
        require(passcodeExists[_passcode], "Product does not exist");
        require(msg.sender == products[_passcode].newOwner, "Only the new owner can accept ownership transfer");
        require(products[_passcode].ownershipTransferPending, "Ownership transfer not requested or already accepted");

        address previousOwner = products[_passcode].owner;
        products[_passcode].owner = msg.sender;
        products[_passcode].newOwner = address(0);
        products[_passcode].ownershipTransferPending = false;
        emit ProductOwnershipTransferred(_passcode, previousOwner, msg.sender);
    }

    // Modify the getProduct function to return a ProductDetails struct
    function getProduct(uint256 _passcode) public view returns (ProductDetails memory) {
        require(passcodeExists[_passcode], "Product does not exist");
        Product memory product = products[_passcode];
        return ProductDetails({
            owner: product.owner,
            name: product.name,
            description: product.description,
            manufacturer: product.manufacturer,
            productionDate: product.productionDate,
            expiryDate: product.expiryDate,
            batchNumber: product.batchNumber,
            verified: product.verified,
            verifiers: product.verifiers,
            newOwner: product.newOwner,
            ownershipTransferPending: product.ownershipTransferPending,
            actionTimestamps: product.actionTimestamps,
            actionDescriptions: product.actionDescriptions
        });
    }

    function addAction(uint256 _passcode, string memory _description) public {
        require(passcodeExists[_passcode], "Product does not exist");
        require(msg.sender == products[_passcode].owner || msg.sender == owner, "Only the owner or contract owner can add actions");

        // Check if the action is already present in the array
        bool actionExists = false;
        for (uint i = 0; i < products[_passcode].actionDescriptions.length; i++) {
            if (keccak256(abi.encodePacked(products[_passcode].actionDescriptions[i])) == keccak256(abi.encodePacked(_description))) {
                actionExists = true;
                break;
            }
        }
        require(!actionExists, "Action already exists");

        products[_passcode].actionTimestamps.push(block.timestamp);
        products[_passcode].actionDescriptions.push(_description);
    }
}
