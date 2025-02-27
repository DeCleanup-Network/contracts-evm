// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDCUToken.sol";

/**
 * @title DCURewardManager
 * @dev Contract for managing DCU rewards for users based on various activities
 */
contract DCURewardManager is Ownable {
    // Reference to the DCU token contract
    IDCUToken public dcuToken;
    
    // Mapping from user address to their DCU balance
    mapping(address => uint256) public userBalances;
    
    // Reward amounts for different activities
    uint256 public dipClaimReward;
    uint256 public referralReward;
    uint256 public streakReward;
    
    // Events
    event RewardEarned(address indexed user, uint256 amount, string activityType);
    event RewardClaimed(address indexed user, uint256 amount);
    
    /**
     * @dev Constructor sets the DCU token address and initial reward amounts
     * @param _dcuToken Address of the DCU token contract
     * @param _dipClaimReward Initial reward amount for dIP claims
     * @param _referralReward Initial reward amount for referrals
     * @param _streakReward Initial reward amount for streaks
     */
    constructor(
        address _dcuToken,
        uint256 _dipClaimReward,
        uint256 _referralReward,
        uint256 _streakReward
    ) Ownable(msg.sender) {
        dcuToken = IDCUToken(_dcuToken);
        dipClaimReward = _dipClaimReward;
        referralReward = _referralReward;
        streakReward = _streakReward;
    }
    
    /**
     * @dev Rewards a user for successfully claiming a dIP
     * @param user Address of the user to reward
     */
    function rewardDipClaim(address user) external onlyOwner {
        userBalances[user] += dipClaimReward;
        emit RewardEarned(user, dipClaimReward, "dip_claim");
    }
    
    /**
     * @dev Rewards a user for a successful referral
     * @param user Address of the user to reward
     */
    function rewardReferral(address user) external onlyOwner {
        userBalances[user] += referralReward;
        emit RewardEarned(user, referralReward, "referral");
    }
    
    /**
     * @dev Rewards a user for maintaining a streak
     * @param user Address of the user to reward
     */
    function rewardStreak(address user) external onlyOwner {
        userBalances[user] += streakReward;
        emit RewardEarned(user, streakReward, "streak");
    }
    
    /**
     * @dev Custom reward amount for special cases
     * @param user Address of the user to reward
     * @param amount Amount of DCU to reward
     * @param activityType String describing the activity type
     */
    function rewardCustom(address user, uint256 amount, string calldata activityType) external onlyOwner {
        userBalances[user] += amount;
        emit RewardEarned(user, amount, activityType);
    }
    
    /**
     * @dev Get the DCU balance of a user
     * @param user Address of the user
     * @return The user's DCU balance
     */
    function getBalance(address user) external view returns (uint256) {
        return userBalances[user];
    }
    
    /**
     * @dev Allows a user to claim their earned DCU rewards
     * @param amount Amount of DCU to claim
     */
    function claimRewards(uint256 amount) external {
        require(userBalances[msg.sender] >= amount, "Insufficient balance");
        userBalances[msg.sender] -= amount;
        require(dcuToken.mint(msg.sender, amount), "Reward distribution failed");
        emit RewardClaimed(msg.sender, amount);
    }
    
    /**
     * @dev Update reward amounts (only owner)
     * @param _dipClaimReward New reward for dIP claims
     * @param _referralReward New reward for referrals
     * @param _streakReward New reward for streaks
     */
    function updateRewardAmounts(
        uint256 _dipClaimReward,
        uint256 _referralReward,
        uint256 _streakReward
    ) external onlyOwner {
        dipClaimReward = _dipClaimReward;
        referralReward = _referralReward;
        streakReward = _streakReward;
    }
} 