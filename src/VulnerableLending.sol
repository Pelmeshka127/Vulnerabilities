// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract VulnerableLending {
    IERC20 public token;
    mapping(address => uint256) public deposits;
    mapping(address => uint256) public borrowed;
    mapping(address => uint256) public lastInterestUpdate;
    
    uint256 public constant INTEREST_RATE = 5; // 5% per year
    uint256 public constant INTEREST_DENOMINATOR = 100;
    
    event Deposit(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);
    
    constructor(address _token) {
        token = IERC20(_token);
    }
    
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        // Vulnerable to rounding errors
        deposits[msg.sender] += amount;
        lastInterestUpdate[msg.sender] = block.timestamp;
        emit Deposit(msg.sender, amount);
    }
    
    function borrow(uint256 amount) external {
        // Vulnerable - no collateral check
        uint256 available = getAvailableToBorrow(msg.sender);
        require(amount <= available, "Insufficient collateral");
        
        // Vulnerable to integer overflow in some conditions
        borrowed[msg.sender] += amount;
        lastInterestUpdate[msg.sender] = block.timestamp;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Borrow(msg.sender, amount);
    }
    
    function repay(uint256 amount) external {
        // Vulnerable - allows over-repayment
        borrowed[msg.sender] -= amount;
        lastInterestUpdate[msg.sender] = block.timestamp;
        
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit Repay(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external {
        updateInterest(msg.sender);
        
        // Vulnerable - no check if user has enough deposited
        deposits[msg.sender] -= amount;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
    }
    
    // Vulnerable function with incorrect interest calculation
    function getAvailableToBorrow(address user) public view returns (uint256) {
        // Vulnerable - incorrect interest calculation
        uint256 timePassed = block.timestamp - lastInterestUpdate[user];
        uint256 interest = (borrowed[user] * INTEREST_RATE * timePassed) / (365 days * INTEREST_DENOMINATOR);
        
        // Vulnerable - can return incorrect values due to integer division
        return (deposits[user] * 75) / 100 - (borrowed[user] + interest);
    }
    
    function updateInterest(address user) internal {
        // Vulnerable - incorrect interest calculation
        uint256 timePassed = block.timestamp - lastInterestUpdate[user];
        uint256 interest = (borrowed[user] * INTEREST_RATE * timePassed) / (365 days * INTEREST_DENOMINATOR);
        
        // Vulnerable - can cause overflow
        borrowed[user] += interest;
        lastInterestUpdate[user] = block.timestamp;
    }
    
    // Vulnerable function that allows manipulation
    function forceUpdateInterest(address user) external {
        // Vulnerable - anyone can update anyone else's interest
        updateInterest(user);
    }
}