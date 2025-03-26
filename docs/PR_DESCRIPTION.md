# NFT Claim & Upgrade Event Tracking with Rewards

## Overview
This PR implements event tracking for NFT claims and upgrades, along with automated DCU reward distribution. These changes enable better tracking of user activity for dashboard and leaderboard updates while ensuring proper reward distribution.

## Changes

### Enhanced Event System
- **NFTEvent**: A unified event for tracking both NFT claims and upgrades
  - Includes detailed information such as user address, token ID, old/new levels, timestamp, and reward amount
  - Uses an `eventType` field to differentiate between claims ("CLAIM") and upgrades ("UPGRADE")
- Added supporting events in the RewardLogic contract for reward distribution tracking

### Reward Integration
- Implemented automatic 10 DCU rewards for NFT claims and level upgrades
- Added direct reward triggering through the RewardLogic contract
- Implemented fallback event emission if reward distribution fails
- Extracted common reward logic to reduce code duplication and contract size

### Code Optimizations
- Consolidated multiple similar events into a single unified event to reduce contract size
- Refactored reward processing into a helper function to improve maintainability
- Maintained backward compatibility with existing event structure

### Indexing Support
- Added example files for The Graph integration:
  - Subgraph configuration (YAML)
  - GraphQL schema
  - AssemblyScript mapping files
- Ensured all events are structured for optimal indexing with proper use of indexed parameters

### Documentation
- Created documentation explaining the changes and integration approach
- Added usage examples and testing instructions

## Testing Done
- Verified events are properly emitted on NFT minting
- Verified events are properly emitted on NFT level upgrades
- Confirmed reward distribution works correctly with the RewardLogic contract
- Validated The Graph compatibility with the sample subgraph configuration

## How to Test
1. Mint a new NFT and verify the `NFTEvent` event is emitted with type "CLAIM"
2. Upgrade an NFT and verify the `NFTEvent` event is emitted with type "UPGRADE"
3. Check that 10 DCU rewards are properly distributed for both operations

## Related Issues
Closes #[issue_number] - Emit events for tracking NFT claims & upgrades 