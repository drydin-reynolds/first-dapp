// contracts/JobBoard.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract JobBoard {
    IERC20 public stakingToken; // Likely ETH or approved ERC20
    uint256 public immutable MIN_STAKE;  

    struct Job {
        address employer;
        uint256 stake;
        bool isActive;
        bytes32 ipfsHash; // Stores listing text & AI analysis
    }

    Job[] public jobs;
    
    constructor(address _token, uint256 _minStake) {
        stakingToken = IERC20(_token);
        MIN_STAKE = _minStake;
    }

    function createJob(bytes32 _ipfsHash) external {
        stakingToken.transferFrom(msg.sender, address(this), MIN_STAKE);
        jobs.push(Job(msg.sender, MIN_STAKE, false, _ipfsHash));
    }
}
