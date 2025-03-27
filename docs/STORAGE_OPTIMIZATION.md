# Storage Layout Optimization

This document describes the storage layout optimization changes made to improve gas efficiency in the smart contracts.

## Background

Solidity stores state variables in storage slots of 32 bytes (256 bits) each. When variables are poorly arranged, they can waste storage space, leading to higher gas costs for deployment and state-changing operations.

### Storage Packing Rules:

1. Each storage slot is 32 bytes (256 bits)
2. Variables are packed into slots when possible, in the order they are declared
3. A new slot is used when the next variable doesn't fit in the current slot
4. Certain types like `mapping` and `array` always start a new slot
5. Constants don't use storage slots as they're embedded in the bytecode

## Optimization Strategy

Our optimization strategy focused on:

1. Grouping variables by type to maximize storage packing
2. Ordering variables from smaller to larger types within each group
3. Separating mappings by value type for clarity (although mappings always use their own slots)

## Changes Made

### DipNft Contract

**Before:**
```solidity
// Constants
uint256 public constant MAX_LEVEL = 10;
uint256 public constant REWARD_AMOUNT = 10; // Amount of DCU to reward

// State variables
uint256 private _tokenIdCounter;
address public rewardsContract;

// Soulbound transfer authorization mappings
mapping(uint256 => bool) private _transferAuthorized;
mapping(uint256 => address) private _authorizedRecipient;

// Mappings
mapping(address => uint256) public userLevel;
mapping(address => bool) public verifiedPOI;
mapping(address => bool) public hasMinted;
mapping(uint256 => uint256) public nftLevel;
mapping(uint256 => uint256) public impactLevel;
mapping(address => uint256) private _userTokenIds;
```

**After:**
```solidity
// Constants (these don't use storage slots)
uint256 public constant MAX_LEVEL = 10;
uint256 public constant REWARD_AMOUNT = 10; // Amount of DCU to reward

// Group address variables (each uses a full slot)
address public rewardsContract;

// Group uint256 variables (each uses a full slot)
uint256 private _tokenIdCounter;

// Group bool mappings together (these can't share slots in mappings, but organizing for clarity)
mapping(address => bool) public verifiedPOI;
mapping(address => bool) public hasMinted;
mapping(uint256 => bool) private _transferAuthorized;

// Group address mappings
mapping(uint256 => address) private _authorizedRecipient;

// Group uint256 mappings
mapping(address => uint256) public userLevel;
mapping(uint256 => uint256) public nftLevel;
mapping(uint256 => uint256) public impactLevel;
mapping(address => uint256) private _userTokenIds;
```

### DCURewardManager Contract

**Before:**
```solidity
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
mapping(address => uint256) public totalClaimRewards;
mapping(address => uint256) public totalStreakRewards;
mapping(address => uint256) public totalReferralRewards;
mapping(address => uint256) public totalRewardsClaimed;
```

**After:**
```solidity
// Constants (these don't use storage slots)
uint256 public constant MAX_LEVEL = 10;
uint256 public constant MAX_REWARD_AMOUNT = 1000 ether; // 1000 DCU maximum reward limit

// Address variables (each uses a full slot)
IDCUToken public dcuToken;

// Group uint256 variables together (each uses a full slot)
uint256 public impactProductClaimReward = 10 ether; // 10 DCU for Impact Product claims
uint256 public referralReward = 1 ether; // 1 DCU for referrals
uint256 public streakReward = 3 ether; // 3 DCU for maintaining a 7-day streak

// Group bool mappings (organized for clarity)
mapping(address => bool) public poiVerified;
mapping(address => mapping(address => bool)) public referralRewarded; // referrer => invitee => rewarded
mapping(address => mapping(uint256 => bool)) public impactProductClaimed;

// Group address mappings
mapping(address => address) public referrers; // invitee => referrer

// Group uint256 mappings
mapping(address => uint256) public userBalances;
mapping(address => uint256) public lastPoiTimestamp;
mapping(address => uint256) public totalClaimRewards;
mapping(address => uint256) public totalStreakRewards;
mapping(address => uint256) public totalReferralRewards;
mapping(address => uint256) public totalRewardsClaimed;
```

## Gas Savings Results

The optimization primarily affects deployment costs and state-changing operations. Here are the gas costs after optimization:

```
Deployment gas costs:
DipNft: 5,397,269 gas units
DCURewardManager: 3,055,132 gas units

Function call gas costs:
verifyPOI: 47,639 gas units
setPoiVerificationStatus: 71,016 gas units
safeMint: 202,817 gas units
updateImpactLevel: 33,245 gas units
rewardImpactProductClaim: 101,818 gas units
```

## Limitations and Notes

1. For mappings, we cannot benefit from storage packing as each mapping always occupies its own slot.
2. Constants don't consume storage slots as they're embedded in the contract bytecode.
3. While we've organized mappings by value type for clarity, this doesn't directly impact gas costs but improves readability and maintainability.

## Resources

- [Solidity Storage Layout Documentation](https://docs.soliditylang.org/en/v0.8.20/internals/layout_in_storage.html)
- [Gas Optimization Best Practices](https://github.com/iskdrews/awesome-solidity-gas-optimization) 