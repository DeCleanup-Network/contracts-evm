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
    uint256 public impactProductClaimReward = 10 ether; // 10 DCU for Impact Product claims
    uint256 public referralReward = 1 ether; // 1 DCU for referrals
    uint256 public streakReward = 3 ether; // 3 DCU for maintaining a 7-day streak
    
    // PoI verification tracking
    mapping(address => bool) public poiVerified;
    
    // Impact Product claim tracking (user => level => claimed)
    mapping(address => mapping(uint256 => bool)) public impactProductClaimed;
    
    // Streak tracking
    mapping(address => uint256) public lastPoiTimestamp;
    
    // Referral system
    mapping(address => address) public referrers; // invitee => referrer
    mapping(address => mapping(address => bool)) public referralRewarded; // referrer => invitee => rewarded
    
    // Events
    event RewardEarned(address indexed user, uint256 amount, string activityType);
    event RewardClaimed(address indexed user, uint256 amount);
    event PoiVerified(address indexed user, uint256 timestamp);
    event PoiStreakMaintained(address indexed user, uint256 timestamp);
    event PoiStreakReset(address indexed user, uint256 timestamp);
    event ReferralRegistered(address indexed referrer, address indexed invitee);
    event ReferralRewarded(address indexed referrer, address indexed invitee, uint256 amount);
    event ImpactProductClaimed(address indexed user, uint256 level);
    
    /**
     * @dev Constructor sets the DCU token address and initial reward amounts
     * @param _dcuToken Address of the DCU token contract
     */
    constructor(
        address _dcuToken
    ) Ownable(msg.sender) {
        dcuToken = IDCUToken(_dcuToken);
    }
    
    /**
     * @dev Set PoI verification status for a user
     * @param user Address of the user
     * @param verified Whether the PoI is verified
     */
    function setPoiVerificationStatus(address user, bool verified) external onlyOwner {
        poiVerified[user] = verified;
        
        if (verified) {
            uint256 currentTime = block.timestamp;
            emit PoiVerified(user, currentTime);
            
            // Check if this is a streak (within 7 days of last PoI)
            if (lastPoiTimestamp[user] > 0 && currentTime - lastPoiTimestamp[user] <= 7 days) {
                // Reward streak
                userBalances[user] += streakReward;
                emit PoiStreakMaintained(user, currentTime);
                emit RewardEarned(user, streakReward, "poi_streak");
            } else if (lastPoiTimestamp[user] > 0) {
                // Streak reset
                emit PoiStreakReset(user, currentTime);
            }
            
            // Update last PoI timestamp
            lastPoiTimestamp[user] = currentTime;
        }
    }
    
    /**
     * @dev Register a referral relationship
     * @param invitee Address of the invitee
     * @param referrer Address of the referrer
     */
    function registerReferral(address invitee, address referrer) external onlyOwner {
        require(invitee != address(0), "Invalid invitee address");
        require(referrer != address(0), "Invalid referrer address");
        require(invitee != referrer, "Self-referral not allowed");
        require(referrers[invitee] == address(0), "Referral already registered");
        
        referrers[invitee] = referrer;
        emit ReferralRegistered(referrer, invitee);
    }
    
    /**
     * @dev Rewards a user for successfully claiming an Impact Product
     * @param user Address of the user to reward
     * @param level Level of the Impact Product claimed
     */
    function rewardImpactProductClaim(address user, uint256 level) external onlyOwner {
        require(poiVerified[user], "PoI not verified");
        require(!impactProductClaimed[user][level], "Level already claimed");
        
        // Mark this level as claimed
        impactProductClaimed[user][level] = true;
        
        // Reward the user for claiming an Impact Product
        userBalances[user] += impactProductClaimReward;
        emit RewardEarned(user, impactProductClaimReward, "impact_product_claim");
        emit ImpactProductClaimed(user, level);
        
        // Check if there's a referrer to reward
        address referrer = referrers[user];
        if (referrer != address(0) && !referralRewarded[referrer][user]) {
            // Reward the referrer (only once per referred user)
            userBalances[referrer] += referralReward;
            referralRewarded[referrer][user] = true;
            emit RewardEarned(referrer, referralReward, "referral");
            emit ReferralRewarded(referrer, user, referralReward);
        }
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
     * @param _impactProductClaimReward New reward for Impact Product claims
     * @param _referralReward New reward for referrals
     * @param _streakReward New reward for streaks
     */
    function updateRewardAmounts(
        uint256 _impactProductClaimReward,
        uint256 _referralReward,
        uint256 _streakReward
    ) external onlyOwner {
        impactProductClaimReward = _impactProductClaimReward;
        referralReward = _referralReward;
        streakReward = _streakReward;
    }
    
    /**
     * @dev Check if a user has claimed a specific Impact Product level
     * @param user Address of the user
     * @param level Level of the Impact Product
     * @return Whether the level has been claimed
     */
    function hasClaimedLevel(address user, uint256 level) external view returns (bool) {
        return impactProductClaimed[user][level];
    }
    
    /**
     * @dev Get the referrer of a user
     * @param invitee Address of the invitee
     * @return The referrer's address
     */
    function getReferrer(address invitee) external view returns (address) {
        return referrers[invitee];
    }
    
    /**
     * @dev Check if a referrer has been rewarded for an invitee
     * @param referrer Address of the referrer
     * @param invitee Address of the invitee
     * @return Whether the referrer has been rewarded
     */
    function isReferralRewarded(address referrer, address invitee) external view returns (bool) {
        return referralRewarded[referrer][invitee];
    }
    
    /**
     * @dev Get the timestamp of the last verified PoI for a user
     * @param user Address of the user
     * @return The timestamp of the last verified PoI
     */
    function getLastPoiTimestamp(address user) external view returns (uint256) {
        return lastPoiTimestamp[user];
    }
} 