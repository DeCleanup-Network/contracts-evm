# DeCleanup Network Smart Contract API

This document provides a comprehensive API reference for all DeCleanup Network (DCU) smart contracts deployed on the Sepolia testnet.

## Deployed Contracts

The following contracts are deployed on the Sepolia testnet:

| Contract | Address |
|----------|---------|
| DCUStorage | 0x6B0b410c922713d359f0fe34F710c4D77351DEC5 |
| NFTCollection | 0xf3B81c0Bb5089FA4244f6eE633E1205453C65b37 |
| DCUAccounting | 0xF2c3add9b1a4075086e3CE693DCD9Efee81918Ff |
| DCURewardManager | 0x589679A4aB985E7e50f469507397b2d7a5279c41 |
| RewardLogic | 0xE23e8f18b7CF16201F7D4F50fBf28A654433CE7A |
| DipNft | (address not provided) |

## DCUStorage

Core storage contract that manages token balances, staking, and token distribution.

### Events

- `ClaimableBalanceAdded(address indexed user, uint256 amount, uint256 newBalance)`: Emitted when tokens are allocated to a user's claimable balance.
- `TokensClaimed(address indexed user, uint256 amount, uint256 remainingClaimable)`: Emitted when a user claims tokens.
- `TGEStatusChanged(bool completed)`: Emitted when the Token Generation Event status changes.
- `AddressWhitelisted(address indexed account)`: Emitted when an address is added to the whitelist.
- `AddressRemovedFromWhitelist(address indexed account)`: Emitted when an address is removed from the whitelist.
- `TokensStaked(address indexed user, uint256 amount, uint256 newStakedBalance)`: Emitted when a user stakes tokens.
- `TokensUnstaked(address indexed user, uint256 amount, uint256 newStakedBalance)`: Emitted when a user unstakes tokens.
- `TokensLocked(address indexed user, uint256 amount, uint256 releaseTime)`: Emitted when tokens are locked.
- `TokensUnlocked(address indexed user, uint256 amount)`: Emitted when locked tokens are released.
- `GovernanceUpdated(address indexed oldGovernance, address indexed newGovernance)`: Emitted when governance address is updated.

### TGE Functions

- `setTGEStatus(bool _tgeCompleted)`: Sets the Token Generation Event status.
- `addToWhitelist(address account)`: Adds an address to the whitelist.
- `removeFromWhitelist(address account)`: Removes an address from the whitelist.
- `isWhitelisted(address account)`: Returns whether an address is whitelisted.

### Claimable Balance Functions

- `addClaimableBalance(address user, uint256 amount)`: Adds tokens to a user's claimable balance.
- `claimTokens(uint256 amount)`: Claims tokens from the caller's claimable balance.
- `claimTokensFor(address user, uint256 amount)`: Claims tokens for a specific user.
- `getClaimableBalance(address user)`: Returns a user's claimable token balance.
- `totalClaimable()`: Returns the total amount of claimable tokens.

### Token Functions

- `mint(address to, uint256 amount)`: Mints new tokens to the specified address.
- `burnFrom(address from, uint256 amount)`: Burns tokens from a specific address.
- `transfer(address to, uint256 value)`: Transfers tokens to another address.
- `transferFrom(address from, address to, uint256 value)`: Transfers tokens from one address to another.
- `balanceOf(address account)`: Returns the token balance of an address.

### Staking Functions

- `stake(uint256 amount)`: Stakes tokens.
- `unstake(uint256 amount)`: Unstakes tokens.
- `getStakedBalance(address user)`: Returns a user's staked token balance.

### Locking Functions

- `lockTokens(uint256 amount, uint256 lockDuration)`: Locks tokens for a specified duration.
- `unlockTokens()`: Unlocks tokens after the lock period has expired.
- `getLockedBalance(address user)`: Returns a user's locked token balance and release time.

### Governance Functions

- `updateGovernance(address newGovernance)`: Updates the governance address.
- `setStakingContract(address stakingContract)`: Sets the staking contract address.
- `setRewardManager(address rewardManager)`: Sets the reward manager contract address.

## DCUToken

ERC20 token implementation for the DeCleanup Network.

### Functions

- `mint(address to, uint256 amount)`: Mints new tokens to the specified address.
- `burn(address from, uint256 amount)`: Burns tokens from caller's address.
- `burnFrom(address from, uint256 amount)`: Burns tokens from a specific address.
- `transfer(address to, uint256 amount)`: Transfers tokens to another address.
- `transferFrom(address from, address to, uint256 amount)`: Transfers tokens from one address to another.
- `balanceOf(address account)`: Returns the token balance of an address.
- `addClaimableBalance(address user, uint256 amount)`: Adds tokens to a user's claimable balance.
- `claimTokens(uint256 amount)`: Claims tokens from the caller's claimable balance.
- `claimTokensFor(address user, uint256 amount)`: Claims tokens for a specific user.
- `getClaimableBalance(address user)`: Returns a user's claimable token balance.
- `isWhitelisted(address account)`: Returns whether an address is whitelisted.
- `setTGEStatus(bool _tgeCompleted)`: Sets the Token Generation Event status.

## NFTCollection

NFT contract for the DeCleanup Network.

### Functions

- `mint(address to)`: Mints a new NFT to the specified address and returns the token ID.
- `balanceOf(address owner)`: Returns the number of NFTs owned by an address.

## DipNft

Advanced NFT contract with level progression and rewards.

### Constants

- `MAX_LEVEL`: Maximum level an NFT can reach (10).
- `REWARD_AMOUNT`: Base amount of DCU rewards (10).

### State Variables

- `_tokenIdCounter`: Counter for token IDs.
- `rewardsContract`: Address of the rewards distribution contract.
- `userLevel`: Mapping of user addresses to their level.
- `verifiedPOI`: Mapping of addresses that have been verified with Proof of Impact.
- `hasMinted`: Mapping tracking if an address has minted an NFT.
- `nftLevel`: Mapping of token IDs to their level.
- `impactLevel`: Mapping of token IDs to their impact level.

### Events

- `Minted(address indexed to, uint256 indexed tokenId, uint256 indexed userLevel, uint256 nftLevel)`: Emitted when an NFT is minted.
- `DCURewards(address indexed to, uint256 indexed amount)`: Emitted when DCU rewards are distributed.
- `NFTUpgraded(address indexed to, uint256 indexed tokenId, uint256 indexed newLevel, uint256 userLevel)`: Emitted when an NFT is upgraded.
- `DCURewardTriggered(address indexed to, uint256 indexed amount)`: Emitted when rewards are triggered.
- `RewardsContractUpdated(address indexed oldContract, address indexed newContract)`: Emitted when the rewards contract is updated.
- `POIVerified(address indexed user)`: Emitted when a user's Proof of Impact is verified.
- `ImpactLevelUpdated(uint256 indexed tokenId, uint256 indexed newLevel)`: Emitted when a token's impact level is updated.
- `RewardDistributed(address indexed to, uint256 indexed amount, uint256 indexed level)`: Emitted when rewards are distributed.

### Core Functions

- `mint(address to)`: Mints a new NFT to the specified address. Requires user has not minted already.
- `setVerifiedPOI(address user, bool status)`: Sets a user's POI verification status.
- `upgradeNFT(uint256 tokenId)`: Upgrades an NFT's level.
- `setImpactLevel(uint256 tokenId, uint256 level)`: Sets the impact level for an NFT.
- `calculateReward(uint256 tokenId)`: Calculates the reward amount based on NFT and impact levels.
- `distributeReward(address to, uint256 tokenId)`: Distributes DCU rewards to a user.
- `setRewardsContract(address _rewardsContract)`: Sets the rewards contract address.
- `tokenURI(uint256 tokenId)`: Generates the token URI with metadata.

## DCUAccounting

Manages token deposits and withdrawals with TGE restrictions.

### State Variables

- `dcuToken`: Reference to the DCU token contract.
- `balances`: Mapping from user address to their DCU balance.
- `totalDeposits`: Total amount of DCU tokens held by this contract.
- `tgeCompleted`: TGE status flag.
- `whitelisted`: Mapping of whitelisted addresses that can transfer tokens before TGE.

### Events

- `EmergencyWithdrawal(address indexed owner, uint256 amount)`: Emitted during an emergency withdrawal.
- `AddressWhitelisted(address indexed account)`: Emitted when an address is added to the whitelist.
- `AddressRemovedFromWhitelist(address indexed account)`: Emitted when an address is removed from the whitelist.
- `TGEStatusChanged(bool completed)`: Emitted when the TGE status changes.
- `DCUDeposit(address indexed user, uint256 amount, uint256 newBalance, uint256 timestamp)`: Emitted when a user deposits tokens.
- `DCUWithdrawal(address indexed user, uint256 amount, uint256 newBalance, uint256 timestamp)`: Emitted when a user withdraws tokens.
- `DCUInternalTransfer(address indexed from, address indexed to, uint256 amount, uint256 fromNewBalance, uint256 toNewBalance, uint256 timestamp)`: Emitted when tokens are transferred internally.

### TGE Management Functions

- `setTGEStatus(bool _tgeCompleted)`: Sets the Token Generation Event status.
- `addToWhitelist(address account)`: Adds an address to the whitelist.
- `removeFromWhitelist(address account)`: Removes an address from the whitelist.

### Token Management Functions

- `deposit(uint256 amount)`: Allows a user to deposit DCU tokens.
- `withdraw(uint256 amount)`: Allows a user to withdraw their deposited DCU tokens.
- `transfer(address to, uint256 amount)`: Transfers tokens from the caller to another user within the accounting contract.
- `forcedWithdrawal(address user, uint256 amount)`: Owner-only function to force a withdrawal to a user's wallet.
- `emergencyWithdraw()`: Owner-only function to withdraw all tokens in case of emergency.

## DCURewardManager

Manages DCU rewards distribution for various user activities.

### State Variables

- `dcuToken`: Reference to the DCU token contract.
- `userBalances`: Mapping of user addresses to their DCU balances.
- `impactProductClaimReward`: Reward amount for Impact Product claims (10 DCU).
- `referralReward`: Reward amount for referrals (1 DCU).
- `streakReward`: Reward amount for maintaining a 7-day streak (3 DCU).
- `poiVerified`: Mapping of users with verified Proof of Impact.
- `impactProductClaimed`: Mapping to track Impact Product claims by user and level.
- `lastPoiTimestamp`: Mapping to track the last PoI submission time for streak calculations.
- `referrers`: Mapping of invitees to their referrers.
- `referralRewarded`: Mapping to track if a referral has been rewarded.
- `totalClaimRewards`: Total rewards from Impact Product claims per user.
- `totalStreakRewards`: Total rewards from streaks per user.
- `totalReferralRewards`: Total rewards from referrals per user.
- `totalRewardsClaimed`: Total rewards claimed per user.

### Events

- `RewardDistributed`: Emitted when a reward is distributed.
- `POIVerified`: Emitted when a user's POI is verified.
- `ReferralRecorded`: Emitted when a referral is recorded.
- `ReferralRewarded`: Emitted when a referral is rewarded.
- `RewardsClaimed`: Emitted when rewards are claimed.
- `RewardAmountUpdated`: Emitted when a reward amount is updated.

### Core Functions

- `verifyPoiSubmission(address user)`: Verifies a POI submission for a user.
- `recordImpactProductClaim(address user, uint256 level)`: Records an Impact Product claim.
- `recordReferral(address referrer, address invitee)`: Records a referral.
- `claimRewards(address user, uint256 amount)`: Claims rewards for a user.
- `getUserRewardStats(address user)`: Gets reward statistics for a user.
- `updateImpactProductClaimReward(uint256 amount)`: Updates the Impact Product claim reward amount.
- `updateReferralReward(uint256 amount)`: Updates the referral reward amount.
- `updateStreakReward(uint256 amount)`: Updates the streak reward amount.
- `isStreakActive(address user)`: Checks if a user's streak is active (within 7 days).
- `distributeDCU(address user, uint256 amount)`: Distributes DCU tokens to a user (implements IRewards interface).

## RewardLogic

Implements the core logic for calculating and distributing rewards based on NFT holdings.

### State Variables

- `dcuToken`: Reference to the DCU token contract.
- `nftCollection`: Reference to the NFT collection contract.

### Events

- `RewardDistributed(address indexed user, uint256 amount, uint256 nftBalance, uint256 timestamp)`: Emitted when a reward is distributed.

### Functions

- `calculateReward(address user)`: Calculates reward amount based on a user's NFT holdings (100 DCU per NFT).
- `distributeReward(address user)`: Distributes rewards to a user based on the calculated amount.

## Integration Examples

### Claiming Tokens

```javascript
// Using ethers.js
const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
const DCUStorageContract = new ethers.Contract(DCUStorageAddress, DCUStorageABI, signer);

// Check claimable balance
const claimableBalance = await DCUStorageContract.getClaimableBalance(userAddress);
console.log(`Claimable balance: ${ethers.utils.formatEther(claimableBalance)} DCU`);

// Claim tokens
if (claimableBalance.gt(0)) {
  const tx = await DCUStorageContract.claimTokens(claimableBalance);
  await tx.wait();
  console.log("Tokens claimed successfully");
}
```

### Staking Tokens

```javascript
// Using ethers.js
const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
const DCUStorageContract = new ethers.Contract(DCUStorageAddress, DCUStorageABI, signer);

// Approve tokens for staking
const DCUTokenContract = new ethers.Contract(DCUTokenAddress, DCUTokenABI, signer);
const amountToStake = ethers.utils.parseEther("100");
await DCUTokenContract.approve(DCUStorageAddress, amountToStake);

// Stake tokens
const tx = await DCUStorageContract.stake(amountToStake);
await tx.wait();
console.log(`Successfully staked ${ethers.utils.formatEther(amountToStake)} DCU tokens`);
```

### Depositing to DCUAccounting

```javascript
// Using ethers.js
const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();
const DCUAccountingContract = new ethers.Contract(DCUAccountingAddress, DCUAccountingABI, signer);
const DCUTokenContract = new ethers.Contract(DCUTokenAddress, DCUTokenABI, signer);

// Amount to deposit
const amountToDeposit = ethers.utils.parseEther("50");

// Approve tokens for deposit
await DCUTokenContract.approve(DCUAccountingAddress, amountToDeposit);

// Deposit tokens
const tx = await DCUAccountingContract.deposit(amountToDeposit);
await tx.wait();
console.log(`Successfully deposited ${ethers.utils.formatEther(amountToDeposit)} DCU tokens`);
```

## Error Handling

Most functions will revert with specific error messages in case of failure. Common errors include:

- Insufficient balance
- Not whitelisted
- TGE not completed
- Insufficient allowance
- Not authorized

Always handle these errors in your frontend applications. 