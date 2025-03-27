# Subgraph Configuration Example

This file provides an example configuration for a subgraph to index DipNft and RewardLogic contract events. The YAML file defines data sources, event handlers, and mapping functions.

## Configuration Code

```yaml
specVersion: 0.0.5
schema:
  file: ./schema.graphql
dataSources:
  - kind: ethereum
    name: DipNft
    network: mainnet # Change to your network
    source:
      address: "0x0000000000000000000000000000000000000000" # Replace with your actual contract address
      abi: DipNft
      startBlock: 0 # Replace with the deployment block
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - NFTClaim
        - NFTUpgrade
        - User
        - Token
      abis:
        - name: DipNft
          file: ./abis/DipNft.json
      eventHandlers:
        - event: NFTEvent(indexed address,indexed uint256,uint256,uint256,uint256,uint256,string)
          handler: handleNFTEvent
        - event: DCURewards(indexed address,indexed uint256)
          handler: handleDCURewards
        - event: DCURewardTriggered(indexed address,indexed uint256)
          handler: handleDCURewardTriggered
        - event: Minted(indexed address,indexed uint256,indexed uint256,uint256)
          handler: handleMinted
        - event: NFTUpgraded(indexed address,indexed uint256,indexed uint256,uint256)
          handler: handleNFTUpgraded
      file: ./src/dipnft-mapping.ts
  - kind: ethereum
    name: RewardLogic
    network: mainnet # Change to your network
    source:
      address: "0x0000000000000000000000000000000000000000" # Replace with your actual contract address
      abi: RewardLogic
      startBlock: 0 # Replace with the deployment block
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - RewardDistribution
        - NFTClaimReward
        - NFTUpgradeReward
        - DCUDistribution
      abis:
        - name: RewardLogic
          file: ./abis/RewardLogic.json
      eventHandlers:
        - event: RewardDistributed(indexed address,uint256,uint256,uint256)
          handler: handleRewardDistributed
        - event: NFTClaimReward(indexed address,indexed uint256,uint256,uint256)
          handler: handleNFTClaimReward
        - event: NFTUpgradeReward(indexed address,indexed uint256,uint256,uint256,uint256)
          handler: handleNFTUpgradeReward
        - event: DCUDistributed(indexed address,uint256,uint256,string)
          handler: handleDCUDistributed
      file: ./src/rewardlogic-mapping.ts
```

## Usage

This configuration file should be customized with your actual contract addresses and deployment blocks. It defines two data sources:

1. **DipNft**: Handles NFT-related events, including the unified `NFTEvent` and legacy events
2. **RewardLogic**: Handles reward distribution events

For more details on subgraph configuration, see The Graph documentation at https://thegraph.com/docs/. 