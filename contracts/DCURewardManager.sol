// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IDCUToken.sol";
import "./interfaces/INFTCollection.sol";

/**
 * @title DCURewardManager
 * @dev Contract for managing DCU rewards for users based on various activities
 */
contract DCURewardManager is Ownable {
    // Constants (these don't use storage slots)
    uint256 public constant MAX_LEVEL = 10;
    uint256 public constant MAX_REWARD_AMOUNT = 1000 ether; // 1000 DCU maximum reward limit
    
    // Address variables (each uses a full slot)
    IDCUToken public dcuToken;
    INFTCollection public nftCollection;
    
    // Group uint256 variables together (each uses a full slot)
    uint256 public impactProductClaimReward = 10 ether; // 10 DCU for Impact Product claims
    uint256 public referralReward = 1 ether; // 1 DCU for referrals
    uint256 public streakReward = 3 ether; // 3 DCU for maintaining a 7-day streak
    
    // Verification tracker struct
    struct VerificationStatus {
        bool poiVerified;
        bool nftMinted;
        bool rewardEligible;
    }
    
    // Group bool mappings (organized for clarity)
    mapping(address => bool) public poiVerified;
    mapping(address => mapping(address => bool)) public referralRewarded; // referrer => invitee => rewarded
    mapping(address => mapping(uint256 => bool)) public impactProductClaimed;
    
    // Group address mappings
    mapping(address => address) public referrers; // invitee => referrer
    
    // Group uint256 mappings
    mapping(address => uint256) public userBalances;
    mapping(address => uint256) public lastPoiTimestamp;
    mapping(address => uint256) public totalClaimRewards; // Total rewards from Impact Product claims
    mapping(address => uint256) public totalStreakRewards; // Total rewards from streaks
    mapping(address => uint256) public totalReferralRewards; // Total rewards from referrals
    mapping(address => uint256) public totalRewardsClaimed; // Total rewards claimed (post-TGE)
    
    // Verification status tracker mapping
    mapping(address => VerificationStatus) public verificationStatus;
    
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
    event NFTMintStatusUpdated(address indexed user, bool minted);
    event RewardEligibilityChanged(address indexed user, bool eligible);
    
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
     * @param _nftCollection Address of the NFT collection contract
     */
    constructor(
        address _dcuToken,
        address _nftCollection
    ) Ownable(msg.sender) {
        dcuToken = IDCUToken(_dcuToken);
        nftCollection = INFTCollection(_nftCollection);
    }
    
    /**
     * @dev Update the NFT collection address
     * @param _nftCollection New NFT collection address
     */
    function updateNftCollection(address _nftCollection) external onlyOwner {
        require(_nftCollection != address(0), "Invalid NFT collection address");
        nftCollection = INFTCollection(_nftCollection);
    }
    
    /**
     * @dev Set PoI verification status for a user
     * @param user Address of the user
     * @param verified Whether the PoI is verified
     */
    function setPoiVerificationStatus(address user, bool verified) external onlyOwner {
        require(user != address(0), "Invalid user address");
        poiVerified[user] = verified;
        verificationStatus[user].poiVerified = verified;
        
        // Update reward eligibility if both PoI is verified and NFT is minted
        if (verified && verificationStatus[user].nftMinted) {
            verificationStatus[user].rewardEligible = true;
            emit RewardEligibilityChanged(user, true);
        } else if (!verified && verificationStatus[user].rewardEligible) {
            verificationStatus[user].rewardEligible = false;
            emit RewardEligibilityChanged(user, false);
        }
        
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
     * @dev Update NFT mint status for a user (called by NFT contract)
     * @param user Address of the user
     * @param minted Whether the user has minted an NFT
     */
    function updateNftMintStatus(address user, bool minted) external {
        require(msg.sender == address(nftCollection), "Only NFT contract can call");
        require(user != address(0), "Invalid user address");
        
        verificationStatus[user].nftMinted = minted;
        emit NFTMintStatusUpdated(user, minted);
        
        // If PoI is verified and NFT is minted, user becomes reward eligible
        if (verificationStatus[user].poiVerified && minted) {
            verificationStatus[user].rewardEligible = true;
            emit RewardEligibilityChanged(user, true);
        } else if (!minted && verificationStatus[user].rewardEligible) {
            verificationStatus[user].rewardEligible = false;
            emit RewardEligibilityChanged(user, false);
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
        require(verificationStatus[user].rewardEligible, "User not eligible for rewards");
        require(!impactProductClaimed[user][level], "Level already claimed");
        require(user != address(0), "Invalid user address");
        
        // Verify NFT ownership through the NFT contract
        bool hasNFT = nftCollection.balanceOf(user) > 0;
        require(hasNFT, "User has not minted an Impact Product NFT");
        
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
    
    /**
     * @dev Get a user's verification status
     * @param user Address of the user
     * @return isPoiVerified Whether the user's PoI is verified
     * @return nftMinted Whether the user has minted an NFT
     * @return rewardEligible Whether the user is eligible for rewards
     */
    function getVerificationStatus(address user) external view returns (
        bool isPoiVerified,
        bool nftMinted,
        bool rewardEligible
    ) {
        VerificationStatus memory status = verificationStatus[user];
        return (status.poiVerified, status.nftMinted, status.rewardEligible);
    }
    
    /**
     * @dev Set the reward eligibility status directly for testing purposes
     * @param user Address of the user
     * @param eligible Whether the user is eligible for rewards
     */
    function setRewardEligibilityForTesting(address user, bool eligible) external onlyOwner {
        require(user != address(0), "Invalid user address");
        verificationStatus[user].rewardEligible = eligible;
        emit RewardEligibilityChanged(user, eligible);
    }
} 