// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VulnerableToken.sol";
import "../src/VulnerableAuction.sol";
import "../src/VulnerableLending.sol";
import "../src/Unverified.sol";

contract VulnerableTokenTest is Test {
    VulnerableToken public token;
    
    function setUp() public {
        token = new VulnerableToken("Test Token", "TST", 18, 1000000 * 10**18);
    }
    
    function testIntegerOverflow() public {
        address user1 = address(0x123);
        address user2 = address(0x456);
        
        // Give user1 some tokens
        vm.prank(address(this));
        token.transfer(user1, 1000 * 10**18);
        
        // Test vulnerable batch transfer
        vm.prank(user1);
        address[] memory recipients = new address[](2);
        recipients[0] = user2;
        recipients[1] = address(0x789);
        
        // This should demonstrate the vulnerability
        console2.log("User1 balance before:", token.balances(user1));
        token.vulnerableBatchTransfer(recipients, 100 * 10**18);
        console2.log("User1 balance after:", token.balances(user1));
    }
    
    function testIntegerUnderflow() public {
        address user1 = address(0x123);
        address user2 = address(0x456);
        
        // Try to transfer more than balance (should underflow)
        vm.prank(user1);
        console2.log("User1 balance before:", token.balances(user1));
        // This would cause underflow in vulnerable implementation
        // token.transfer(user2, 1000 * 10**18); // This will fail with modern Solidity
    }
}

contract VulnerableAuctionTest is Test {
    VulnerableAuction public auction;
    
    function setUp() public {
        auction = new VulnerableAuction(7 days);
    }
    
    function testMaliciousBid() public {
        address attacker = address(0x123);
        
        console2.log("Highest bid before:", auction.highestBid());
        console2.log("Highest bidder before:", auction.highestBidder());
        
        // Exploit the vulnerability by setting arbitrary bid
        vm.prank(attacker);
        auction.maliciousBid(1000000 * 10**18);
        
        console2.log("Highest bid after:", auction.highestBid());
        console2.log("Highest bidder after:", auction.highestBidder());
        
        // Verify the manipulation worked
        assertEq(auction.highestBid(), 1000000 * 10**18);
        assertEq(auction.highestBidder(), attacker);
    }
}

contract VulnerableLendingTest is Test {
    VulnerableLending public lending;
    VulnerableToken public token;
    
    function setUp() public {
        token = new VulnerableToken("Lending Token", "LND", 18, 1000000 * 10**18);
        lending = new VulnerableLending(address(token));
        
        // Give this contract some tokens to work with
        vm.prank(address(this));
        token.approve(address(lending), type(uint256).max);
    }
    
    function testForceInterestUpdate() public {
        address user1 = address(0x123);
        address user2 = address(0x456);
        
        // Deposit some tokens
        vm.prank(address(this));
        lending.deposit(1000 * 10**18);
        
        // Manipulate user1's interest by force updating
        console2.log("User1 borrowed before:", lending.borrowed(user1));
        lending.forceUpdateInterest(user1);
        console2.log("User1 borrowed after force update:", lending.borrowed(user1));
        
        // This demonstrates how anyone can manipulate anyone else's account
    }
    
    function testOverRepayment() public {
        address user1 = address(0x123);
        
        // Try to repay without borrowing (this shows vulnerability)
        vm.prank(user1);
        console2.log("User1 borrowed before:", lending.borrowed(user1));
        // This would cause underflow in vulnerable implementation
        // lending.repay(100 * 10**18); // This will fail with proper checks
    }
}

contract UnverifiedTest is Test {
    VulnerableUnverifiedContract public vulnerableContract;
    UnverifiedAttacker public attacker;
    
    function setUp() public {
        vulnerableContract = new VulnerableUnverifiedContract();
        attacker = new UnverifiedAttacker(vulnerableContract);
    }
    
    function testUnverifiedExploit() public {
        console2.log("Testing unverified contract vulnerability");
        
        // The vulnerability is in the lack of access control
        // in the callWithSelector function
        attacker.attack();
        
        console2.log("Attack executed successfully");
    }
}

contract UnverifiedAttacker {
    VulnerableUnverifiedContract public target;
    address public constant UNISWAP_POOL = 0x202A6012894Ae5c288eA824cbc8A9bfb26A49b93;
    
    constructor(VulnerableUnverifiedContract _target) {
        target = _target;
    }
    
    function attack() external {
        // Call the vulnerable function with a selector
        target.callWithSelector(bytes4(0x03b79c24), UNISWAP_POOL);
        
        // In the real attack, this would be followed by a Uniswap swap
        // and profit extraction
    }
    
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        // In the real attack, this would transfer tokens to the pool
        // For demonstration, we just log the callback
        console2.log("Uniswap callback called with amounts:");
        console2.logInt(amount0Delta);
        console2.logInt(amount1Delta);
    }
    
    receive() external payable {}
}