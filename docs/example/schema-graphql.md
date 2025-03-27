# GraphQL Schema Example

This file provides an example GraphQL schema for a subgraph to track NFT claims, upgrades, and rewards. The schema defines entities and their relationships.

## Schema Code

```graphql
type User @entity {
  id: ID! # User address
  totalClaims: Int!
  totalUpgrades: Int!
  totalRewards: BigInt!
  createdAt: BigInt!
  lastActivity: BigInt
  tokens: [Token!]! @derivedFrom(field: "owner")
  claims: [NFTClaim!]! @derivedFrom(field: "user")
  upgrades: [NFTUpgrade!]! @derivedFrom(field: "user")
  rewards: [RewardDistribution!]! @derivedFrom(field: "user")
}

type Token @entity {
  id: ID! # TokenId
  tokenId: BigInt!
  owner: User!
  level: Int!
  impactLevel: Int!
  createdAt: BigInt!
  lastUpgradedAt: BigInt
  claims: [NFTClaim!]! @derivedFrom(field: "token")
  upgrades: [NFTUpgrade!]! @derivedFrom(field: "token")
}

type NFTClaim @entity {
  id: ID! # tx hash + log index
  user: User!
  token: Token!
  timestamp: BigInt!
  rewardAmount: BigInt!
  transaction: String!
}

type NFTUpgrade @entity {
  id: ID! # tx hash + log index
  user: User!
  token: Token!
  oldLevel: Int!
  newLevel: Int!
  timestamp: BigInt!
  rewardAmount: BigInt!
  transaction: String!
}

type RewardDistribution @entity {
  id: ID! # tx hash + log index
  user: User!
  amount: BigInt!
  timestamp: BigInt!
  level: Int!
  transaction: String!
}

type NFTClaimRewardEntity @entity {
  id: ID! # tx hash + log index
  user: User!
  tokenId: BigInt!
  amount: BigInt!
  timestamp: BigInt!
  transaction: String!
}

type NFTUpgradeRewardEntity @entity {
  id: ID! # tx hash + log index
  user: User!
  tokenId: BigInt!
  amount: BigInt!
  oldLevel: Int!
  newLevel: Int!
  timestamp: BigInt!
  transaction: String!
}

type DCUDistributionEntity @entity {
  id: ID! # tx hash + log index
  user: User!
  amount: BigInt!
  timestamp: BigInt!
  reason: String!
  transaction: String!
}

type Global @entity {
  id: ID! # "global"
  totalNFTsClaimed: Int!
  totalUpgrades: Int!
  totalRewardsDistributed: BigInt!
  lastUpdated: BigInt!
}
```

## Usage

This schema defines entities for tracking NFT claims, upgrades, rewards, and user statistics. Key entities include:

1. **User**: Represents a user with NFTs, tracking their claims, upgrades, and rewards
2. **Token**: Represents an NFT with its level and ownership information
3. **NFTClaim & NFTUpgrade**: Track individual NFT claim and upgrade events
4. **RewardDistribution & related entities**: Track different types of reward distributions
5. **Global**: Tracks global statistics across the entire platform

For more details on GraphQL schemas for subgraphs, see The Graph documentation at https://thegraph.com/docs/. 