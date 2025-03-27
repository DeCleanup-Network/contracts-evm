# RewardLogic Contract Mapping Example

This file provides an example AssemblyScript mapping for the RewardLogic contract events. It shows how to properly handle and index reward-related events in a subgraph.

## Mapping Code

```typescript
import { BigInt, Address, log } from '@graphprotocol/graph-ts'
import {
  RewardDistributed,
  NFTClaimReward,
  NFTUpgradeReward,
  DCUDistributed
} from '../generated/RewardLogic/RewardLogic'
import { 
  User, 
  RewardDistribution, 
  NFTClaimRewardEntity, 
  NFTUpgradeRewardEntity, 
  DCUDistributionEntity, 
  Global 
} from '../generated/schema'

// Helper function to ensure User entity exists
function getOrCreateUser(address: Address): User {
  let userId = address.toHexString()
  let user = User.load(userId)
  
  if (!user) {
    user = new User(userId)
    user.totalClaims = 0
    user.totalUpgrades = 0
    user.totalRewards = BigInt.fromI32(0)
    user.createdAt = BigInt.fromI32(0)
  }
  
  return user
}

// Helper function to ensure Global entity exists
function getOrCreateGlobal(): Global {
  let global = Global.load('global')
  
  if (!global) {
    global = new Global('global')
    global.totalNFTsClaimed = 0
    global.totalUpgrades = 0
    global.totalRewardsDistributed = BigInt.fromI32(0)
    global.lastUpdated = BigInt.fromI32(0)
  }
  
  return global
}

// Handle general reward distribution
export function handleRewardDistributed(event: RewardDistributed): void {
  let user = getOrCreateUser(event.params.user)
  let global = getOrCreateGlobal()
  
  // Record the distribution
  let distributionId = event.transaction.hash.toHexString() + '-' + event.logIndex.toString()
  let distribution = new RewardDistribution(distributionId)
  
  distribution.user = user.id
  distribution.amount = event.params.amount
  distribution.timestamp = event.block.timestamp
  distribution.level = event.params.level.toI32()
  distribution.transaction = event.transaction.hash.toHexString()
  
  // Update user stats
  user.totalRewards = user.totalRewards.plus(event.params.amount)
  user.lastActivity = event.block.timestamp
  
  // Update global stats
  global.totalRewardsDistributed = global.totalRewardsDistributed.plus(event.params.amount)
  global.lastUpdated = event.block.timestamp
  
  // Save entities
  distribution.save()
  user.save()
  global.save()
}

// Handle NFT claim rewards
export function handleNFTClaimReward(event: NFTClaimReward): void {
  let user = getOrCreateUser(event.params.user)
  let global = getOrCreateGlobal()
  
  // Record the NFT claim reward
  let rewardId = event.transaction.hash.toHexString() + '-' + event.logIndex.toString()
  let reward = new NFTClaimRewardEntity(rewardId)
  
  reward.user = user.id
  reward.tokenId = event.params.tokenId
  reward.amount = event.params.amount
  reward.timestamp = event.block.timestamp
  reward.transaction = event.transaction.hash.toHexString()
  
  // Update user stats
  user.totalRewards = user.totalRewards.plus(event.params.amount)
  user.lastActivity = event.block.timestamp
  
  // Update global stats
  global.totalRewardsDistributed = global.totalRewardsDistributed.plus(event.params.amount)
  global.lastUpdated = event.block.timestamp
  
  // Save entities
  reward.save()
  user.save()
  global.save()
}

// Handle NFT upgrade rewards
export function handleNFTUpgradeReward(event: NFTUpgradeReward): void {
  let user = getOrCreateUser(event.params.user)
  let global = getOrCreateGlobal()
  
  // Record the NFT upgrade reward
  let rewardId = event.transaction.hash.toHexString() + '-' + event.logIndex.toString()
  let reward = new NFTUpgradeRewardEntity(rewardId)
  
  reward.user = user.id
  reward.tokenId = event.params.tokenId
  reward.amount = event.params.amount
  reward.oldLevel = event.params.oldLevel.toI32()
  reward.newLevel = event.params.newLevel.toI32()
  reward.timestamp = event.block.timestamp
  reward.transaction = event.transaction.hash.toHexString()
  
  // Update user stats
  user.totalRewards = user.totalRewards.plus(event.params.amount)
  user.lastActivity = event.block.timestamp
  
  // Update global stats
  global.totalRewardsDistributed = global.totalRewardsDistributed.plus(event.params.amount)
  global.lastUpdated = event.block.timestamp
  
  // Save entities
  reward.save()
  user.save()
  global.save()
}

// Handle DCU distributions
export function handleDCUDistributed(event: DCUDistributed): void {
  let user = getOrCreateUser(event.params.user)
  let global = getOrCreateGlobal()
  
  // Record the DCU distribution
  let distributionId = event.transaction.hash.toHexString() + '-' + event.logIndex.toString()
  let distribution = new DCUDistributionEntity(distributionId)
  
  distribution.user = user.id
  distribution.amount = event.params.amount
  distribution.timestamp = event.block.timestamp
  distribution.reason = event.params.reason
  distribution.transaction = event.transaction.hash.toHexString()
  
  // Update user stats
  user.totalRewards = user.totalRewards.plus(event.params.amount)
  user.lastActivity = event.block.timestamp
  
  // Update global stats
  global.totalRewardsDistributed = global.totalRewardsDistributed.plus(event.params.amount)
  global.lastUpdated = event.block.timestamp
  
  // Save entities
  distribution.save()
  user.save()
  global.save()
}
```

## Usage

This mapping file should be used in conjunction with the RewardLogic contract ABI and the subgraph configuration. It handles all reward-related events and updates the relevant entities in The Graph's store.

For more details on subgraph development, see The Graph documentation at https://thegraph.com/docs/. 