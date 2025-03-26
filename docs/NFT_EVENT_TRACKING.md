# NFT Claim and Upgrade Event Tracking

This document outlines the changes made to track NFT claims and upgrades, ensuring proper reward distribution and data accessibility for dashboard and leaderboard functionality.

## Enhanced Events Added

### DipNft Contract

1. **NFTEvent**
   - A unified event that tracks both NFT claims and upgrades
   - Parameters:
     - `user` (indexed): The address of the user
     - `tokenId` (indexed): The ID of the token
     - `oldLevel`: Previous level (0 for new claims)
     - `newLevel`: New level after the operation
     - `timestamp`: When the operation occurred
     - `rewardAmount`: Amount of DCU rewarded
     - `eventType`: "CLAIM" for new NFTs, "UPGRADE" for level upgrades
   - Enables comprehensive tracking for both dashboard and leaderboard updates

### RewardLogic Contract

1. **NFTClaimReward**
   - Tracks rewards distributed specifically for NFT claims
   - Links the reward to a specific token ID

2. **NFTUpgradeReward**
   - Tracks rewards distributed for NFT level upgrades
   - Includes the new level and token ID

3. **DCUDistributed**
   - General event for DCU token distribution
   - Includes reason metadata for better tracking

## Reward Distribution Enhancements

1. **Direct Reward Triggering**
   - NFT claims now automatically trigger a 10 DCU reward
   - Level upgrades also trigger a 10 DCU reward
   - Both operations attempt to call the `distributeDCU` function on the rewards contract

2. **Fallback Event Emission**
   - If reward distribution fails, events are still emitted for tracking
   - Ensures rewards can be distributed manually if necessary

## Optimizations

1. **Code Size Reduction**
   - Combined multiple similar events into a unified `NFTEvent` with an event type
   - Extracted common reward processing logic into a helper function
   - Maintained backward compatibility with existing event structure

## Indexing Tools Support

We've added example files to assist with The Graph integration:

1. **subgraph.yaml.example**
   - Example configuration file for The Graph subgraph
   - Includes data sources and event handlers for both contracts

2. **schema.graphql.example**
   - GraphQL schema defining entities for tracking claims, upgrades, and rewards
   - Includes relationships between users, tokens, and various events

3. **dipnft-mapping.ts.example** & **rewardlogic-mapping.ts.example**
   - Example AssemblyScript mapping files for processing events
   - Shows how to update entities and track statistics

## Testing

You should test these changes by:

1. Minting a new NFT and verifying that:
   - The `NFTEvent` event is emitted with type "CLAIM"
   - 10 DCU tokens are rewarded

2. Upgrading an NFT and verifying that:
   - The `NFTEvent` event is emitted with type "UPGRADE"
   - 10 DCU tokens are rewarded

3. Deploying a test subgraph to verify that:
   - Events are properly indexed
   - Entity relationships are correctly maintained
   - Dashboard and leaderboard can query the necessary data

## Notes for Developers

- The unified `NFTEvent` includes an `eventType` string to differentiate between claims and upgrades
- All new events include indexed parameters for efficient filtering
- The timestamp is included in events to facilitate time-based queries
- The reward amount is standardized at 10 DCU but can be adjusted via constants
- Be sure to configure the rewards contract address before using the reward distribution functionality 