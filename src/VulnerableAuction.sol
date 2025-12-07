// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VulnerableAuction {
    address public owner;
    address public highestBidder;
    uint256 public highestBid;
    uint256 public auctionEndTime;
    bool public ended;
    
    mapping(address => uint256) public pendingReturns;
    
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionEnded(address winner, uint256 amount);
    
    constructor(uint256 _biddingTime) {
        owner = msg.sender;
        auctionEndTime = block.timestamp + _biddingTime;
    }
    
    // Vulnerable to reentrancy, but let's make it a different vulnerability
    function bid() external payable {
        require(block.timestamp < auctionEndTime, "Auction ended");
        require(msg.value > highestBid, "Bid not high enough");
        
        // Vulnerable - refund previous bidder
        if (highestBidder != address(0)) {
            // Vulnerable to gas griefing - sending to contract without fallback
            pendingReturns[highestBidder] += highestBid;
        }
        
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncreased(msg.sender, msg.value);
    }
    
    // Vulnerable withdraw function
    function withdraw() external returns (bool) {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw");
        
        // Vulnerable - reset before external call
        pendingReturns[msg.sender] = 0;
        
        // Vulnerable to gas griefing - no check on return value
        (bool success, ) = msg.sender.call{value: amount}("");
        // No check if success is true!
        
        return true;
    }
    
    // Vulnerable to front-running
    function endAuction() external {
        require(block.timestamp >= auctionEndTime, "Auction not yet ended");
        require(!ended, "Auction already ended");
        
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);
        
        // Vulnerable - sending to contract without checking if it can accept ETH
        (bool success, ) = owner.call{value: highestBid}("");
        // No check if success is true!
    }
    
    // Vulnerable function that can be manipulated
    function maliciousBid(uint256 amount) external {
        // Vulnerable - allows setting arbitrary bid without sending ETH
        highestBid = amount;
        highestBidder = msg.sender;
    }
}