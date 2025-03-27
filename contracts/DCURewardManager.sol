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
    
    // Constants for validation
    uint256 public constant MAX_LEVEL = 10;
    uint256 public constant MAX_REWARD_AMOUNT = 1000 ether; // 1000 DCU maximum reward limit
    
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
    
    // Reward tracking for analytics
    mapping(address => uint256) public totalClaimRewards; // Total rewards from Impact Product claims
    mapping(address => uint256) public totalStreakRewards; // Total rewards from streaks
    mapping(address => uint256) public totalReferralRewards; // Total rewards from referrals
    mapping(address => uint256) public totalRewardsClaimed; // Total rewards claimed (post-TGE)
    
    // Struct for user reward stats to avoid stack too deep errors
    struct UserRewardStats {
        uint256 currentBalance;
        uint256 totalEarned;
        uint256 totalClaimed;
        uint256 claimRewardsAmount;
        uint256 streakRewardsAmount;
        uint256 referralRewardsAmount;
    }
    
    // Struct for user PoI stats
    struct UserPoiStats {
        uint256 lastPoiTime;
        bool isPoiVerified;
    }
    
    // Events
    event RewardClaimed(address indexed user, uint256 amount);
    event PoiVerified(address indexed user, uint256 timestamp);
    event PoiStreakReset(address indexed user, uint256 timestamp);
    event ReferralRegistered(address indexed referrer, address indexed invitee);
    
    // Consolidated reward events with detailed information
    event DCURewardImpactProduct(
        address indexed user, 
        uint256 amount, 
        uint256 level, 
        uint256 timestamp, 
        uint256 newBalance
    );
    
    event DCURewardStreak(
        address indexed user, 
        uint256 amount, 
        uint256 streakDays, 
        uint256 timestamp, 
        uint256 newBalance
    );
    
    event DCURewardReferral(
        address indexed referrer, 
        address indexed invitee, 
        uint256 amount, 
        uint256 timestamp, 
        uint256 newBalance
    );
    
    // Modifier for level validation
    modifier validLevel(uint256 level) {
        require(level > 0 && level <= MAX_LEVEL, "Invalid level range");
        _;
    }
    
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
        require(user != address(0), "Invalid user address");
        poiVerified[user] = verified;
        
        if (verified) {
            uint256 currentTime = block.timestamp;
            emit PoiVerified(user, currentTime);
            
            // Check if this is a streak (within 7 days of last PoI)
            if (lastPoiTimestamp[user] > 0 && currentTime - lastPoiTimestamp[user] <= 7 days) {
                // Reward streak
                userBalances[user] += streakReward;
                totalStreakRewards[user] += streakReward;
                
                // Calculate streak days (approximate)
                uint256 streakDays = (currentTime - lastPoiTimestamp[user]) / 1 days;
                if (streakDays == 0) streakDays = 1; // Minimum 1 day
                
                // Emit consolidated streak reward event
                emit DCURewardStreak(
                    user,
                    streakReward,
                    streakDays,
                    currentTime,
                    userBalances[user]
                );
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
    function rewardImpactProductClaim(address user, uint256 level) external onlyOwner validLevel(level) {
        require(poiVerified[user], "PoI not verified");
        require(!impactProductClaimed[user][level], "Level already claimed");
        require(user != address(0), "Invalid user address");
        
        // Mark this level as claimed
        impactProductClaimed[user][level] = true;
        
        // Reward the user for claiming an Impact Product
        userBalances[user] += impactProductClaimReward;
        totalClaimRewards[user] += impactProductClaimReward;
        
        uint256 currentTime = block.timestamp;
        
        // Emit consolidated impact product reward event
        emit DCURewardImpactProduct(
            user,
            impactProductClaimReward,
            level,
            currentTime,
            userBalances[user]
        );
        
        // Check if there's a referrer to reward
        address referrer = referrers[user];
        if (referrer != address(0) && !referralRewarded[referrer][user]) {
            // Reward the referrer (only once per referred user)
            userBalances[referrer] += referralReward;
            totalReferralRewards[referrer] += referralReward;
            referralRewarded[referrer][user] = true;
            
            // Emit consolidated referral reward event
            emit DCURewardReferral(
                referrer,
                user,
                referralReward,
                currentTime,
                userBalances[referrer]
            );
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
        require(amount > 0, "Amount must be greater than zero");
        require(userBalances[msg.sender] >= amount, "Insufficient balance");
        userBalances[msg.sender] -= amount;
        totalRewardsClaimed[msg.sender] += amount;
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
        require(_impactProductClaimReward <= MAX_REWARD_AMOUNT, "Impact product claim reward too high");
        require(_referralReward <= MAX_REWARD_AMOUNT, "Referral reward too high");
        require(_streakReward <= MAX_REWARD_AMOUNT, "Streak reward too high");
        
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
    
    /**
     * @dev Get the total earned DCU for a user (before claiming)
     * @param user Address of the user
     * @return Total earned DCU, including current balance and already claimed amount
     */
    function getTotalEarnedDCU(address user) external view returns (uint256) {
        return userBalances[user] + totalRewardsClaimed[user];
    }
    
    /**
     * @dev Get the breakdown of rewards for a user
     * @param user Address of the user
     * @return claimRewardsAmount Total rewards from Impact Product claims
     * @return streakRewardsAmount Total rewards from streaks
     * @return referralRewardsAmount Total rewards from referrals
     * @return currentBalance Current unclaimed balance
     * @return claimedRewards Total rewards already claimed
     */
    function getRewardsBreakdown(address user) external view returns (
        uint256 claimRewardsAmount,
        uint256 streakRewardsAmount,
        uint256 referralRewardsAmount,
        uint256 currentBalance,
        uint256 claimedRewards
    ) {
        return (
            totalClaimRewards[user],
            totalStreakRewards[user],
            totalReferralRewards[user],
            userBalances[user],
            totalRewardsClaimed[user]
        );
    }
    
    /**
     * @dev Get user reward stats
     * @param user Address of the user
     * @return stats Struct containing reward stats
     */
    function getUserRewardStats(address user) external view returns (UserRewardStats memory stats) {
        stats.currentBalance = userBalances[user];
        stats.totalEarned = userBalances[user] + totalRewardsClaimed[user];
        stats.totalClaimed = totalRewardsClaimed[user];
        stats.claimRewardsAmount = totalClaimRewards[user];
        stats.streakRewardsAmount = totalStreakRewards[user];
        stats.referralRewardsAmount = totalReferralRewards[user];
        return stats;
    }
    
    /**
     * @dev Get user PoI stats
     * @param user Address of the user
     * @return stats Struct containing PoI stats
     */
    function getUserPoiStats(address user) external view returns (UserPoiStats memory stats) {
        stats.lastPoiTime = lastPoiTimestamp[user];
        stats.isPoiVerified = poiVerified[user];
        return stats;
    }
    
    /**
     * @dev Get complete user stats for frontend display (compatibility function)
     * @param user Address of the user
     * @return currentBalance The user's current unclaimed balance
     * @return totalEarned Total DCU earned (claimed + unclaimed)
     * @return totalClaimed Total DCU already claimed
     * @return claimRewardsAmount Total rewards from Impact Product claims
     * @return streakRewardsAmount Total rewards from streaks
     * @return referralRewardsAmount Total rewards from referrals
     * @return lastPoiTime Timestamp of the last verified PoI
     * @return isPoiVerified Whether the user's PoI is currently verified
     */
    function getUserStats(address user) external view returns (
        uint256 currentBalance,
        uint256 totalEarned,
        uint256 totalClaimed,
        uint256 claimRewardsAmount,
        uint256 streakRewardsAmount,
        uint256 referralRewardsAmount,
        uint256 lastPoiTime,
        bool isPoiVerified
    ) {
        UserRewardStats memory rewardStats = this.getUserRewardStats(user);
        UserPoiStats memory poiStats = this.getUserPoiStats(user);
        
        return (
            rewardStats.currentBalance,
            rewardStats.totalEarned,
            rewardStats.totalClaimed,
            rewardStats.claimRewardsAmount,
            rewardStats.streakRewardsAmount,
            rewardStats.referralRewardsAmount,
            poiStats.lastPoiTime,
            poiStats.isPoiVerified
        );
    }
} 