// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RealEstateTokenization {
    struct Property {
        uint256 id;
        string name;
        string location;
        uint256 totalTokens;
        uint256 tokenPrice;
        uint256 tokensAvailable;
        address owner;
        bool isActive;
        uint256 createdAt;
    }

    struct Investment {
        uint256 propertyId;
        uint256 tokens;
        uint256 investmentAmount;
        uint256 timestamp;
    }

    mapping(uint256 => Property) public properties;
    mapping(address => mapping(uint256 => uint256)) public investorTokens;
    mapping(address => Investment[]) public investorHistory;
    mapping(uint256 => address[]) public propertyInvestors;

    uint256 public propertyCounter;
    uint256 public totalValueLocked;
    address public owner;

    event PropertyListed(uint256 indexed propertyId, string name, uint256 totalTokens, uint256 tokenPrice);
    event TokensPurchased(address indexed investor, uint256 indexed propertyId, uint256 tokens, uint256 amount);
    event PropertyStatusChanged(uint256 indexed propertyId, bool isActive);
    event RevenueDistributed(uint256 indexed propertyId, uint256 totalRevenue);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier propertyExists(uint256 _propertyId) {
        require(_propertyId > 0 && _propertyId <= propertyCounter, "Property does not exist");
        _;
    }

    constructor() {
        owner = msg.sender;
        propertyCounter = 0;
        totalValueLocked = 0;
    }

    function listProperty(
        string memory _name,
        string memory _location,
        uint256 _totalTokens,
        uint256 _tokenPrice
    ) external onlyOwner returns (uint256) {
        require(_totalTokens > 0, "Total tokens must be greater than 0");
        require(_tokenPrice > 0, "Token price must be greater than 0");

        propertyCounter++;
        
        properties[propertyCounter] = Property({
            id: propertyCounter,
            name: _name,
            location: _location,
            totalTokens: _totalTokens,
            tokenPrice: _tokenPrice,
            tokensAvailable: _totalTokens,
            owner: msg.sender,
            isActive: true,
            createdAt: block.timestamp
        });

        emit PropertyListed(propertyCounter, _name, _totalTokens, _tokenPrice);
        return propertyCounter;
    }

    function purchaseTokens(uint256 _propertyId, uint256 _tokens) 
        external 
        payable 
        propertyExists(_propertyId) 
    {
        Property storage property = properties[_propertyId];
        require(property.isActive, "Property is not active");
        require(_tokens > 0, "Token amount must be greater than 0");
        require(_tokens <= property.tokensAvailable, "Not enough tokens available");
        
        uint256 totalCost = _tokens * property.tokenPrice;
        require(msg.value >= totalCost, "Insufficient payment");

        property.tokensAvailable -= _tokens;
        investorTokens[msg.sender][_propertyId] += _tokens;
        totalValueLocked += totalCost;

        // Add to investor history
        investorHistory[msg.sender].push(Investment({
            propertyId: _propertyId,
            tokens: _tokens,
            investmentAmount: totalCost,
            timestamp: block.timestamp
        }));

        // Add to property investors if first investment
        if (investorTokens[msg.sender][_propertyId] == _tokens) {
            propertyInvestors[_propertyId].push(msg.sender);
        }

        // Refund excess payment
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        emit TokensPurchased(msg.sender, _propertyId, _tokens, totalCost);
    }

    function distributeRevenue(uint256 _propertyId) 
        external 
        payable 
        onlyOwner 
        propertyExists(_propertyId) 
    {
        require(msg.value > 0, "Revenue amount must be greater than 0");
        
        Property storage property = properties[_propertyId];
        uint256 totalDistributedTokens = property.totalTokens - property.tokensAvailable;
        require(totalDistributedTokens > 0, "No tokens have been sold for this property");

        address[] memory investors = propertyInvestors[_propertyId];
        
        for (uint256 i = 0; i < investors.length; i++) {
            address investor = investors[i];
            uint256 investorTokenCount = investorTokens[investor][_propertyId];
            
            if (investorTokenCount > 0) {
                uint256 revenue = (msg.value * investorTokenCount) / totalDistributedTokens;
                payable(investor).transfer(revenue);
            }
        }

        emit RevenueDistributed(_propertyId, msg.value);
    }

    function getPropertyDetails(uint256 _propertyId) 
        external 
        view 
        propertyExists(_propertyId) 
        returns (
            string memory name,
            string memory location,
            uint256 totalTokens,
            uint256 tokenPrice,
            uint256 tokensAvailable,
            bool isActive
        ) 
    {
        Property storage property = properties[_propertyId];
        return (
            property.name,
            property.location,
            property.totalTokens,
            property.tokenPrice,
            property.tokensAvailable,
            property.isActive
        );
    }
}
