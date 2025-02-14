// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Use OpenZeppelin's IERC20 interface instead of a custom one
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract JobBoard {
    IERC20 public token;
    uint256 public jobCounter;
    
    struct Job {
        address employer;
        uint256 stake;
        bool isActive;
    }
    
    mapping(uint256 => Job) public jobs;

    constructor(address _token) {
        token = IERC20(_token);  // Explicit ERC20 interface assignment
    }

    function createJobListing(uint256 stakeAmount) external {
        require(stakeAmount > 0, "Stake required");
        
        // First get approval, then use transferFrom
        require(
            token.allowance(msg.sender, address(this)) >= stakeAmount,
            "Not enough allowance"
        );
        
        require(
            token.transferFrom(msg.sender, address(this), stakeAmount),
            "Transfer failed"
        );
        
        jobCounter++;
        jobs[jobCounter] = Job(msg.sender, stakeAmount, true);
    }
}
