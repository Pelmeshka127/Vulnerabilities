// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VulnerableUnverifiedContract {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    // Vulnerable function - no proper access control
    function callWithSelector(bytes4 selector, address target) external payable {
        // No validation of caller or target
        (bool success, ) = target.call(abi.encodeWithSelector(selector));
        require(success, "Call failed");
    }
}