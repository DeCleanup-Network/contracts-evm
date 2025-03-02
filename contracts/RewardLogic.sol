// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDCUToken.sol";
import "./interfaces/INFTCollection.sol";

contract RewardLogic is Ownable {
    IDCUToken public dcuToken;
    INFTCollection public nftCollection;
    
    // Events for tracking reward distributions
    event RewardDistributed(
        address indexed user,
        uint256 amount,
        uint256 nftBalance,
        uint256 timestamp
    );
    
    constructor(address _dcuToken, address _nftCollection) Ownable(msg.sender) {
        dcuToken = IDCUToken(_dcuToken);
        nftCollection = INFTCollection(_nftCollection);
    }

    function calculateReward(address user) public view returns (uint256) {
        // Implement reward calculation logic based on NFT holdings
        uint256 nftBalance = nftCollection.balanceOf(user);
        return nftBalance * 100 ether; // Example: 100 DCU per NFT
    }

    function distributeReward(address user) external {
        uint256 reward = calculateReward(user);
        require(dcuToken.mint(user, reward), "Reward distribution failed");
        
        // Emit event for tracking reward distribution
        emit RewardDistributed(
            user,
            reward,
            nftCollection.balanceOf(user),
            block.timestamp
        );
    }
} 